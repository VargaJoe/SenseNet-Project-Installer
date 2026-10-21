using System.Diagnostics;
using System.Text.Json.Nodes;

namespace PlotManager.Server;

public sealed class EngineClient(ServiceSettings settings, SecretStore secrets)
{
    public IReadOnlyDictionary<string, string?> CaptureEnvironment(string owner, JsonObject request)
    {
        var comparer = OperatingSystem.IsWindows() ? StringComparer.OrdinalIgnoreCase : StringComparer.Ordinal;
        var availableSecrets = new Dictionary<string, string>(secrets.EnvironmentFor(owner), comparer);
        var environment = new Dictionary<string, string?>(comparer);
        var names = SecretStore.ReferencedEnvironment(request);
        if (request["ConfigurationFiles"] is JsonArray files)
            foreach (var file in files)
                foreach (var name in SecretStore.ReferencedEnvironment(JsonStore.Object(file!.GetValue<string>()))) names.Add(name);
        foreach (var name in names)
        {
            if (name.StartsWith("PLOTMANAGER_", StringComparison.OrdinalIgnoreCase) && !name.StartsWith("PLOTMANAGER_SECRET_", StringComparison.OrdinalIgnoreCase)) throw new ApiException(400, "Service configuration environment variables cannot be used by a project.");
            if (!environment.ContainsKey(name)) environment[name] = availableSecrets.TryGetValue(name, out var secret) ? secret : System.Environment.GetEnvironmentVariable(name);
        }
        // Null captures absence too: a newly added variable cannot silently
        // change a submitted run between preflight and its actual worker.
        return new System.Collections.ObjectModel.ReadOnlyDictionary<string, string?>(environment);
    }
    public async Task<JsonNode> InvokeAsync(string owner, JsonObject request, string engineDirectory, string scratch, string? eventPath, Action<Process>? started, CancellationToken cancellation, IReadOnlyDictionary<string, string?>? environmentSnapshot = null)
    {
        Directory.CreateDirectory(scratch);
        var requestPath = Path.Combine(scratch, "request-" + Guid.NewGuid().ToString("N") + ".json");
        var responsePath = Path.Combine(scratch, "response-" + Guid.NewGuid().ToString("N") + ".json");
        var environment = environmentSnapshot ?? CaptureEnvironment(owner, request);
        var redactions = environment.Values.Where(x => !string.IsNullOrEmpty(x)).Select(x => x!).ToArray();
        JsonStore.Write(requestPath, request);
        ServiceSettings.PrivateFile(requestPath);
        try
        {
            var bridge = Path.Combine(engineDirectory, "Invoke-ManagedRequest.ps1");
            if (!File.Exists(bridge)) throw new ApiException(503, "The managed PowerShell engine bridge is not installed.", "engine_unavailable");
            var start = new ProcessStartInfo(settings.PowerShell) { UseShellExecute = false, CreateNoWindow = true, RedirectStandardOutput = true, RedirectStandardError = true, WorkingDirectory = request["WorkDirectory"]?.GetValue<string>() ?? scratch };
            foreach (var argument in new[] { "-NoLogo", "-NoProfile", "-NonInteractive", "-File", bridge, "-RequestPath", requestPath, "-ResponsePath", responsePath }) start.ArgumentList.Add(argument);
            start.ArgumentList.Add("-AutoPath"); start.ArgumentList.Add(Path.Combine(engineDirectory, "Auto"));
            if (eventPath != null) { start.ArgumentList.Add("-EventPath"); start.ArgumentList.Add(eventPath); }
            foreach (var key in start.Environment.Keys.Where(x => x.StartsWith("PLOTMANAGER_", StringComparison.OrdinalIgnoreCase) || x.StartsWith("ASPNETCORE_", StringComparison.OrdinalIgnoreCase)).ToArray()) start.Environment.Remove(key);
            foreach (var pair in environment)
            {
                if (pair.Value == null) start.Environment.Remove(pair.Key);
                else start.Environment[pair.Key] = pair.Value;
            }
            using var process = new Process { StartInfo = start };
            try { process.Start(); } catch (System.ComponentModel.Win32Exception) { throw new ApiException(503, "PowerShell 7 is required on the runner. Configure PLOTMANAGER_PWSH.", "engine_unavailable"); }
            started?.Invoke(process);
            // Pipe readers must be cancellable too. A descendant can inherit a
            // pipe handle even after the worker exits; waiting for EOF alone
            // would leave cancellation and the project lock stuck indefinitely.
            var stdout = process.StandardOutput.BaseStream.CopyToAsync(Stream.Null, cancellation);
            var stderr = process.StandardError.BaseStream.CopyToAsync(Stream.Null, cancellation);
            using var registration = cancellation.Register(() => { try { if (!process.HasExited) process.Kill(true); } catch (Exception ex) when (ex is InvalidOperationException or System.ComponentModel.Win32Exception) { } });
            try
            {
                await process.WaitForExitAsync(cancellation);
                await Task.WhenAll(stdout, stderr).WaitAsync(cancellation);
            }
            catch (OperationCanceledException)
            {
                // Only report cancellation after the owned worker really exits.
                // Kill(true) covers its current descendants; external services
                // and detached operations retain the documented no-rollback rule.
                try { if (!process.HasExited) process.Kill(true); } catch (Exception ex) when (ex is InvalidOperationException or System.ComponentModel.Win32Exception) { }
                await process.WaitForExitAsync(CancellationToken.None);
                try { await Task.WhenAll(stdout, stderr); } catch (OperationCanceledException) { } catch (IOException) { }
                throw;
            }
            cancellation.ThrowIfCancellationRequested();
            if (!File.Exists(responsePath)) throw new ApiException(400, "Engine request failed before producing a structured response.", "engine_error");
            JsonNode result;
            try { result = JsonNode.Parse(File.ReadAllText(responsePath)) ?? throw new FormatException(); }
            catch (Exception ex) when (ex is System.Text.Json.JsonException or FormatException) { throw new ApiException(500, "Engine returned an invalid structured response.", "engine_error"); }
            var operation = request["Operation"]?.GetValue<string>() ?? "";
            var nativeStatus = result["Status"]?.GetValue<string>();
            var nativeError = result["Error"];
            var failedRun = operation == "run" && nativeStatus == "Failed" && result["Steps"] is JsonArray;
            var sanitized = SecretStore.RedactEngineResponse(operation, result, redactions);
            // Decisions use native protocol fields, never sanitized user data.
            // A failed step is a valid structured run result; a failed bridge or
            // preflight remains an error before any operation is scheduled.
            if ((process.ExitCode != 0 && !failedRun) || nativeError != null)
                throw new ApiException(400, sanitized["Error"]?.ToString() ?? "The engine rejected this request.", "engine_error");
            return sanitized;
        }
        finally
        {
            File.Delete(requestPath);
            File.Delete(responsePath);
        }
    }
    public JsonObject Request(string operation, ProjectRecord project, IReadOnlyList<string> files, ExecutionRequest? execution = null)
    {
        var request = new JsonObject { ["Operation"] = operation, ["ConfigurationFiles"] = new JsonArray(files.Select(x => JsonValue.Create(x)).ToArray()), ["WorkDirectory"] = project.Directory };
        if (execution != null)
        {
            if (string.IsNullOrWhiteSpace(execution.Plot)) throw new ApiException(400, "Plot is required.");
            ProjectStore.ValidateReferences(execution.Overrides);
            request["Plot"] = execution.Plot;
            request["Overrides"] = execution.Overrides?.DeepClone() ?? new JsonObject();
            request["WhatIf"] = execution.WhatIf;
            if (!string.IsNullOrWhiteSpace(execution.InvocationId)) request["InvocationId"] = execution.InvocationId;
        }
        return request;
    }
}
