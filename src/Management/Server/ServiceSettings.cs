using System.Net;
using System.Security.AccessControl;
using System.Security.Principal;
using System.Text.Json;

namespace PlotManager.Server;

public sealed class ServiceSettings
{
    public string Mode { get; init; } = "local";
    public string DataDirectory { get; init; } = "";
    public string ProjectRoot { get; init; } = "";
    public string EngineDirectory { get; init; } = "";
    public string PowerShell { get; init; } = "pwsh";
    public Dictionary<string, string> Users { get; init; } = new(StringComparer.Ordinal);

    public static ServiceSettings Load(IConfiguration config)
    {
        string Get(string key, string fallback) => config[key] ?? Environment.GetEnvironmentVariable(key) ?? fallback;
        var mode = Get("PLOTMANAGER_MODE", "local");
        if (mode is not ("local" or "hosted")) throw new InvalidOperationException("PLOTMANAGER_MODE must be local or hosted.");
        var data = Path.GetFullPath(Get("PLOTMANAGER_DATA", Path.Combine(Environment.GetFolderPath(Environment.SpecialFolder.LocalApplicationData), "PlotManager")));
        PrivateDirectory(data);
        var root = Path.GetFullPath(Get("PLOTMANAGER_PROJECT_ROOT", Path.Combine(data, "projects")));
        Directory.CreateDirectory(root);
        SafePaths.EnsureNoLinks(root);
        var defaultEngine = Path.Combine(AppContext.BaseDirectory, "engine");
        if (!Directory.Exists(defaultEngine)) defaultEngine = Path.GetFullPath(Path.Combine(AppContext.BaseDirectory, "../../../../../Deployment/Scripts"));
        var users = new Dictionary<string, string>(StringComparer.Ordinal);
        if (mode == "hosted")
        {
            var configured = Get("PLOTMANAGER_USERS", "");
            if (string.IsNullOrWhiteSpace(configured)) throw new InvalidOperationException("Hosted mode requires PLOTMANAGER_USERS JSON with distinct operator names and strong tokens.");
            foreach (var pair in JsonSerializer.Deserialize<Dictionary<string, string>>(configured) ?? new())
            {
                if (!System.Text.RegularExpressions.Regex.IsMatch(pair.Key, "^[A-Za-z0-9_-]{1,64}$") || string.IsNullOrEmpty(pair.Value) || pair.Value.Length < 32) throw new InvalidOperationException("Operator IDs must contain 1-64 letters, digits, underscores or hyphens; tokens must have at least 32 characters.");
                users.Add(pair.Key, pair.Value);
            }
            if (users.Count == 0 || users.Values.Distinct().Count() != users.Count) throw new InvalidOperationException("Hosted operator tokens must be nonempty and unique.");
        }
        else
        {
            var token = Get("PLOTMANAGER_TOKEN", "");
            var tokenFile = Path.Combine(data, "bootstrap-token");
            if (string.IsNullOrWhiteSpace(token))
            {
                token = File.Exists(tokenFile) ? File.ReadAllText(tokenFile).Trim() : Convert.ToHexString(System.Security.Cryptography.RandomNumberGenerator.GetBytes(32));
                File.WriteAllText(tokenFile, token);
                PrivateFile(tokenFile);
            }
            if (token.Length < 24) throw new InvalidOperationException("The local bootstrap token must have at least 24 characters.");
            users["local"] = token;
        }
        return new ServiceSettings { Mode = mode, DataDirectory = data, ProjectRoot = root, EngineDirectory = Path.GetFullPath(Get("PLOTMANAGER_ENGINE", defaultEngine)), PowerShell = Get("PLOTMANAGER_PWSH", "pwsh"), Users = users };
    }

    public static void PrivateDirectory(string path)
    {
        Directory.CreateDirectory(path);
        SafePaths.EnsureNoLinks(path);
        if (OperatingSystem.IsWindows())
        {
            var security = new DirectorySecurity();
            security.SetAccessRuleProtection(true, false);
            var identity = WindowsIdentity.GetCurrent().User ?? throw new InvalidOperationException("Cannot determine service identity.");
            var directory = new DirectoryInfo(path);
            // An existing owner can secure its DACL without WRITE_OWNER. Desktop
            // creates the directory first, so reassigning an identical owner can
            // fail on an otherwise valid Modify-only inherited ACL.
            if (!identity.Equals(directory.GetAccessControl(AccessControlSections.Owner).GetOwner(typeof(SecurityIdentifier))))
                security.SetOwner(identity);
            security.AddAccessRule(new FileSystemAccessRule(identity, FileSystemRights.FullControl, InheritanceFlags.ContainerInherit | InheritanceFlags.ObjectInherit, PropagationFlags.None, AccessControlType.Allow));
            directory.SetAccessControl(security);
        }
        else File.SetUnixFileMode(path, UnixFileMode.UserRead | UnixFileMode.UserWrite | UnixFileMode.UserExecute);
    }
    public static void PrivateFile(string path)
    {
        if (!OperatingSystem.IsWindows()) File.SetUnixFileMode(path, UnixFileMode.UserRead | UnixFileMode.UserWrite);
    }

    public void ValidateUrls(string? urls)
    {
        var addresses = (urls ?? "http://127.0.0.1:5188").Split(';', StringSplitOptions.RemoveEmptyEntries);
        foreach (var address in addresses)
        {
            if (!Uri.TryCreate(address, UriKind.Absolute, out var uri)) throw new InvalidOperationException("Use explicit service HTTP(S) URLs.");
            if (Mode == "local" && !(uri.Host.Equals("localhost", StringComparison.OrdinalIgnoreCase) || IPAddress.TryParse(uri.Host, out var ip) && IPAddress.IsLoopback(ip))) throw new InvalidOperationException("Local mode must bind only loopback. Use hosted HTTPS mode for remote access.");
            if (Mode == "hosted" && uri.Scheme != "https") throw new InvalidOperationException("Hosted mode requires HTTPS binding and a configured ASP.NET Core certificate.");
        }
    }
}

public static class SafePaths
{
    public static string Within(string root, string path)
    {
        var fullRoot = Path.TrimEndingDirectorySeparator(Path.GetFullPath(root));
        var full = Path.TrimEndingDirectorySeparator(Path.GetFullPath(Path.IsPathRooted(path) ? path : Path.Combine(fullRoot, path)));
        var comparison = OperatingSystem.IsWindows() ? StringComparison.OrdinalIgnoreCase : StringComparison.Ordinal;
        if (!full.Equals(fullRoot, comparison) && !full.StartsWith(fullRoot + Path.DirectorySeparatorChar, comparison)) throw new ApiException(400, "Path is outside the allowed project directory.", "path_outside_root");
        EnsureNoLinks(full);
        return full;
    }
    public static void EnsureNoLinks(string path)
    {
        var cursor = Path.GetFullPath(path);
        while (!string.IsNullOrEmpty(cursor))
        {
            if ((File.Exists(cursor) || Directory.Exists(cursor)) && (File.GetAttributes(cursor) & FileAttributes.ReparsePoint) != 0) throw new ApiException(400, "Symbolic link and reparse paths are not supported.", "path_link");
            cursor = Path.GetDirectoryName(cursor);
        }
    }
    public static string RelativeFile(string root, string path)
    {
        if (string.IsNullOrWhiteSpace(path) || Path.IsPathRooted(path)) throw new ApiException(400, "Project file paths must be relative.");
        var full = Within(root, path);
        if (full == Path.GetFullPath(root)) throw new ApiException(400, "Expected a file path.");
        return full;
    }
}
