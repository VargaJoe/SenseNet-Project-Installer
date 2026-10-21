using System.Diagnostics;
using System.Text.Json.Nodes;

namespace PlotManager.Server;

public sealed class EngineClient(ServiceSettings settings, SecretStore secrets)
{
    public async Task<JsonNode> InvokeAsync(string owner, JsonObject request, string engineDirectory, string scratch, string? eventPath, Action<Process>? started, CancellationToken cancellation)
    {
        Directory.CreateDirectory(scratch);
        var requestPath = Path.Combine(scratch, "request-" + Guid.NewGuid().ToString("N") + ".json");
        var responsePath = Path.Combine(scratch, "response-" + Guid.NewGuid().ToString("N") + ".json");
        var environment = secrets.EnvironmentFor(owner);
        var redactions = new List<string>(environment.Values);
        var names = SecretStore.ReferencedEnvironment(request);
        if (request["ConfigurationFiles"] is JsonArray files)
            foreach (var file in files)
                foreach (var name in SecretStore.ReferencedEnvironment(JsonStore.Object(file!.GetValue<string>()))) names.Add(name);
        foreach (var name in names)
        {
            if (name.StartsWith("PLOTMANAGER_", StringComparison.OrdinalIgnoreCase) && !name.StartsWith("PLOTMANAGER_SECRET_", StringComparison.Ordinal)) throw new ApiException(400, "Service configuration environment variables cannot be used by a project.");
            var value = environment.GetValueOrDefault(name) ?? System.Environment.GetEnvironmentVariable(name);
            if (!string.IsNullOrEmpty(value)) redactions.Add(value);
        }
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
            foreach (var pair in environment) start.Environment[pair.Key] = pair.Value;
            using var process = new Process { StartInfo = start };
            try { process.Start(); } catch (System.ComponentModel.Win32Exception) { throw new ApiException(503, "PowerShell 7 is required on the runner. Configure PLOTMANAGER_PWSH.", "engine_unavailable"); }
            started?.Invoke(process);
            var stdout = process.StandardOutput.BaseStream.CopyToAsync(Stream.Null);
            var stderr = process.StandardError.BaseStream.CopyToAsync(Stream.Null);
            using var registration = cancellation.Register(() => { try { if (!process.HasExited) process.Kill(true); } catch (Exception ex) when (ex is InvalidOperationException or System.ComponentModel.Win32Exception) { } });
            await process.WaitForExitAsync(CancellationToken.None);
            await Task.WhenAll(stdout, stderr);
            cancellation.ThrowIfCancellationRequested();
            if (!File.Exists(responsePath)) throw new ApiException(400, "Engine request failed before producing a structured response.", "engine_error");
            JsonNode result;
            try { result = JsonNode.Parse(File.ReadAllText(responsePath)) ?? throw new FormatException(); }
            catch (Exception ex) when (ex is System.Text.Json.JsonException or FormatException) { throw new ApiException(500, "Engine returned an invalid structured response.", "engine_error"); }
            var sanitized = SecretStore.Redact(result, redactions)!;
            if ((process.ExitCode != 0 && sanitized["Status"] == null) || sanitized["Error"] != null)
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
