using System.Collections.Concurrent;
using System.Security.Cryptography;
using System.Text.Json.Nodes;
using System.Text.RegularExpressions;

namespace PlotManager.Server;

public sealed class ProjectStore(ServiceSettings settings)
{
    private readonly ConcurrentDictionary<string, SemaphoreSlim> gates = new();
    private readonly object registryGate = new();
    private string Registry => Path.Combine(settings.DataDirectory, "projects.json");
    private List<ProjectRecord> Records => File.Exists(Registry) ? JsonStore.Read<List<ProjectRecord>>(Registry) : new();
    public IDisposable Lock(string id)
    {
        var gate = gates.GetOrAdd(id, _ => new SemaphoreSlim(1, 1));
        if (!gate.Wait(0)) throw new ApiException(409, "The project is running or being edited.", "project_busy");
        return new Release(gate);
    }
    private sealed class Release(SemaphoreSlim gate) : IDisposable { public void Dispose() => gate.Release(); }
    public bool Busy(string id) => gates.TryGetValue(id, out var gate) && gate.CurrentCount == 0;
    public List<ProjectRecord> List(string owner) { lock (registryGate) return Records.Where(p => p.Owner == owner).ToList(); }
    public ProjectRecord Get(string owner, string id)
    {
        lock (registryGate)
        {
            var record = Records.FirstOrDefault(p => p.Id == id) ?? throw new ApiException(404, "Project not found.");
            if (record.Owner != owner) throw new ApiException(403, "Project access denied.", "forbidden");
            SafePaths.Within(settings.ProjectRoot, record.Directory);
            return record;
        }
    }
    public object View(ProjectRecord project, string? activeRunId = null)
    {
        var definition = Definition(project);
        return new { project.Id, name = definition["name"]?.GetValue<string>() ?? Path.GetFileName(project.Directory), project.Directory, environments = Environments(definition).Select(x => x.Key).ToArray(), definition, activeRunId };
    }
    public ProjectRecord Create(string owner, CreateProject request)
    {
        // Reserve/check/create/register as one operation. Two operators must
        // never both observe the same empty directory and overwrite it.
        lock (registryGate) return CreateUnlocked(owner, request);
    }
    private ProjectRecord CreateUnlocked(string owner, CreateProject request)
    {
        if (string.IsNullOrWhiteSpace(request.Name) || request.Name.Length > 120) throw new ApiException(400, "Project name is required (maximum 120 characters).");
        if (request.Template is not (null or "generic")) throw new ApiException(400, "Unknown project template.");
        var name = Regex.Replace(request.Name.Trim(), @"[^\p{L}\p{N}_.-]", "-").Trim('.', '-');
        if (name.Length == 0) name = "project";
        var directory = SafePaths.Within(settings.ProjectRoot, request.Directory ?? name + "-" + Guid.NewGuid().ToString("N")[..8]);
        EnsureDirectoryAccess(owner, directory);
        if (Directory.Exists(directory) && Directory.EnumerateFileSystemEntries(directory).Any()) throw new ApiException(409, "Create requires a new or empty project directory. Use Open for an existing project.");
        Directory.CreateDirectory(directory);
        var definition = JsonNode.Parse("""
            {"formatVersion":1,"configuration":{"default":"default.json","project":"project.json","environments":{"development":"environments/development.json"}}}
            """)!.AsObject();
        definition["name"] = request.Name.Trim();
        if (request.Template == "generic") definition["wizard"] = JsonNode.Parse("""
            {"title":"Generic file installer","description":"Choose a file target on this runner, configure its content, preview, then run. Preview does not contact step services.","plot":"install","layer":"project","groups":[{"id":"target","title":"Choose target","fields":[{"key":"target","label":"Output file on runner","type":"string","default":"hello.txt","required":true,"settingPath":"Sample.Target"}]},{"id":"settings","title":"Configure content","fields":[{"key":"message","label":"File content","type":"string","default":"Hello from Plot Manager","required":true,"settingPath":"Sample.Message"}]}]}
            """);
        JsonStore.Write(Path.Combine(directory, "plot-project.json"), definition);
        JsonStore.Write(Path.Combine(directory, "default.json"), request.Template == "generic" ? JsonNode.Parse("""
            {"Sample":{"Target":"hello.txt","Message":"Hello from Plot Manager"},"Plots":{"install":{"Steps":[{"Id":"compose","Step":"text.join","With":{"Items":[{"$ref":"settings.Sample.Message"}],"Separator":""}},{"Id":"save","Step":"filesystem.write","With":{"Path":{"$ref":"settings.Sample.Target"},"Content":{"$ref":"steps.compose.Output.Text"},"Overwrite":true}}]}}}
            """)! : new JsonObject());
        JsonStore.Write(Path.Combine(directory, "project.json"), new JsonObject());
        JsonStore.Write(Path.Combine(directory, "environments/development.json"), new JsonObject());
        return Open(owner, new OpenProject(directory));
    }
    public ProjectRecord Open(string owner, OpenProject request)
    {
        var directory = SafePaths.Within(settings.ProjectRoot, request.Directory);
        EnsureDirectoryAccess(owner, directory);
        var project = new ProjectRecord { Owner = owner, Directory = directory };
        _ = Layers(project, null);
        lock (registryGate)
        {
            EnsureDirectoryAccess(owner, directory);
            var records = Records;
            var existing = records.FirstOrDefault(p => string.Equals(p.Directory, directory, OperatingSystem.IsWindows() ? StringComparison.OrdinalIgnoreCase : StringComparison.Ordinal));
            if (existing != null)
            {
                if (existing.Owner != owner) throw new ApiException(403, "This project is already owned by another operator.", "forbidden");
                return existing;
            }
            records.Add(project);
            JsonStore.Write(Registry, records);
            return project;
        }
    }
    public JsonObject Definition(ProjectRecord project)
    {
        var path = SafePaths.RelativeFile(project.Directory, "plot-project.json");
        if (!File.Exists(path)) throw new ApiException(400, "No plot-project.json found in the selected runner directory.");
        var definition = JsonStore.Object(path);
        if (definition["formatVersion"]?.GetValue<int>() != 1) throw new ApiException(400, "Unsupported project formatVersion. Expected 1.");
        return definition;
    }
    public object ReadDefinition(ProjectRecord project)
    {
        var file = SafePaths.RelativeFile(project.Directory, "plot-project.json");
        return new { etag = Hash(file), data = Definition(project) };
    }
    public object SaveDefinition(ProjectRecord project, SaveLayer request)
    {
        if (request.Data == null || string.IsNullOrWhiteSpace(request.Etag)) throw new ApiException(400, "Saving requires a JSON object and its current etag.");
        using var gate = Lock(project.Id);
        var file = SafePaths.RelativeFile(project.Directory, "plot-project.json");
        if (Hash(file) != request.Etag) throw new ApiException(409, "The project definition changed. Reload before saving.", "etag_conflict");
        var data = request.Data;
        if (data["formatVersion"]?.GetValue<int>() != 1 || data["name"] is not JsonValue name || !name.TryGetValue<string>(out var text) || string.IsNullOrWhiteSpace(text)) throw new ApiException(400, "A project definition requires formatVersion 1 and a name.");
        _ = Layers(project, null, data);
        foreach (var environment in Environments(data)) _ = Layers(project, environment.Key, data);
        if (data["wizard"] != null) ValidateWizard(data["wizard"]);
        JsonStore.Write(file, data);
        return ReadDefinition(project);
    }
    private static JsonObject Environments(JsonObject definition) => definition["configuration"]?["environments"] as JsonObject ?? new JsonObject();
    public List<Layer> Layers(ProjectRecord project, string? environment) => Layers(project, environment, Definition(project));
    private List<Layer> Layers(ProjectRecord project, string? environment, JsonObject definition)
    {
        var configuration = definition["configuration"] as JsonObject ?? throw new ApiException(400, "Project requires a configuration object.");
        var layers = new List<Layer>();
        foreach (var id in new[] { "default", "project" })
        {
            if (configuration[id] is JsonValue value && value.TryGetValue<string>(out var relative))
            {
                _ = SafePaths.RelativeFile(project.Directory, relative);
                layers.Add(new Layer(id, id == "default" ? "Default" : "Project", relative));
            }
        }
        if (!layers.Any(x => x.Id == "project")) throw new ApiException(400, "Project configuration layer is required.");
        foreach (var item in Environments(definition))
        {
            if (!Regex.IsMatch(item.Key, "^[A-Za-z0-9_-]{1,64}$") || item.Value is not JsonValue value || !value.TryGetValue<string>(out var relative)) throw new ApiException(400, "Invalid environment definition.");
            _ = SafePaths.RelativeFile(project.Directory, relative);
            if (environment == item.Key) layers.Add(new Layer("environment:" + item.Key, item.Key, relative));
        }
        if (!string.IsNullOrWhiteSpace(environment) && !Environments(definition).ContainsKey(environment)) throw new ApiException(400, "Unknown environment.");
        foreach (var layer in layers)
        {
            var path = SafePaths.RelativeFile(project.Directory, layer.Path);
            if (!File.Exists(path)) throw new ApiException(400, "A configured layer file does not exist.");
            ValidateReferences(JsonStore.Object(path));
        }
        return layers;
    }
    private Layer SelectLayer(ProjectRecord project, string id)
    {
        var environment = id.StartsWith("environment:", StringComparison.Ordinal) ? id[12..] : null;
        return Layers(project, environment).FirstOrDefault(x => x.Id == id) ?? throw new ApiException(404, "Layer not found.");
    }
    public LayerDocument ReadLayer(ProjectRecord project, string id)
    {
        var layer = SelectLayer(project, id);
        var file = SafePaths.RelativeFile(project.Directory, layer.Path);
        return new LayerDocument(layer.Id, layer.Path, Hash(file), JsonStore.Object(file));
    }
    public LayerDocument Save(ProjectRecord project, string id, SaveLayer request)
    {
        using var gate = Lock(project.Id);
        return SaveUnlocked(project, id, request);
    }
    private LayerDocument SaveUnlocked(ProjectRecord project, string id, SaveLayer request)
    {
        if (request.Data == null || string.IsNullOrWhiteSpace(request.Etag)) throw new ApiException(400, "Saving requires a JSON object and its current etag.");
        var current = ReadLayer(project, id);
        if (current.Etag != request.Etag) throw new ApiException(409, "The selected layer changed. Reload before saving.", "etag_conflict");
        ValidateReferences(request.Data);
        JsonStore.Write(SafePaths.RelativeFile(project.Directory, current.Path), request.Data);
        return ReadLayer(project, id);
    }
    public void AddEnvironment(ProjectRecord project, string name)
    {
        if (!Regex.IsMatch(name ?? "", "^[A-Za-z0-9_-]{1,64}$")) throw new ApiException(400, "Environment name must contain 1-64 letters, digits, underscores or hyphens.");
        using var gate = Lock(project.Id);
        var definition = Definition(project);
        var configuration = definition["configuration"]!.AsObject();
        var environments = configuration["environments"] as JsonObject;
        if (environments == null) configuration["environments"] = environments = new JsonObject();
        if (environments.ContainsKey(name!)) throw new ApiException(409, "Environment already exists.");
        var relative = "environments/" + name + ".json";
        var file = SafePaths.RelativeFile(project.Directory, relative);
        if (File.Exists(file)) throw new ApiException(409, "Environment file already exists.");
        JsonStore.Write(file, new JsonObject());
        environments[name!] = relative;
        JsonStore.Write(Path.Combine(project.Directory, "plot-project.json"), definition);
    }
    public object Upload(ProjectRecord project, UploadFile request)
    {
        if (string.IsNullOrWhiteSpace(request.Name) || Path.GetFileName(request.Name) != request.Name || request.Name.IndexOfAny(Path.GetInvalidFileNameChars()) >= 0 || request.Name is "." or "..") throw new ApiException(400, "Upload requires a file name without directories.");
        byte[] bytes;
        try { bytes = Convert.FromBase64String(request.ContentBase64); } catch (FormatException) { throw new ApiException(400, "Invalid base64 upload."); }
        if (bytes.Length > 10 * 1024 * 1024) throw new ApiException(413, "Upload exceeds 10 MiB.");
        using var gate = Lock(project.Id);
        var relative = "uploads/" + Guid.NewGuid().ToString("N")[..8] + "-" + request.Name;
        var file = SafePaths.RelativeFile(project.Directory, relative);
        Directory.CreateDirectory(Path.GetDirectoryName(file)!);
        File.WriteAllBytes(file, bytes);
        return new { path = file, relativePath = relative };
    }
    public LayerDocument SaveWizard(ProjectRecord project, WizardRequest request)
    {
        if (request.Values == null) throw new ApiException(400, "Wizard values must be a JSON object.");
        using var gate = Lock(project.Id);
        var wizard = Wizard(project);
        var layerId = wizard["layer"]?.GetValue<string>() ?? "project";
        var layer = ReadLayer(project, layerId);
        var data = layer.Data;
        var fields = wizard["groups"]!.AsArray().SelectMany(x => x!["fields"]!.AsArray()).Select(x => x!.AsObject()).ToArray();
        if (request.Values.Any(x => !fields.Any(field => field["key"]!.ToString() == x.Key))) throw new ApiException(400, "Unknown wizard value.");
        foreach (var field in fields)
        {
            var key = field["key"]!.ToString();
            if (!request.Values.TryGetPropertyValue(key, out var value))
            {
                if (field["required"]?.GetValue<bool>() == true) throw new ApiException(400, "A required wizard value is missing.");
                continue;
            }
            var valid = field["type"]!.ToString() switch
            {
                "string" => value is JsonValue scalar && scalar.TryGetValue<string>(out var item) && (field["required"]?.GetValue<bool>() != true || !string.IsNullOrWhiteSpace(item)),
                "int" => value is JsonValue integer && integer.TryGetValue<int>(out _),
                "bool" => value is JsonValue boolean && boolean.TryGetValue<bool>(out _),
                "array" => value is JsonArray,
                "object" => value is JsonObject,
                _ => false
            };
            if (!valid) throw new ApiException(400, "A wizard value does not match its declared type.");
            var path = field["settingPath"]!.ToString().Split('.');
            var current = data;
            foreach (var part in path[..^1])
            {
                var existing = current.Select(x => x.Key).FirstOrDefault(x => x.Equals(part, StringComparison.OrdinalIgnoreCase)) ?? part;
                if (current[existing] is not JsonObject child) current[existing] = child = new JsonObject();
                current = child;
            }
            var leaf = current.Select(x => x.Key).FirstOrDefault(x => x.Equals(path[^1], StringComparison.OrdinalIgnoreCase)) ?? path[^1];
            current[leaf] = value!.DeepClone();
        }
        return SaveUnlocked(project, layerId, new SaveLayer(request.Etag, data));
    }
    private static void ValidateWizard(JsonNode? node)
    {
        if (node is not JsonObject wizard || wizard["plot"] is not JsonValue plot || !plot.TryGetValue<string>(out var plotName) || string.IsNullOrWhiteSpace(plotName) || wizard["groups"] is not JsonArray groups) throw new ApiException(400, "Wizard requires a plot and form groups.");
        var keys = new HashSet<string>();
        foreach (var group in groups)
        {
            if (group?["fields"] is not JsonArray fields) throw new ApiException(400, "Wizard groups require fields.");
            foreach (var field in fields)
                if (field is not JsonObject item || item["key"] is not JsonValue key || !key.TryGetValue<string>(out var name) || string.IsNullOrWhiteSpace(name) || !keys.Add(name) || item["type"]?.ToString() is not ("string" or "int" or "bool" or "array" or "object") || item["settingPath"] is not JsonValue path || !path.TryGetValue<string>(out var binding) || !Regex.IsMatch(binding, @"^[A-Za-z_][A-Za-z0-9_-]*(\.[A-Za-z_][A-Za-z0-9_-]*)*$")) throw new ApiException(400, "Wizard fields require unique keys, supported types and dotted settingPath bindings.");
        }
    }
    public JsonObject Wizard(ProjectRecord project)
    {
        var wizard = Definition(project)["wizard"];
        if (wizard == null) throw new ApiException(404, "This project has no declarative wizard.");
        ValidateWizard(wizard);
        return wizard.AsObject();
    }
    public object Browse(string owner, string? path)
    {
        var selected = SafePaths.Within(settings.ProjectRoot, path ?? settings.ProjectRoot);
        if (!Directory.Exists(selected)) throw new ApiException(404, "Runner directory not found.");
        List<ProjectRecord> others;
        lock (registryGate) others = Records.Where(x => x.Owner != owner).ToList();
        var comparison = OperatingSystem.IsWindows() ? StringComparison.OrdinalIgnoreCase : StringComparison.Ordinal;
        bool IsPrivate(string entry) => others.Any(x => entry.Equals(Path.TrimEndingDirectorySeparator(x.Directory), comparison) || entry.StartsWith(Path.TrimEndingDirectorySeparator(x.Directory) + Path.DirectorySeparatorChar, comparison));
        if (IsPrivate(selected)) throw new ApiException(403, "Runner directory access denied.", "forbidden");
        var entries = Directory.EnumerateFileSystemEntries(selected).Where(x => !IsPrivate(x) && (File.GetAttributes(x) & FileAttributes.ReparsePoint) == 0).Select(x => new { name = Path.GetFileName(x), path = x, isDirectory = Directory.Exists(x) }).OrderByDescending(x => x.isDirectory).ThenBy(x => x.name).Take(1000).ToArray();
        return new { path = selected, entries, allowedRoot = settings.ProjectRoot };
    }
    private void EnsureDirectoryAccess(string owner, string directory)
    {
        var comparison = OperatingSystem.IsWindows() ? StringComparison.OrdinalIgnoreCase : StringComparison.Ordinal;
        lock (registryGate)
            if (Records.Any(x => x.Owner != owner && (directory.Equals(x.Directory, comparison) || directory.StartsWith(Path.TrimEndingDirectorySeparator(x.Directory) + Path.DirectorySeparatorChar, comparison) || x.Directory.StartsWith(Path.TrimEndingDirectorySeparator(directory) + Path.DirectorySeparatorChar, comparison)))) throw new ApiException(403, "Project directories owned by different operators must not overlap.", "forbidden");
    }
    public static void ValidateReferences(JsonNode? node)
    {
        if (node is JsonObject obj)
        {
            foreach (var property in obj)
            {
                if (Regex.IsMatch(property.Key, "^(password|secret|token|api[-_]?key|private[-_]?key|connectionstring|certificatepassword)$", RegexOptions.IgnoreCase) && property.Value is JsonValue or JsonArray)
                {
                    if (property.Value is not JsonObject reference || reference.Count != 1 || !(reference.ContainsKey("$env") || reference.ContainsKey("$ref"))) throw new ApiException(400, "Secret parameters must use an environment or settings reference, never a literal value.", "secret_literal");
                }
                ValidateReferences(property.Value);
            }
        }
        else if (node is JsonArray array) foreach (var item in array) ValidateReferences(item);
    }
    public static string Hash(string file) => Convert.ToHexString(SHA256.HashData(File.ReadAllBytes(file))).ToLowerInvariant();
}
