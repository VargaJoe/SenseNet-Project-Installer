using System.Text.Json;
using System.Text.Json.Nodes;

namespace PlotManager.Server;

public static class JsonStore
{
    public static readonly JsonSerializerOptions Options = new(JsonSerializerDefaults.Web) { WriteIndented = true };
    public static T Read<T>(string path)
    {
        using var stream = new FileStream(path, FileMode.Open, FileAccess.Read, FileShare.ReadWrite | FileShare.Delete);
        return JsonSerializer.Deserialize<T>(stream, Options) ?? throw new ApiException(400, "Invalid JSON file.");
    }
    public static void Write<T>(string path, T value)
    {
        Directory.CreateDirectory(Path.GetDirectoryName(path)!);
        var temporary = path + "." + Guid.NewGuid().ToString("N") + ".tmp";
        File.WriteAllText(temporary, JsonSerializer.Serialize(value, Options));
        File.Move(temporary, path, true);
    }
    public static JsonObject Object(string path) => JsonNode.Parse(File.ReadAllText(path)) as JsonObject ?? throw new ApiException(400, "Configuration must be a JSON object.");
}

public sealed class ApiException(int status, string message, string code = "invalid_request") : Exception(message)
{
    public int Status { get; } = status;
    public string Code { get; } = code;
}

public sealed class ProjectRecord
{
    public string Id { get; set; } = Guid.NewGuid().ToString("N");
    public string Owner { get; set; } = "";
    public string Directory { get; set; } = "";
}

public sealed record CreateProject(string Name, string? Directory, string? Template);
public sealed record OpenProject(string Directory);
public sealed record SaveLayer(string Etag, JsonObject Data);
public sealed record AddEnvironment(string Name);
public sealed record UploadFile(string Name, string ContentBase64);
public sealed record LoginRequest(string Token);
public sealed record SecretRequest(string Value);
public sealed record WizardRequest(string Etag, JsonObject Values);
public sealed record ExecutionRequest(string Plot, string? Environment, JsonObject? Overrides, string? InvocationId, bool WhatIf = false);
public sealed class RunRecord
{
    public string Id { get; set; } = Guid.NewGuid().ToString("N");
    public string ProjectId { get; set; } = "";
    public string Owner { get; set; } = "";
    public string Plot { get; set; } = "";
    public string? Environment { get; set; }
    public string? InvocationId { get; set; }
    public bool WhatIf { get; set; }
    public string Status { get; set; } = "Queued";
    public DateTimeOffset CreatedAt { get; set; } = DateTimeOffset.UtcNow;
    public DateTimeOffset? StartedAt { get; set; }
    public DateTimeOffset? CompletedAt { get; set; }
    public JsonNode? Steps { get; set; }
    public JsonNode? Engine { get; set; }
    public string? Error { get; set; }
    public Dictionary<string, string> Snapshot { get; set; } = new();
}

public sealed record Layer(string Id, string Label, string Path);
public sealed record LayerDocument(string Id, string Path, string Etag, JsonObject Data);
