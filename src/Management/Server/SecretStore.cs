using System.Text.Json.Nodes;
using System.Text.RegularExpressions;
using Microsoft.AspNetCore.DataProtection;

namespace PlotManager.Server;

public sealed class SecretStore(ServiceSettings settings, IDataProtectionProvider provider)
{
    private readonly IDataProtector protector = provider.CreateProtector("PlotManager.RunnerSecrets.v1");
    private readonly object gate = new();
    private string FilePath => Path.Combine(settings.DataDirectory, "secrets.json");
    private Dictionary<string, string> Read() => File.Exists(FilePath) ? JsonStore.Read<Dictionary<string, string>>(FilePath) : new();
    private static string Key(string name)
    {
        if (!Regex.IsMatch(name ?? "", "^[A-Za-z][A-Za-z0-9_]{0,63}$")) throw new ApiException(400, "Secret names must be letters, digits and underscores, beginning with a letter.");
        return name!.ToUpperInvariant();
    }
    private static object View(string name) => new { name, reference = new Dictionary<string, string> { ["$env"] = "PLOTMANAGER_SECRET_" + name } };
    public Dictionary<string, string> EnvironmentFor(string owner)
    {
        // Values are namespaced by authenticated owner and never shared across operators.
        lock (gate) return Read().Where(x => x.Key.StartsWith(owner + ":", StringComparison.Ordinal)).ToDictionary(x => "PLOTMANAGER_SECRET_" + x.Key[(owner.Length + 1)..], x => protector.Unprotect(x.Value));
    }
    public object List(string owner)
    {
        lock (gate) return new { secrets = Read().Keys.Where(x => x.StartsWith(owner + ":", StringComparison.Ordinal)).Select(x => View(x[(owner.Length + 1)..])).ToArray() };
    }
    public object Save(string owner, string name, string value)
    {
        var key = Key(name);
        if (string.IsNullOrEmpty(value) || value.Length > 65536) throw new ApiException(400, "Secret must contain 1-65536 characters.");
        lock (gate)
        {
            var secrets = Read();
            secrets[owner + ":" + key] = protector.Protect(value);
            JsonStore.Write(FilePath, secrets);
            ServiceSettings.PrivateFile(FilePath);
            return View(key);
        }
    }
    public void Delete(string owner, string name) { lock (gate) { var values = Read(); values.Remove(owner + ":" + Key(name)); JsonStore.Write(FilePath, values); } }
    public static HashSet<string> ReferencedEnvironment(JsonNode? value)
    {
        var names = new HashSet<string>(StringComparer.Ordinal);
        void Walk(JsonNode? node)
        {
            if (node is JsonObject obj)
            {
                if (obj["$env"] is JsonValue v && v.TryGetValue<string>(out var name)) names.Add(name);
                foreach (var pair in obj) Walk(pair.Value);
            }
            else if (node is JsonArray array) foreach (var item in array) Walk(item);
        }
        Walk(value);
        return names;
    }
    public static JsonNode? Redact(JsonNode? value, IEnumerable<string> secretValues)
    {
        var tokens = secretValues.Where(x => !string.IsNullOrEmpty(x)).Distinct().OrderByDescending(x => x.Length).ToArray();
        string Text(string text)
        {
            foreach (var token in tokens) text = text.Replace(token, "[REDACTED]", StringComparison.Ordinal);
            return text;
        }
        JsonNode? Walk(JsonNode? node)
        {
            if (node is JsonObject obj)
            {
                var result = new JsonObject();
                foreach (var item in obj)
                {
                    var key = Text(item.Key);
                    var unique = key;
                    var suffix = 1;
                    while (result.ContainsKey(unique)) unique = key + "#" + suffix++;
                    result[unique] = Walk(item.Value);
                }
                return result;
            }
            if (node is JsonArray array) return new JsonArray(array.Select(Walk).ToArray());
            if (node is JsonValue scalar && scalar.TryGetValue<string>(out var text))
            {
                return JsonValue.Create(Text(text));
            }
            if (node is JsonValue && tokens.Contains(node.ToJsonString(), StringComparer.Ordinal)) return JsonValue.Create("[REDACTED]");
            return node?.DeepClone();
        }
        return Walk(value);
    }
}
