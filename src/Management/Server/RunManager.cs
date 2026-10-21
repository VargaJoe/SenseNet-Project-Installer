using System.Collections.Concurrent;
using System.Text.Json.Nodes;

namespace PlotManager.Server;

public sealed class RunManager(ServiceSettings settings, ProjectStore projects, EngineClient engine) : IHostedService
{
    private sealed class ActiveRun(RunRecord record, IDisposable projectLock)
    {
        public RunRecord Record { get; } = record;
        public IDisposable ProjectLock { get; } = projectLock;
        public CancellationTokenSource Cancellation { get; } = new();
        public Task? Task { get; set; }
        public object Gate { get; } = new();
        public bool UserCancelled { get; set; }
    }
    private readonly ConcurrentDictionary<string, ActiveRun> active = new();
    private readonly CancellationTokenSource shutdown = new();
    private readonly object eventGate = new();
    private string Root => Path.Combine(settings.DataDirectory, "runs");
    private string Folder(string id)
    {
        if (!Guid.TryParseExact(id, "N", out _)) throw new ApiException(404, "Run not found.");
        return SafePaths.Within(Root, id);
    }
    private string RecordPath(string id) => Path.Combine(Folder(id), "run.json");
    private void Save(RunRecord record) => JsonStore.Write(RecordPath(record.Id), record);
    public Task StartAsync(CancellationToken cancellationToken)
    {
        ServiceSettings.PrivateDirectory(Root);
        foreach (var file in Directory.EnumerateDirectories(Root).Select(x => Path.Combine(x, "run.json")).Where(File.Exists))
        {
            SafePaths.Within(Root, file);
            var record = JsonStore.Read<RunRecord>(file);
            if (record.Status is "Queued" or "Running")
            {
                record.Status = "Interrupted";
                record.CompletedAt = DateTimeOffset.UtcNow;
                record.Error = "The service stopped before this run completed. External operations may still be active; no rollback was performed.";
                Save(record);
                AppendEvent(record, new JsonObject { ["type"] = "Interrupted", ["status"] = "Interrupted" });
            }
        }
        return Task.CompletedTask;
    }
    public async Task StopAsync(CancellationToken cancellationToken)
    {
        shutdown.Cancel();
        foreach (var run in active.Values) run.Cancellation.Cancel();
        var tasks = active.Values.Select(x => x.Task ?? Task.CompletedTask).ToArray();
        try { await Task.WhenAll(tasks).WaitAsync(TimeSpan.FromSeconds(10), cancellationToken); } catch (OperationCanceledException) { } catch (TimeoutException) { }
    }
    public string? ActiveId(string projectId) => active.Values.FirstOrDefault(x => x.Record.ProjectId == projectId)?.Record.Id;
    public async Task<RunRecord> Start(string owner, ProjectRecord project, ExecutionRequest execution)
    {
        var projectLock = projects.Lock(project.Id);
        ActiveRun? run = null;
        string? createdFolder = null;
        bool scheduled = false;
        try
        {
            var record = new RunRecord { ProjectId = project.Id, Owner = owner, Plot = execution.Plot, Environment = execution.Environment, InvocationId = execution.InvocationId, WhatIf = execution.WhatIf };
            var folder = Folder(record.Id);
            createdFolder = folder;
            Directory.CreateDirectory(folder);
            var enginePath = Path.Combine(folder, "snapshot/engine");
            CopyDirectory(Path.Combine(settings.EngineDirectory, "Core"), Path.Combine(enginePath, "Core"), record.Snapshot, folder);
            CopyDirectory(Path.Combine(settings.EngineDirectory, "Auto"), Path.Combine(enginePath, "Auto"), record.Snapshot, folder);
            CopyFile(Path.Combine(settings.EngineDirectory, "Invoke-ManagedRequest.ps1"), Path.Combine(enginePath, "Invoke-ManagedRequest.ps1"), record.Snapshot, folder);
            var files = new List<string>();
            foreach (var layer in projects.Layers(project, execution.Environment))
            {
                var target = Path.Combine(folder, "snapshot/configuration", layer.Path);
                CopyFile(SafePaths.RelativeFile(project.Directory, layer.Path), target, record.Snapshot, folder);
                files.Add(target);
            }
            var definitionPath = Path.Combine(folder, "snapshot/plot-project.json");
            CopyFile(Path.Combine(project.Directory, "plot-project.json"), definitionPath, record.Snapshot, folder);
            var request = engine.Request("plan", project, files, execution);
            // Static validation runs against exactly the copied engine and layers.
            // The run has not been scheduled and no package command is invoked yet.
            using (var preflight = CancellationTokenSource.CreateLinkedTokenSource(shutdown.Token))
            {
                preflight.CancelAfter(TimeSpan.FromMinutes(2));
                _ = await engine.InvokeAsync(owner, request, enginePath, folder, null, null, preflight.Token);
            }
            request["Operation"] = "run";
            var requestSnapshot = Path.Combine(folder, "snapshot/request.json");
            JsonStore.Write(requestSnapshot, request);
            record.Snapshot["snapshot/request.json"] = ProjectStore.Hash(requestSnapshot);
            run = new ActiveRun(record, projectLock);
            Save(record);
            AppendEvent(record, new JsonObject { ["type"] = "Queued", ["status"] = "Queued" });
            if (!active.TryAdd(record.Id, run)) throw new InvalidOperationException("Duplicate run ID.");
            run.Task = Task.Run(() => Execute(run, request, enginePath, folder));
            scheduled = true;
            return record;
        }
        catch
        {
            if (!scheduled)
            {
                if (run != null) active.TryRemove(run.Record.Id, out _);
                projectLock.Dispose();
                if (createdFolder != null && Directory.Exists(createdFolder)) Directory.Delete(SafePaths.Within(Root, createdFolder), true);
            }
            throw;
        }
    }
    private static void CopyDirectory(string source, string destination, Dictionary<string, string> hashes, string root)
    {
        if (!Directory.Exists(source)) throw new ApiException(503, "The complete engine installation is required.", "engine_unavailable");
        SafePaths.EnsureNoLinks(source);
        Directory.CreateDirectory(destination);
        foreach (var entry in Directory.EnumerateFileSystemEntries(source))
        {
            SafePaths.EnsureNoLinks(entry);
            var target = Path.Combine(destination, Path.GetFileName(entry));
            if (Directory.Exists(entry)) CopyDirectory(entry, target, hashes, root);
            else CopyFile(entry, target, hashes, root);
        }
    }
    private static void CopyFile(string source, string target, Dictionary<string, string> hashes, string root)
    {
        SafePaths.EnsureNoLinks(source);
        if (!File.Exists(source)) throw new ApiException(503, "A required engine or configuration file is missing.");
        Directory.CreateDirectory(Path.GetDirectoryName(target)!);
        File.Copy(source, target, false);
        hashes[Path.GetRelativePath(root, target).Replace('\\', '/')] = ProjectStore.Hash(target);
    }
    private async Task Execute(ActiveRun run, JsonObject request, string enginePath, string folder)
    {
        using var linked = CancellationTokenSource.CreateLinkedTokenSource(shutdown.Token, run.Cancellation.Token);
        using var eventsDone = new CancellationTokenSource();
        var nativeEvents = Path.Combine(folder, "worker-events.ndjson");
        Task? watcher = null;
        try
        {
            lock (run.Gate)
            {
                run.Record.Status = "Running";
                run.Record.StartedAt = DateTimeOffset.UtcNow;
                Save(run.Record);
            }
            AppendEvent(run.Record, new JsonObject { ["type"] = "Running", ["status"] = "Running" });
            watcher = PumpEvents(run, nativeEvents, eventsDone.Token);
            var result = await engine.InvokeAsync(run.Record.Owner, request, enginePath, folder, nativeEvents, null, linked.Token);
            lock (run.Gate)
            {
                run.Record.Engine = result;
                run.Record.Status = result["Status"]?.GetValue<string>() == "Failed" ? "Failed" : "Succeeded";
            }
        }
        catch (OperationCanceledException)
        {
            lock (run.Gate)
            {
                run.Record.Status = run.UserCancelled ? "Cancelled" : "Interrupted";
                run.Record.Error = "The worker process tree was stopped. No rollback was performed; an external operation may continue on its target service.";
            }
        }
        catch (ApiException ex)
        {
            lock (run.Gate) { run.Record.Status = "Failed"; run.Record.Error = ex.Message; }
        }
        catch (Exception)
        {
            lock (run.Gate) { run.Record.Status = "Failed"; run.Record.Error = "The managed worker failed. No raw process streams are exposed; inspect runner installation and service diagnostics."; }
        }
        finally
        {
            try
            {
                eventsDone.Cancel();
                if (watcher != null)
                {
                    try { await watcher; }
                    catch (IOException) { run.Record.Status = "Failed"; run.Record.Error = "Run event persistence failed; inspect runner storage. No rollback was performed."; }
                    catch (UnauthorizedAccessException) { run.Record.Status = "Failed"; run.Record.Error = "Run event persistence failed; inspect runner storage permissions. No rollback was performed."; }
                }
                lock (run.Gate)
                {
                    run.Record.CompletedAt = DateTimeOffset.UtcNow;
                    if (run.Record.Status is "Cancelled" or "Interrupted" or "Failed" && run.Record.Steps is JsonArray steps)
                        foreach (var step in steps.OfType<JsonObject>().Where(x => x["status"]?.ToString() == "Running")) step["status"] = run.Record.Status;
                    Save(run.Record);
                }
                AppendEvent(run.Record, new JsonObject { ["type"] = "Completed", ["status"] = run.Record.Status });
            }
            finally
            {
                run.ProjectLock.Dispose();
                active.TryRemove(run.Record.Id, out _);
            }
        }
    }
    private async Task PumpEvents(ActiveRun run, string path, CancellationToken done)
    {
        var consumed = 0;
        do
        {
            if (File.Exists(path))
            {
                string content;
                using (var stream = new FileStream(path, FileMode.Open, FileAccess.Read, FileShare.ReadWrite | FileShare.Delete))
                using (var reader = new StreamReader(stream)) content = await reader.ReadToEndAsync();
                var lines = content.Split('\n');
                while (consumed < lines.Length - 1)
                {
                    var line = lines[consumed++];
                    if (string.IsNullOrWhiteSpace(line)) continue;
                    JsonObject? native;
                    try { native = JsonNode.Parse(line) as JsonObject; } catch (System.Text.Json.JsonException) { continue; }
                    if (native == null) continue;
                    var entry = new JsonObject();
                    foreach (var name in new[] { "Type", "Timestamp", "InvocationId", "Step", "Status", "DurationMs" })
                        if (native[name] != null) entry[char.ToLowerInvariant(name[0]) + name[1..]] = native[name]!.DeepClone();
                    AppendEvent(run.Record, entry);
                    if (native["InvocationId"] != null)
                    {
                        lock (run.Gate)
                        {
                            if (run.Record.Steps is not JsonArray) run.Record.Steps = new JsonArray();
                            var steps = run.Record.Steps.AsArray();
                            var id = native["InvocationId"]!.ToString();
                            var step = steps.OfType<JsonObject>().FirstOrDefault(x => x["id"]?.ToString() == id);
                            if (step == null) steps.Add(step = new JsonObject { ["id"] = id, ["step"] = native["Step"]?.DeepClone() });
                            step["status"] = native["Status"]?.DeepClone() ?? JsonValue.Create(native["Type"]?.ToString() == "StepStarted" ? "Running" : "Completed");
                            step["durationMs"] = native["DurationMs"]?.DeepClone();
                            Save(run.Record);
                        }
                    }
                }
            }
            if (done.IsCancellationRequested) break;
            try { await Task.Delay(100, done); } catch (OperationCanceledException) { }
        } while (true);
    }
    private void AppendEvent(RunRecord record, JsonObject entry)
    {
        lock (eventGate)
        {
            var path = Path.Combine(Folder(record.Id), "events.ndjson");
            var cursor = File.Exists(path) ? File.ReadLines(path).Count() + 1 : 1;
            entry["cursor"] = cursor;
            entry["timestamp"] ??= JsonValue.Create(DateTimeOffset.UtcNow.ToString("O"));
            File.AppendAllText(path, entry.ToJsonString() + "\n");
        }
    }
    public RunRecord Get(string owner, string projectId, string id)
    {
        _ = projects.Get(owner, projectId);
        var file = RecordPath(id);
        if (!File.Exists(file)) throw new ApiException(404, "Run not found.");
        var record = JsonStore.Read<RunRecord>(file);
        if (record.Owner != owner || record.ProjectId != projectId) throw new ApiException(403, "Run access denied.", "forbidden");
        // A durable terminal record is published before the lock is released.
        // Do not tell a polling client it can edit/start again until that release.
        if (active.ContainsKey(id) && record.Status is not ("Queued" or "Running"))
        {
            record.Status = "Running";
            record.CompletedAt = null;
        }
        return record;
    }
    public List<RunRecord> List(string owner, string projectId)
    {
        _ = projects.Get(owner, projectId);
        if (!Directory.Exists(Root)) return new();
        return Directory.EnumerateDirectories(Root).Select(path => Path.Combine(path, "run.json")).Where(File.Exists).Select(JsonStore.Read<RunRecord>).Where(x => x.Owner == owner && x.ProjectId == projectId).OrderByDescending(x => x.CreatedAt).ToList();
    }
    public object Events(string owner, string projectId, string id, long after)
    {
        var record = Get(owner, projectId, id);
        if (after < 0) throw new ApiException(400, "Event cursor cannot be negative.");
        lock (eventGate)
        {
            var path = Path.Combine(Folder(id), "events.ndjson");
            var events = File.Exists(path) ? File.ReadLines(path).Where(x => !string.IsNullOrWhiteSpace(x)).Select(x => JsonNode.Parse(x)!.AsObject()).ToList() : new();
            return new { events = events.Where(x => x["cursor"]!.GetValue<long>() > after).ToArray(), cursor = events.LastOrDefault()?["cursor"]?.GetValue<long>() ?? 0, record.Status };
        }
    }
    public RunRecord Cancel(string owner, string projectId, string id)
    {
        var record = Get(owner, projectId, id);
        if (active.TryGetValue(id, out var run))
        {
            lock (run.Gate) { run.UserCancelled = true; run.Cancellation.Cancel(); }
            AppendEvent(record, new JsonObject { ["type"] = "CancelRequested", ["status"] = record.Status });
        }
        return record;
    }
}
