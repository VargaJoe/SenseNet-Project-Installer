using System.Diagnostics;
using System.Net;
using System.Net.Http.Json;
using System.Text.Json.Nodes;
using System.Security.Cryptography;
using System.Security.Cryptography.X509Certificates;
using System.Security.AccessControl;
using System.Security.Principal;
using Microsoft.AspNetCore.Builder;
using Microsoft.Extensions.DependencyInjection;
using PlotManager.Server;

internal static class ManagementTests
{
    private static int checks;
    private static string diagnosticState = "";
    private static void Check(bool condition, string name)
    {
        if (!condition) throw new Exception("FAIL: " + name);
        checks++;
        Console.WriteLine("PASS " + name);
    }
    private static async Task<JsonObject> Json(HttpResponseMessage response, HttpStatusCode expected = HttpStatusCode.OK)
    {
        var text = await response.Content.ReadAsStringAsync();
        if (response.StatusCode != expected) throw new Exception($"Expected {(int)expected}, got {(int)response.StatusCode}: {text}");
        return JsonNode.Parse(text)!.AsObject();
    }
    private static async Task<JsonObject> WaitRun(HttpClient client, string projectId, string runId)
    {
        for (var i = 0; i < 900; i++)
        {
            var run = await Json(await client.GetAsync($"/api/projects/{projectId}/runs/{runId}"));
            if (run["status"]!.ToString() is not ("Queued" or "Running")) return run;
            await Task.Delay(100);
        }
        var diagnosticFile = Path.Combine(diagnosticState, "runs", runId, "run.json");
        if (File.Exists(diagnosticFile))
        {
            var diagnostic = JsonStore.Read<RunRecord>(diagnosticFile);
            Console.Error.WriteLine($"Timed-out durable run: status={diagnostic.Status}, error={diagnostic.Error}, completedAt={diagnostic.CompletedAt}");
            var events = Path.Combine(diagnosticState, "runs", runId, "events.ndjson");
            if (File.Exists(events)) Console.Error.WriteLine(File.ReadAllText(events));
            var rawEvents = Path.Combine(diagnosticState, "runs", runId, "worker-events.ndjson");
            if (File.Exists(rawEvents)) Console.Error.WriteLine("Worker events: " + File.ReadAllText(rawEvents));
            Console.Error.WriteLine("Pending worker response files: " + Directory.EnumerateFiles(Path.Combine(diagnosticState, "runs", runId), "response-*.json").Count());
        }
        throw new Exception("Run did not finish within 90 seconds.");
    }
    private static HttpClient Client(WebApplication app, string? bearer = null)
    {
        var client = new HttpClient(new HttpClientHandler { CookieContainer = new CookieContainer() }) { BaseAddress = new Uri(app.Urls.Single()), Timeout = TimeSpan.FromMinutes(3) };
        client.DefaultRequestHeaders.Add("X-Plot-Request", "1");
        if (bearer != null) client.DefaultRequestHeaders.Authorization = new("Bearer", bearer);
        return client;
    }
    public static async Task<int> Main(string[] args)
    {
        var repository = Path.GetFullPath(Path.Combine(AppContext.BaseDirectory, "../../../../../"));
        var enginePath = Path.GetFullPath(Path.Combine(repository, "src/Deployment/Scripts"));
        var temporary = Path.Combine(Path.GetTempPath(), "PlotManager-BackendTests-" + Guid.NewGuid().ToString("N"));
        var state = Path.Combine(temporary, "state");
        diagnosticState = state;
        var projectRoot = Path.Combine(temporary, "projects");
        var token = "integration-only-" + Guid.NewGuid().ToString("N");
        var bobToken = "other-operator-" + Guid.NewGuid().ToString("N");
        var configuredEngine = OperatingSystem.IsWindows() ? @"\\?\" + enginePath : enginePath;
        var config = new Dictionary<string, string?> { ["urls"] = "http://127.0.0.1:0", ["PLOTMANAGER_MODE"] = "local", ["PLOTMANAGER_TOKEN"] = token, ["PLOTMANAGER_DATA"] = state, ["PLOTMANAGER_PROJECT_ROOT"] = projectRoot, ["PLOTMANAGER_ENGINE"] = configuredEngine, ["Logging:LogLevel:Default"] = "Warning", ["Logging:LogLevel:PlotManager.Server.RunManager"] = "Information" };
        WebApplication? app = null;
        try
        {
            VerifyOwnedDirectory(Path.Combine(temporary, "owned-modify-only"));
            if (args.Contains("--permissions-only", StringComparer.Ordinal))
            {
                Console.WriteLine($"{checks}/{checks} targeted directory permission assertions passed.");
                return 0;
            }
            app = global::Program.Build(Array.Empty<string>(), config);
            app.Services.GetRequiredService<ServiceSettings>().Users["bob"] = bobToken;
            await app.StartAsync();
            if (OperatingSystem.IsWindows())
            {
                using var nativePathClient = Client(app, token);
                var nativeCatalog = await Json(await nativePathClient.GetAsync("/api/catalog"));
                Check(nativeCatalog["engine"]!["Steps"]!.AsArray().Count == 49, "verbatim local engine directory executes the real worker catalog without changing PowerShell policy");
            }
            else Console.WriteLine("SKIP Windows verbatim-drive engine path regression on this OS.");
            if (args.Contains("--engine-path-only", StringComparer.Ordinal))
            {
                Console.WriteLine($"{checks}/{checks} targeted native engine path assertions passed.");
                return 0;
            }
            using var client = Client(app);
            Check((await client.GetAsync("/api/health")).IsSuccessStatusCode, "health is public");
            Check((await client.GetAsync("/api/projects")).StatusCode == HttpStatusCode.Unauthorized, "projects require authentication");
            Check((await client.PostAsJsonAsync("/api/session", new { token = "wrong" })).StatusCode == HttpStatusCode.Unauthorized, "invalid token rejected");
            using (var raw = new HttpClient { BaseAddress = client.BaseAddress })
                Check((await raw.PostAsJsonAsync("/api/session", new { token })).StatusCode == HttpStatusCode.Forbidden, "login requires CSRF marker");
            using (var cross = Client(app))
            {
                cross.DefaultRequestHeaders.Add("Origin", "https://untrusted.invalid");
                Check((await cross.PostAsJsonAsync("/api/session", new { token })).StatusCode == HttpStatusCode.Forbidden, "cross-origin login rejected");
            }
            var loginResponse = await client.PostAsJsonAsync("/api/session", new { token });
            _ = await Json(loginResponse);
            var cookie = loginResponse.Headers.GetValues("Set-Cookie").Single();
            Check(cookie.Contains("httponly", StringComparison.OrdinalIgnoreCase) && cookie.Contains("samesite=strict", StringComparison.OrdinalIgnoreCase), "session cookie is HttpOnly and Strict");
            Check((await Json(await client.GetAsync("/api/session")))["authenticated"]!.GetValue<bool>(), "cookie session works");
            using var bob = Client(app, bobToken);
            Check((await bob.GetAsync("/api/runner")).IsSuccessStatusCode, "native bearer authentication works");
            using (var spoof = Client(app, token))
            {
                spoof.DefaultRequestHeaders.Host = "untrusted.invalid";
                Check((await spoof.GetAsync("/api/runner")).StatusCode == HttpStatusCode.BadRequest, "local DNS rebinding Host rejected");
            }
            Check((await client.GetAsync("/api/browse?path=" + Uri.EscapeDataString(Path.GetPathRoot(temporary)!))).StatusCode == HttpStatusCode.BadRequest, "runner browsing rejects root traversal");
            var project = await Json(await client.PostAsJsonAsync("/api/projects", new { name = "Isolated sample", template = "generic" }), HttpStatusCode.Created);
            var id = project["id"]!.ToString();
            var directory = project["directory"]!.ToString();
            if (args.Contains("--secret-protocol-only", StringComparer.Ordinal))
            {
                await VerifySecretProtocol(app, client, id, directory);
                Console.WriteLine($"{checks}/{checks} targeted secret protocol assertions passed.");
                return 0;
            }
            if (args.Contains("--storage-only", StringComparer.Ordinal))
            {
                await VerifySharingFailure(client, id, state);
                Console.WriteLine($"{checks}/{checks} targeted backend assertions passed.");
                return 0;
            }
            Check(!project["definition"]!.ToJsonString().Contains(temporary), "portable project definition has relative paths");
            Check((await bob.GetAsync($"/api/projects/{id}")).StatusCode == HttpStatusCode.Forbidden, "project ownership enforced");
            Check((await bob.PostAsJsonAsync("/api/projects/open", new { directory })).StatusCode == HttpStatusCode.Forbidden, "open cannot claim another owner's project");
            Check((await client.PostAsJsonAsync("/api/projects", new { name = "escape", directory = Path.GetPathRoot(temporary) })).StatusCode == HttpStatusCode.BadRequest, "create rejects outside allowed root");
            Check((await bob.PostAsJsonAsync("/api/projects", new { name = "nested intrusion", directory = Path.Combine(directory, "nested") })).StatusCode == HttpStatusCode.Forbidden, "create cannot enter another owner's directory subtree");
            var openedAgain = await Json(await client.PostAsJsonAsync("/api/projects/open", new { directory = directory + Path.DirectorySeparatorChar }));
            Check(openedAgain["id"]!.ToString() == id, "trailing directory separator cannot create a second project identity");
            Check((await bob.GetAsync("/api/browse?path=" + Uri.EscapeDataString(directory))).StatusCode == HttpStatusCode.Forbidden, "runner browse cannot enter another owner's project");
            var bobBrowse = await Json(await bob.GetAsync("/api/browse"));
            Check(!bobBrowse["entries"]!.AsArray().Any(x => x!["path"]!.ToString() == directory), "runner browse hides other-owned project roots");
            var blank = await Json(await client.PostAsJsonAsync("/api/projects", new { name = "Blank native project" }), HttpStatusCode.Created);
            Check(blank["definition"]!["wizard"] == null && JsonStore.Object(Path.Combine(blank["directory"]!.ToString(), "default.json")).Count == 0, "no template creates a blank native project");
            var definition = await Json(await client.GetAsync($"/api/projects/{id}/definition"));
            var portable = definition["data"]!.DeepClone().AsObject();
            portable["name"] = "Renamed isolated sample";
            portable["FutureFeature"] = new JsonObject { ["preserved"] = true };
            portable["wizard"]!["groups"]![1]!["fields"]!.AsArray().Add(new JsonObject { ["key"] = "enabled", ["label"] = "Optional flag", ["type"] = "bool", ["required"] = false, ["settingPath"] = "Custom.Enabled" });
            var definitionSaved = await Json(await client.PutAsJsonAsync($"/api/projects/{id}/definition", new { etag = definition["etag"]!.ToString(), data = portable }));
            Check(definitionSaved["data"]!["FutureFeature"]!["preserved"]!.GetValue<bool>(), "definition editor preserves unknown project metadata");
            Check((await client.PutAsJsonAsync($"/api/projects/{id}/definition", new { etag = definition["etag"]!.ToString(), data = portable })).StatusCode == HttpStatusCode.Conflict, "definition editor rejects stale etag");
            var layerPath = $"/api/projects/{id}/layers/project";
            var layer = await Json(await client.GetAsync(layerPath));
            var data = JsonNode.Parse("""{"Unknown":{"zero":0,"false":false,"null":null,"array":[],"date":"2026-10-21T18:22:00+02:00"},"Sample":{"Message":"saved message"}}""")!.AsObject();
            var saved = await Json(await client.PutAsJsonAsync(layerPath, new { etag = layer["etag"]!.ToString(), data }));
            Check(JsonNode.DeepEquals(saved["data"], data), "layer roundtrip preserves unknown JSON and null false zero empty array");
            Check((await client.PutAsJsonAsync(layerPath, new { etag = saved["etag"]!.ToString(), data = (object?)null })).StatusCode == HttpStatusCode.BadRequest && JsonNode.DeepEquals((await Json(await client.GetAsync(layerPath)))["data"], data), "null save body cannot replace a configuration object");
            Check((await client.PutAsJsonAsync(layerPath, new { etag = layer["etag"]!.ToString(), data })).StatusCode == HttpStatusCode.Conflict, "stale layer etag rejected");
            var literal = data.DeepClone().AsObject(); literal["Password"] = "must-not-save";
            Check((await client.PutAsJsonAsync(layerPath, new { etag = saved["etag"]!.ToString(), data = literal })).StatusCode == HttpStatusCode.BadRequest, "literal secret rejected");
            _ = await Json(await client.PostAsJsonAsync($"/api/projects/{id}/environments", new { name = "test" }));
            var env = await Json(await client.GetAsync($"/api/projects/{id}/layers/environment:test"));
            Check(env["data"]!.AsObject().Count == 0, "new environment starts with inherited configuration");
            var secretValue = "isolated-secret-" + Guid.NewGuid().ToString("N");
            var secret = await Json(await client.PutAsJsonAsync("/api/secrets/example", new { value = secretValue }));
            Check(!secret.ToJsonString().Contains(secretValue), "secret write response contains reference only");
            Check(!File.ReadAllText(Path.Combine(state, "secrets.json")).Contains(secretValue), "secret is encrypted at rest");
            var sensitiveOutput = new JsonObject { [secretValue] = secretValue, ["number"] = 12345 };
            var protectedOutput = SecretStore.Redact(sensitiveOutput, new[] { secretValue, "12345" })!;
            Check(!protectedOutput.ToJsonString().Contains(secretValue) && !protectedOutput.ToJsonString().Contains("12345"), "redaction covers output keys and numeric secret scalars");
            Check((await Json(await bob.GetAsync("/api/secrets")))["secrets"]!.AsArray().Count == 0, "secrets isolated by authenticated owner");
            var catalog = await Json(await client.GetAsync("/api/catalog"));
            Check(catalog["engine"]!["Steps"]!.AsArray().Count >= 49, "catalog comes from real installed engine manifests");
            var effective = await Json(await client.GetAsync($"/api/projects/{id}/configuration?environment=development"));
            Check(effective["engine"]!["Configuration"]!["Sample"]!["Message"]!.ToString() == "saved message", "effective configuration uses native layered merge");
            Check(effective["engine"]!["Sources"]!["Sample.Message"]!.ToString().EndsWith("project.json"), "effective configuration exposes exact source file");
            var planRequest = new { plot = "install", environment = "development", overrides = new { } };
            var plan = await Json(await client.PostAsJsonAsync($"/api/projects/{id}/plan", planRequest));
            Check(plan["engine"]!["Steps"]!.AsArray().Count == 2, "native static plan includes both invocations");
            Check(!File.Exists(Path.Combine(directory, "hello.txt")), "static plan does not execute steps");
            Check((await client.PostAsJsonAsync($"/api/projects/{id}/plan", new { plot = "install", invocationId = "save" })).StatusCode == HttpStatusCode.BadRequest, "single step rejects unresolved prior output");
            var single = await Json(await client.PostAsJsonAsync($"/api/projects/{id}/runs", new { plot = "install", invocationId = "compose" }), HttpStatusCode.Accepted);
            var singleDone = await WaitRun(client, id, single["id"]!.ToString());
            Check(singleDone["status"]!.ToString() == "Succeeded" && singleDone["engine"]!["Steps"]!.AsArray().Count == 1, "single independent invocation executes real engine");
            var whatIf = await Json(await client.PostAsJsonAsync($"/api/projects/{id}/runs", new { plot = "install", whatIf = true }), HttpStatusCode.Accepted);
            var preview = await WaitRun(client, id, whatIf["id"]!.ToString());
            Check(preview["status"]!.ToString() == "Succeeded" && !File.Exists(Path.Combine(directory, "hello.txt")), "WhatIf completes without invoking package operations");
            var started = await Json(await client.PostAsJsonAsync($"/api/projects/{id}/runs", planRequest), HttpStatusCode.Accepted);
            var runId = started["id"]!.ToString();
            var done = await WaitRun(client, id, runId);
            Check(done["status"]!.ToString() == "Succeeded" && File.ReadAllText(Path.Combine(directory, "hello.txt")) == "saved message", "full plot executes actual filesystem operation");
            Check(done["snapshot"]!.AsObject().Any(x => x.Key.EndsWith("package.psd1")) && done["snapshot"]!.AsObject().Any(x => x.Key.EndsWith("project.json")), "run snapshots configuration and engine package hashes");
            var events = await Json(await client.GetAsync($"/api/projects/{id}/runs/{runId}/events?after=0"));
            Check(events["events"]!.AsArray().Any(x => x!["type"]!.ToString() == "StepStarted"), "durable live step events captured");
            var cursor = events["cursor"]!.GetValue<long>();
            Check((await Json(await client.GetAsync($"/api/projects/{id}/runs/{runId}/events?after={cursor}")))["events"]!.AsArray().Count == 0, "event cursor replay reconnect has no duplicates");
            Check((await bob.GetAsync($"/api/projects/{id}/runs/{runId}/events")).StatusCode == HttpStatusCode.Forbidden, "run replay enforces project ACL");
            await VerifySharingFailure(client, id, state);
            var requestProcess = new ProcessStartInfo("pwsh") { WorkingDirectory = directory, UseShellExecute = false, RedirectStandardOutput = true, RedirectStandardError = true };
            foreach (var argument in new[] { "-NoProfile", "-File", Path.Combine(enginePath, "Run.ps1"), "install", "-DefaultConfigPath", Path.Combine(directory, "default.json"), "-ConfigPath", Path.Combine(directory, "project.json"), "-EnvironmentConfigPath", Path.Combine(directory, "environments/development.json"), "-WorkDirectory", directory }) requestProcess.ArgumentList.Add(argument);
            File.Delete(Path.Combine(directory, "hello.txt"));
            using (var cli = Process.Start(requestProcess)!)
            {
                var stdout = cli.StandardOutput.ReadToEndAsync(); var stderr = cli.StandardError.ReadToEndAsync();
                await cli.WaitForExitAsync(); await Task.WhenAll(stdout, stderr);
                Check(cli.ExitCode == 0 && File.ReadAllText(Path.Combine(directory, "hello.txt")) == "saved message", "CLI and GUI produce identical layered execution result");
            }
            layer = await Json(await client.GetAsync(layerPath));
            data = layer["data"]!.DeepClone().AsObject();
            data["Plots"] = JsonNode.Parse("""{"invalid":{"Steps":[{"Id":"first","Step":"filesystem.write","With":{"Path":"should-not-exist.txt","Content":"bad"}},{"Id":"later","Step":"text.join","With":{"Items":123}}]},"reordered":{"Steps":[{"Id":"save","Step":"filesystem.write","With":{"Path":"bad-order.txt","Content":{"$ref":"steps.compose.Output.Text"}}},{"Id":"compose","Step":"text.join","With":{"Items":["hello"]}}]},"slow":{"Steps":[{"Id":"sleep","Step":"process.run","With":{"FilePath":"pwsh","Arguments":["-NoProfile","-NonInteractive","-Command","Start-Sleep -Seconds 60"],"TimeoutSeconds":90}}]},"secret":{"Steps":[{"Id":"read","Step":"text.join","With":{"Items":[{"$env":"PLOTMANAGER_SECRET_EXAMPLE"}]}}]}}""");
            data["Plots"]!["slow"]!["Steps"]![0]!["With"]!["Arguments"]![3] = "Set-Content -LiteralPath 'managed-child.pid' -Value $PID; Start-Sleep -Seconds 60";
            saved = await Json(await client.PutAsJsonAsync(layerPath, new { etag = layer["etag"]!.ToString(), data }));
            Check((await client.PostAsJsonAsync($"/api/projects/{id}/runs", new { plot = "invalid" })).StatusCode == HttpStatusCode.BadRequest && !File.Exists(Path.Combine(directory, "should-not-exist.txt")), "invalid later static setting prevents first operation");
            Check((await client.PostAsJsonAsync($"/api/projects/{id}/plan", new { plot = "reordered" })).StatusCode == HttpStatusCode.BadRequest, "reordering detects forward output dependency");
            var secretRun = await Json(await client.PostAsJsonAsync($"/api/projects/{id}/runs", new { plot = "secret" }), HttpStatusCode.Accepted);
            var secretDone = await WaitRun(client, id, secretRun["id"]!.ToString());
            Check(secretDone["status"]!.ToString() == "Succeeded" && !secretDone.ToJsonString().Contains(secretValue), "encrypted secret injected only into worker and redacted from results");
            await VerifyEnvironmentSnapshot(app, id, directory, enginePath, state, secretValue);
            var slow = await Json(await client.PostAsJsonAsync($"/api/projects/{id}/runs", new { plot = "slow" }), HttpStatusCode.Accepted);
            var slowId = slow["id"]!.ToString();
            Check((await client.PutAsJsonAsync(layerPath, new { etag = saved["etag"]!.ToString(), data })).StatusCode == HttpStatusCode.Conflict, "active run locks editing");
            Check((await client.PostAsJsonAsync($"/api/projects/{id}/runs", new { plot = "install" })).StatusCode == HttpStatusCode.Conflict, "active run locks conflicting execution");
            // A portable runtime on mounted storage starts both the managed
            // worker and its package child. Wait for readiness, not a 15s SLA.
            for (var i = 0; i < 600 && !File.Exists(Path.Combine(directory, "managed-child.pid")); i++) await Task.Delay(100);
            Check(File.Exists(Path.Combine(directory, "managed-child.pid")), "cancellation test reaches actual package child process");
            var childPid = int.Parse(File.ReadAllText(Path.Combine(directory, "managed-child.pid")).Trim());
            using (var reconnect = Client(app, token))
            {
                var live = await Json(await reconnect.GetAsync($"/api/projects/{id}/runs/{slowId}/events"));
                Check(live["status"]!.ToString() == "Running" && live["events"]!.AsArray().Any(x => x!["type"]!.ToString() == "StepStarted"), "new client reconnects to live background run and events");
            }
            var snapshotFile = Path.Combine(state, "runs", slowId, "snapshot/configuration/project.json");
            var frozenLayer = File.ReadAllText(snapshotFile);
            var liveFile = Path.Combine(directory, "project.json");
            var originalLayer = File.ReadAllText(liveFile);
            File.WriteAllText(liveFile, originalLayer + "\n ");
            Check(File.ReadAllText(snapshotFile) == frozenLayer && ProjectStore.Hash(snapshotFile) == slow["snapshot"]!["snapshot/configuration/project.json"]!.ToString(), "active snapshot stays immutable after direct source file change");
            File.WriteAllText(liveFile, originalLayer);
            _ = await Json(await client.PostAsync($"/api/projects/{id}/runs/{slowId}/cancel", null));
            var cancelled = await WaitRun(client, id, slowId);
            Check(cancelled["status"]!.ToString() == "Cancelled" && cancelled["error"]!.ToString().Contains("No rollback"), "cancellation kills worker and states no rollback");
            bool childGone;
            try { using var child = Process.GetProcessById(childPid); childGone = child.HasExited; } catch (ArgumentException) { childGone = true; }
            Check(childGone, "cancellation terminates package grandchild process tree");
            var wizard = await Json(await client.GetAsync($"/api/projects/{id}/wizard"));
            Check(wizard["groups"]!.AsArray().Count > 0, "generic installer has declarative form groups");
            layer = await Json(await client.GetAsync(layerPath));
            var caseData = layer["data"]!.DeepClone().AsObject();
            var existingSample = caseData["Sample"]!.DeepClone().AsObject();
            existingSample["Vendor"] = new JsonObject { ["unknownMetadata"] = "preserve me" };
            caseData.Remove("Sample"); caseData["sample"] = existingSample;
            layer = await Json(await client.PutAsJsonAsync(layerPath, new { etag = layer["etag"]!.ToString(), data = caseData }));
            var wizardLayer = await Json(await client.PostAsJsonAsync($"/api/projects/{id}/wizard", new { etag = layer["etag"]!.ToString(), values = new { target = "wizard.txt", message = "wizard passed", enabled = false } }));
            Check(wizardLayer["data"]!["Custom"]!["Enabled"]!.GetValue<bool>() == false, "declarative wizard applies custom typed binding without hardcoded fields");
            Check(wizardLayer["data"]!["Sample"] == null && wizardLayer["data"]!["sample"]!["Vendor"]!["unknownMetadata"]!.ToString() == "preserve me", "wizard respects engine key casing and preserves vendor metadata");
            var wizardRun = await Json(await client.PostAsJsonAsync($"/api/projects/{id}/runs", new { plot = "install" }), HttpStatusCode.Accepted);
            var wizardDone = await WaitRun(client, id, wizardRun["id"]!.ToString());
            Check(wizardDone["status"]!.ToString() == "Succeeded" && File.ReadAllText(Path.Combine(directory, "wizard.txt")) == "wizard passed", "guided sample saves normal configuration and executes");
            var upload = await Json(await client.PostAsJsonAsync($"/api/projects/{id}/uploads", new { name = "sample.txt", contentBase64 = Convert.ToBase64String("uploaded"u8.ToArray()) }));
            Check(File.ReadAllText(upload["path"]!.ToString()) == "uploaded" && upload["relativePath"]!.ToString().StartsWith("uploads/"), "browser upload is explicit runner-side project file");
            var inherited = await Json(await client.GetAsync(layerPath));
            var inheritedData = inherited["data"]!.DeepClone().AsObject();
            foreach (var sampleKey in inheritedData.Where(x => x.Key.Equals("Sample", StringComparison.OrdinalIgnoreCase)).Select(x => x.Key).ToArray()) inheritedData.Remove(sampleKey);
            _ = await Json(await client.PutAsJsonAsync(layerPath, new { etag = inherited["etag"]!.ToString(), data = inheritedData }));
            var restored = await Json(await client.GetAsync($"/api/projects/{id}/configuration"));
            Check(restored["engine"]!["Configuration"]!["Sample"]!["Message"]!.ToString() == "Hello from Plot Manager", "removing selected override restores inheritance");
            // Persist a realistic unfinished record and recreate the service against
            // the same isolated data to prove recovery and history reconnect.
            var recoveryId = Guid.NewGuid().ToString("N");
            JsonStore.Write(Path.Combine(state, "runs", recoveryId, "run.json"), new RunRecord { Id = recoveryId, ProjectId = id, Owner = "local", Plot = "install", Status = "Running" });
            await app.StopAsync(); await app.DisposeAsync(); app = null;
            app = global::Program.Build(Array.Empty<string>(), config); await app.StartAsync();
            using var reconnected = Client(app, token);
            var recovered = await Json(await reconnected.GetAsync($"/api/projects/{id}/runs/{recoveryId}"));
            Check(recovered["status"]!.ToString() == "Interrupted", "startup marks unfinished runs Interrupted without retry");
            var history = await Json(await reconnected.GetAsync($"/api/projects/{id}/runs"));
            Check(history["runs"]!.AsArray().Count >= 7, "durable history survives service restart and reconnect");
            Check((await reconnected.GetAsync($"/api/projects/{id}/runs/{runId}/events")).IsSuccessStatusCode, "durable event replay survives restart");
            using (var cookieClient = Client(app))
            {
                _ = await Json(await cookieClient.PostAsJsonAsync("/api/session", new { token }));
                var serviceSettings = app.Services.GetRequiredService<ServiceSettings>();
                serviceSettings.Users["local"] = "rotated-" + Guid.NewGuid().ToString("N");
                Check((await cookieClient.GetAsync("/api/projects")).StatusCode == HttpStatusCode.Unauthorized, "rotating operator token revokes existing cookie session");
                serviceSettings.Users["local"] = token;
            }
            await using (var second = global::Program.Build(Array.Empty<string>(), config))
            {
                var rejected = false;
                try { await second.StartAsync(); } catch (InvalidOperationException) { rejected = true; }
                Check(rejected, "second service cannot open the same durable runner state");
            }
            using (var rsa = RSA.Create(2048))
            {
                var certificateRequest = new CertificateRequest("CN=localhost", rsa, HashAlgorithmName.SHA256, RSASignaturePadding.Pkcs1);
                using var certificate = certificateRequest.CreateSelfSigned(DateTimeOffset.UtcNow.AddDays(-1), DateTimeOffset.UtcNow.AddDays(1));
                var pfx = Path.Combine(temporary, "https-test.pfx");
                File.WriteAllBytes(pfx, certificate.Export(X509ContentType.Pfx, "isolated-pfx-password"));
                var hostedConfig = new Dictionary<string, string?>(config)
                {
                    ["urls"] = "https://127.0.0.1:0", ["PLOTMANAGER_MODE"] = "hosted", ["PLOTMANAGER_USERS"] = System.Text.Json.JsonSerializer.Serialize(new { alice = token }), ["PLOTMANAGER_DATA"] = Path.Combine(temporary, "hosted-state"), ["PLOTMANAGER_PROJECT_ROOT"] = Path.Combine(temporary, "hosted-projects"), ["Kestrel:Certificates:Default:Path"] = pfx, ["Kestrel:Certificates:Default:Password"] = "isolated-pfx-password"
                };
                await using var hosted = global::Program.Build(Array.Empty<string>(), hostedConfig); await hosted.StartAsync();
                // Only this isolated test handler trusts the test's ephemeral cert.
                using var https = new HttpClient(new HttpClientHandler { ServerCertificateCustomValidationCallback = (_, serverCertificate, _, _) => serverCertificate?.Thumbprint == certificate.Thumbprint }) { BaseAddress = new Uri(hosted.Urls.Single()) };
                https.DefaultRequestHeaders.Add("X-Plot-Request", "1");
                Check((await https.GetAsync("/api/runner")).StatusCode == HttpStatusCode.Unauthorized, "real hosted HTTPS runner requires authentication");
                var secureLogin = await https.PostAsJsonAsync("/api/session", new { token });
                _ = await Json(secureLogin);
                Check(secureLogin.Headers.GetValues("Set-Cookie").Single().Contains("secure", StringComparison.OrdinalIgnoreCase), "hosted HTTPS session cookie is Secure");
                var hostedRunner = await Json(await https.GetAsync("/api/runner"));
                Check(hostedRunner["mode"]!.ToString() == "hosted" && hostedRunner["executionTarget"]!.ToString() == "service-host", "hosted browser executes only on authenticated service host");
                await hosted.StopAsync();
            }
            CheckThrows(() => new ServiceSettings { Mode = "local" }.ValidateUrls("http://0.0.0.0:5188"), "local mode refuses remote bind");
            CheckThrows(() => new ServiceSettings { Mode = "hosted" }.ValidateUrls("http://127.0.0.1:5188"), "hosted mode refuses plaintext HTTP");
            var unsafeEndpoint = new Dictionary<string, string?>(config) { ["Kestrel:Endpoints:AccidentalPublic:Url"] = "http://0.0.0.0:5188" };
            CheckThrows(() => global::Program.Build(Array.Empty<string>(), unsafeEndpoint), "Kestrel endpoint configuration cannot bypass local binding restriction");
            var unsafeOperator = new Dictionary<string, string?>(config) { ["PLOTMANAGER_MODE"] = "hosted", ["PLOTMANAGER_USERS"] = System.Text.Json.JsonSerializer.Serialize(new Dictionary<string, string> { ["alice:child"] = token }) };
            CheckThrows(() => global::Program.Build(Array.Empty<string>(), unsafeOperator), "operator IDs cannot collide with secret ownership namespaces");
            await VerifySecretProtocol(app, reconnected, id, directory);
            Console.WriteLine($"{checks}/{checks} management backend assertions passed on {System.Runtime.InteropServices.RuntimeInformation.OSDescription}.");
            return 0;
        }
        catch (Exception ex) { Console.Error.WriteLine(ex); return 1; }
        finally
        {
            if (app != null) { await app.StopAsync(); await app.DisposeAsync(); }
            var safeRoot = Path.GetFullPath(Path.GetTempPath()) + (Path.EndsInDirectorySeparator(Path.GetTempPath()) ? "" : Path.DirectorySeparatorChar);
            if (Directory.Exists(temporary) && Path.GetFullPath(temporary).StartsWith(safeRoot, OperatingSystem.IsWindows() ? StringComparison.OrdinalIgnoreCase : StringComparison.Ordinal)) Directory.Delete(temporary, true);
        }
    }
    private static void VerifyOwnedDirectory(string path)
    {
        if (!OperatingSystem.IsWindows()) { Console.WriteLine("SKIP Windows owned-directory ACL regression on this OS."); return; }
        var identity = WindowsIdentity.GetCurrent().User!;
        var directory = Directory.CreateDirectory(path);
        Check(identity.Equals(directory.GetAccessControl(AccessControlSections.Owner).GetOwner(typeof(SecurityIdentifier))), "permission fixture directory belongs to the service identity");
        // Reproduce a Rust-created desktop data directory: the owner may edit
        // its DACL but Modify does not grant WRITE_OWNER. Reassigning the same
        // owner unnecessarily would fail even though securing the DACL is allowed.
        var modify = new DirectorySecurity();
        modify.SetAccessRuleProtection(true, false);
        modify.AddAccessRule(new FileSystemAccessRule(identity, FileSystemRights.Modify, InheritanceFlags.ContainerInherit | InheritanceFlags.ObjectInherit, PropagationFlags.None, AccessControlType.Allow));
        directory.SetAccessControl(modify);
        ServiceSettings.PrivateDirectory(path);
        ServiceSettings.PrivateDirectory(path);
        var actual = directory.GetAccessControl(AccessControlSections.Owner | AccessControlSections.Access);
        var rules = actual.GetAccessRules(true, true, typeof(SecurityIdentifier)).Cast<FileSystemAccessRule>().ToArray();
        Check(identity.Equals(actual.GetOwner(typeof(SecurityIdentifier))) && actual.AreAccessRulesProtected && rules.Length == 1 && rules[0].IdentityReference.Equals(identity) && rules[0].FileSystemRights == FileSystemRights.FullControl && rules[0].AccessControlType == AccessControlType.Allow && rules[0].InheritanceFlags == (InheritanceFlags.ContainerInherit | InheritanceFlags.ObjectInherit), "owned Modify-only directory becomes private and startup remains idempotent without WRITE_OWNER");
        var child = Path.Combine(path, "private-child.txt");
        File.WriteAllText(child, "isolated ACL regression");
        var childRules = new FileInfo(child).GetAccessControl(AccessControlSections.Access).GetAccessRules(true, true, typeof(SecurityIdentifier)).Cast<FileSystemAccessRule>().ToArray();
        Check(childRules.Length == 1 && childRules[0].IdentityReference.Equals(identity) && childRules[0].AccessControlType == AccessControlType.Allow && childRules[0].FileSystemRights == FileSystemRights.FullControl, "state files inherit only the service identity's full control");
    }
    private static void CheckThrows(Action action, string name)
    {
        try { action(); } catch (InvalidOperationException) { Check(true, name); return; }
        throw new Exception("FAIL: " + name);
    }
    private static async Task VerifySecretProtocol(WebApplication app, HttpClient client, string id, string directory)
    {
        var secrets = app.Services.GetRequiredService<SecretStore>();
        var engine = app.Services.GetRequiredService<EngineClient>();
        var layerPath = $"/api/projects/{id}/layers/project";
        var original = await Json(await client.GetAsync(layerPath));
        var fixture = Path.Combine(directory, "secret-payload.json");
        try
        {
            _ = secrets.Save("local", "short_unused", "a");
            _ = secrets.Save("local", "failure_unused", "Failed");
            var capturedCatalog = engine.CaptureEnvironment("local", new JsonObject { ["Operation"] = "catalog" });
            Check(capturedCatalog.Count == 0, "unused owner secrets are not injected or used to redact catalog metadata");
            var catalog = (await Json(await client.GetAsync("/api/catalog")))["engine"]!.AsObject();
            var join = catalog["Steps"]!.AsArray().Single(x => x!["Id"]!.ToString() == "text.join")!;
            Check(join["Package"]!.ToString() == "text" && join["Parameters"]!["Items"]!["Type"]!.ToString() == "array", "one-character unused secret leaves catalog control keys and schema types intact");

            _ = secrets.Save("local", "short_used", "a");
            _ = secrets.Save("local", "number_used", "7");
            _ = secrets.Save("local", "failure_used", "Failed");
            JsonStore.Write(fixture, new JsonObject { ["a"] = "a", ["number"] = 7 });
            var data = JsonNode.Parse("""
                {"NumberInput":{"$env":"PLOTMANAGER_SECRET_NUMBER_USED"},"FailureInput":{"$env":"PLOTMANAGER_SECRET_FAILURE_USED"},"Plots":{"safely-redacted":{"Steps":[{"Id":"start","Step":"text.join","With":{"Items":[{"$env":"PLOTMANAGER_SECRET_SHORT_USED"}],"Separator":""}},{"Id":"data","Step":"json.read","With":{"Path":"secret-payload.json"}}]},"actually-fails":{"Steps":[{"Id":"failure","Step":"process.run","With":{"FilePath":"pwsh","Arguments":["-NoProfile","-NonInteractive","-Command","exit 9"],"TimeoutSeconds":15}}]}}}
                """)!.AsObject();
            _ = await Json(await client.PutAsJsonAsync(layerPath, new { etag = original["etag"]!.ToString(), data }));
            var project = app.Services.GetRequiredService<ProjectStore>().Get("local", id);
            var request = engine.Request("plan", project, new[] { Path.Combine(directory, "project.json") }, new ExecutionRequest("safely-redacted", null, null, null));
            var captured = engine.CaptureEnvironment("local", request);
            Check(captured.ContainsKey("PLOTMANAGER_SECRET_SHORT_USED") && captured.ContainsKey("PLOTMANAGER_SECRET_NUMBER_USED") && !captured.ContainsKey("PLOTMANAGER_SECRET_SHORT_UNUSED"), "worker snapshot includes only referenced owner secrets");
            var inspect = (await Json(await client.GetAsync($"/api/projects/{id}/configuration")))["engine"]!;
            Check(inspect["Configuration"]!["Plots"]!["safely-redacted"]!["Steps"]![0]!["Id"]!.ToString() == "start" && inspect["Sources"]!["Plots.safely-redacted.Steps"]!.ToString() == Path.Combine(directory, "project.json"), "used one-character secret leaves raw inspection identifiers and file origins intact");
            var plan = (await Json(await client.PostAsJsonAsync($"/api/projects/{id}/plan", new { plot = "safely-redacted" })))["engine"]!;
            Check(plan["Steps"]![0]!["Id"]!.ToString() == "start" && plan["Steps"]![0]!["Settings"]!["Separator"] != null, "plan preserves invocation IDs and top-level parameter names");
            Check(plan["Steps"]![0]!["Settings"]!["Items"]![0]!.ToString().Equals("[redacted]", StringComparison.OrdinalIgnoreCase), "evaluated secret settings are masked once without corrupting the marker");
            Check(plan["Steps"]![0]!["Origins"]!["Items"]!["File"]!.ToString() == Path.Combine(directory, "project.json") && plan["Configuration"]!["NumberInput"]!["$env"]!.ToString() == "PLOTMANAGER_SECRET_NUMBER_USED", "plan provenance and atomic directive identifiers are preserved");
            var run = await Json(await client.PostAsJsonAsync($"/api/projects/{id}/runs", new { plot = "safely-redacted" }), HttpStatusCode.Accepted);
            var done = await WaitRun(client, id, run["id"]!.ToString());
            Check(done["status"]!.ToString() == "Succeeded" && done["engine"]!["Status"]!.ToString() == "Succeeded" && done["engine"]!["Steps"]![0]!["Id"]!.ToString() == "start", "used short secrets preserve actual successful run control fields");
            Check(done["engine"]!["Steps"]![0]!["Output"]!["Text"]!.ToString().Equals("[redacted]", StringComparison.OrdinalIgnoreCase), "real worker secret output is redacted without damaging output field names");
            var output = done["engine"]!["Steps"]![1]!["Output"]!.AsObject().Select(x => x.Value).OfType<JsonObject>().Single();
            Check(!output.ContainsKey("a") && output.Any(x => x.Key.Equals("[redacted]", StringComparison.OrdinalIgnoreCase)) && output["number"]!.ToString().Equals("[redacted]", StringComparison.OrdinalIgnoreCase), "real worker payload dictionary keys and numeric secret scalars remain redacted");
            var failedRun = await Json(await client.PostAsJsonAsync($"/api/projects/{id}/runs", new { plot = "actually-fails" }), HttpStatusCode.Accepted);
            var failed = await WaitRun(client, id, failedRun["id"]!.ToString());
            Check(failed["status"]!.ToString() == "Failed" && failed["engine"]!["Status"]!.ToString() == "Failed" && failed["engine"]!["Steps"]![0]!["Status"]!.ToString() == "Failed", "a secret equal to Failed cannot turn an actual failed step into successful history");
            var unexpected = new JsonObject { ["Status"] = "Failed", ["Error"] = "a Failed 7" };
            var sanitized = SecretStore.RedactEngineResponse("run", unexpected, new[] { "a", "Failed", "7" });
            Check(sanitized["Status"]!.ToString() == "Failed" && sanitized["Error"]!.ToString().Split("[REDACTED]").Length == 4, "general engine errors mask values while preserving authoritative failure control");
        }
        finally
        {
            foreach (var name in new[] { "short_unused", "failure_unused", "short_used", "number_used", "failure_used" }) secrets.Delete("local", name);
            var current = await Json(await client.GetAsync(layerPath));
            _ = await Json(await client.PutAsJsonAsync(layerPath, new { etag = current["etag"]!.ToString(), data = original["data"]!.DeepClone() }));
            if (File.Exists(fixture)) File.Delete(fixture);
        }
    }
    private static async Task VerifyEnvironmentSnapshot(WebApplication app, string projectId, string directory, string enginePath, string state, string originalSecret)
    {
        var inheritedName = "PLOT_TEST_FREEZE_" + Guid.NewGuid().ToString("N");
        var absentName = inheritedName + "_ABSENT";
        var originalEnvironment = "initial-environment-" + Guid.NewGuid().ToString("N");
        var freezeFile = Path.Combine(directory, "environment-freeze.json");
        var configuration = new JsonObject { ["Plots"] = new JsonObject { ["freeze"] = new JsonObject { ["Steps"] = new JsonArray(
            new JsonObject { ["Id"] = "secret", ["Step"] = "filesystem.write", ["With"] = new JsonObject { ["Path"] = "frozen-secret.txt", ["Content"] = new JsonObject { ["$ENV"] = "PLOTMANAGER_SECRET_EXAMPLE" } } },
            new JsonObject { ["Id"] = "inherited", ["Step"] = "filesystem.write", ["With"] = new JsonObject { ["Path"] = "frozen-environment.txt", ["Content"] = new JsonObject { ["$Env"] = inheritedName } } }) } }, ["AbsentUnused"] = new JsonObject { ["$ENV"] = absentName } };
        JsonStore.Write(freezeFile, configuration);
        var secrets = app.Services.GetRequiredService<SecretStore>();
        var engine = app.Services.GetRequiredService<EngineClient>();
        var project = app.Services.GetRequiredService<ProjectStore>().Get("local", projectId);
        Environment.SetEnvironmentVariable(inheritedName, originalEnvironment);
        try
        {
            var request = engine.Request("run", project, new[] { freezeFile }, new ExecutionRequest("freeze", null, null, null));
            var captured = engine.CaptureEnvironment("local", request);
            _ = secrets.Save("local", "example", "rotated-secret-" + Guid.NewGuid().ToString("N"));
            Environment.SetEnvironmentVariable(inheritedName, "changed-after-submit");
            Environment.SetEnvironmentVariable(absentName, "added-after-submit");
            using var timeout = new CancellationTokenSource(TimeSpan.FromMinutes(2));
            _ = await engine.InvokeAsync("local", request, enginePath, Path.Combine(state, "freeze-test"), null, null, timeout.Token, captured);
            Check(File.ReadAllText(Path.Combine(directory, "frozen-secret.txt")) == originalSecret, "real worker uses submitted encrypted secret snapshot after secret rotation");
            Check(File.ReadAllText(Path.Combine(directory, "frozen-environment.txt")) == originalEnvironment, "real worker uses submitted inherited environment snapshot after environment change");
            Check(captured.ContainsKey(absentName) && captured[absentName] == null, "worker environment snapshot freezes absent referenced variables too");
        }
        finally
        {
            _ = secrets.Save("local", "example", originalSecret);
            Environment.SetEnvironmentVariable(inheritedName, null);
            Environment.SetEnvironmentVariable(absentName, null);
        }
    }
    private static async Task VerifySharingFailure(HttpClient client, string projectId, string state)
    {
        if (!OperatingSystem.IsWindows()) { Console.WriteLine("SKIP Windows file-sharing fault injection on this OS."); return; }
        var run = await Json(await client.PostAsJsonAsync($"/api/projects/{projectId}/runs", new { plot = "install", invocationId = "compose" }), HttpStatusCode.Accepted);
        var id = run["id"]!.ToString();
        var recordPath = Path.Combine(state, "runs", id, "run.json");
        // Deliberately deny replacement of this isolated history file while the
        // real worker runs. Reads remain allowed; Windows MoveFile reports
        // ERROR_ACCESS_DENIED for this denied replacement (HResult 0x80070005).
        using var held = new FileStream(recordPath, FileMode.Open, FileAccess.Read, FileShare.Read);
        var terminal = await WaitRun(client, projectId, id);
        Check(terminal["status"]!.ToString() == "Failed" && terminal["error"]!.ToString().Contains("terminal history could not be saved"), "history sharing failure reports honest Failed instead of stuck Queued/Running");
        var listed = await Json(await client.GetAsync($"/api/projects/{projectId}/runs"));
        Check(listed["runs"]!.AsArray().Single(x => x!["id"]!.ToString() == id)!["status"]!.ToString() == "Failed", "history list agrees with detail after persistence failure");
    }
}
