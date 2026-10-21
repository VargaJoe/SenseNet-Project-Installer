using System.Diagnostics;
using System.Security.Claims;
using System.Security.Cryptography;
using System.Text;
using System.Text.Json.Nodes;
using Microsoft.AspNetCore.Authentication;
using Microsoft.AspNetCore.Authentication.Cookies;
using Microsoft.AspNetCore.DataProtection;
using Microsoft.AspNetCore.Http.Features;
using PlotManager.Server;

public static class Program
{
    public static async Task Main(string[] args) => await Build(args).RunAsync();

    public static WebApplication Build(string[] args, IDictionary<string, string?>? overrides = null)
    {
        var builder = WebApplication.CreateBuilder(new WebApplicationOptions { Args = args, ContentRootPath = AppContext.BaseDirectory });
        if (overrides != null) builder.Configuration.AddInMemoryCollection(overrides);
        var settings = ServiceSettings.Load(builder.Configuration);
        var urls = builder.Configuration["urls"] ?? Environment.GetEnvironmentVariable("ASPNETCORE_URLS") ?? "http://127.0.0.1:5188";
        settings.ValidateUrls(urls);
        // Explicit Kestrel endpoints override UseUrls. Validate those too so
        // environment configuration cannot accidentally expose local mode.
        foreach (var endpoint in builder.Configuration.GetSection("Kestrel:Endpoints").GetChildren())
            settings.ValidateUrls(endpoint["Url"] ?? throw new InvalidOperationException("Every explicit Kestrel endpoint requires a URL."));
        builder.WebHost.UseUrls(urls);
        builder.Services.AddSingleton(settings);
        builder.Services.AddSingleton<ProjectStore>();
        builder.Services.AddSingleton<SecretStore>();
        builder.Services.AddSingleton<EngineClient>();
        builder.Services.AddSingleton<RunManager>();
        builder.Services.AddSingleton<StateLease>();
        builder.Services.AddHostedService(sp => sp.GetRequiredService<StateLease>());
        builder.Services.AddHostedService(sp => sp.GetRequiredService<RunManager>());
        var protection = builder.Services.AddDataProtection().PersistKeysToFileSystem(new DirectoryInfo(Path.Combine(settings.DataDirectory, "keys"))).SetApplicationName("PlotManager.Management.v1");
        if (OperatingSystem.IsWindows()) protection.ProtectKeysWithDpapi();
        builder.Services.AddAuthentication(CookieAuthenticationDefaults.AuthenticationScheme).AddCookie(options =>
        {
            options.Cookie.Name = "PlotManager.Session";
            options.Cookie.HttpOnly = true;
            options.Cookie.SameSite = SameSiteMode.Strict;
            options.Cookie.SecurePolicy = settings.Mode == "hosted" ? CookieSecurePolicy.Always : CookieSecurePolicy.SameAsRequest;
            options.ExpireTimeSpan = TimeSpan.FromHours(8);
            options.SlidingExpiration = false;
            options.Events.OnValidatePrincipal = context =>
            {
                if (context.Principal?.Identity?.Name is not { } user || !settings.Users.TryGetValue(user, out var token) || context.Principal.FindFirst("plot:token-stamp")?.Value != TokenStamp(token)) context.RejectPrincipal();
                return Task.CompletedTask;
            };
        });
        builder.Services.Configure<FormOptions>(options => options.MultipartBodyLengthLimit = 15 * 1024 * 1024);
        builder.WebHost.ConfigureKestrel(options => options.Limits.MaxRequestBodySize = 15 * 1024 * 1024);
        var app = builder.Build();
        app.Use(async (context, next) =>
        {
            try
            {
                context.Response.Headers["X-Content-Type-Options"] = "nosniff";
                context.Response.Headers["Referrer-Policy"] = "no-referrer";
                context.Response.Headers["Content-Security-Policy"] = "default-src 'self'; script-src 'self'; style-src 'self' 'unsafe-inline'; img-src 'self' data:; connect-src 'self'; frame-ancestors 'none'; base-uri 'self'; form-action 'self'";
                if (settings.Mode == "local" && !IsLoopbackHost(context.Request.Host.Host)) throw new ApiException(400, "Local mode only accepts loopback host names.");
                if (settings.Mode == "hosted" && !context.Request.IsHttps) throw new ApiException(400, "HTTPS is required in hosted mode.");
                if (context.Request.Path.StartsWithSegments("/api"))
                {
                    context.Response.Headers.CacheControl = "no-store";
                    if (context.Request.Method is not ("GET" or "HEAD" or "OPTIONS"))
                    {
                        if (context.Request.Headers["X-Plot-Request"] != "1") throw new ApiException(403, "Missing same-origin request marker.", "csrf");
                        if (context.Request.Headers.TryGetValue("Origin", out var origin) && origin != $"{context.Request.Scheme}://{context.Request.Host}") throw new ApiException(403, "Cross-origin requests are not allowed.", "csrf");
                        if (context.Request.Headers["Sec-Fetch-Site"] == "cross-site") throw new ApiException(403, "Cross-site requests are not allowed.", "csrf");
                    }
                }
                await next();
            }
            catch (ApiException ex) { context.Response.StatusCode = ex.Status; await context.Response.WriteAsJsonAsync(new { error = ex.Message, code = ex.Code }); }
            catch (Exception ex) when (ex is IOException or UnauthorizedAccessException or System.Text.Json.JsonException or InvalidOperationException or ArgumentException)
            {
                context.Response.StatusCode = 400;
                await context.Response.WriteAsJsonAsync(new { error = "The request could not be completed. Check the project format, file permissions and runner prerequisites.", code = "request_failed" });
            }
        });
        app.UseAuthentication();
        app.Use(async (context, next) =>
        {
            if (context.Request.Headers.Authorization.ToString() is { } authorization && authorization.StartsWith("Bearer ", StringComparison.Ordinal))
            {
                var user = Authenticate(settings, authorization[7..]);
                if (user != null) context.User = Principal(user, settings.Users[user]);
                else { context.Response.StatusCode = 401; await context.Response.WriteAsJsonAsync(new { error = "Authentication required.", code = "unauthorized" }); return; }
            }
            if (context.Request.Path.StartsWithSegments("/api") && context.Request.Path != "/api/health" && context.Request.Path != "/api/session" && context.User.Identity?.IsAuthenticated != true)
            {
                context.Response.StatusCode = 401;
                await context.Response.WriteAsJsonAsync(new { error = "Authentication required.", code = "unauthorized" });
                return;
            }
            await next();
        });
        static string Owner(HttpContext context) => context.User.Identity?.Name ?? throw new ApiException(401, "Authentication required.");
        app.MapGet("/api/health", () => new { status = "ok", protocolVersion = 1 });
        app.MapGet("/api/session", (HttpContext context) => new { authenticated = context.User.Identity?.IsAuthenticated == true, user = context.User.Identity?.Name, mode = settings.Mode });
        app.MapPost("/api/session", async (HttpContext context, LoginRequest request) =>
        {
            var user = Authenticate(settings, request.Token) ?? throw new ApiException(401, "Invalid operator token.", "unauthorized");
            await context.SignInAsync(CookieAuthenticationDefaults.AuthenticationScheme, Principal(user, settings.Users[user]));
            return Results.Json(new { authenticated = true, user, mode = settings.Mode });
        });
        app.MapDelete("/api/session", async (HttpContext context) => { await context.SignOutAsync(); return Results.NoContent(); });
        app.MapGet("/api/runner", () => new { id = Environment.MachineName, displayName = Environment.MachineName, os = System.Runtime.InteropServices.RuntimeInformation.OSDescription, identity = Environment.UserDomainName + "\\" + Environment.UserName, protocolVersion = 1, powerShell = settings.PowerShell, mode = settings.Mode, executionTarget = "service-host" });
        app.MapGet("/api/browse", (HttpContext context, string? path, ProjectStore projects) => projects.Browse(Owner(context), path));
        app.MapGet("/api/projects", (HttpContext context, ProjectStore projects, RunManager runs) => new { projects = projects.List(Owner(context)).Select(x => projects.View(x, runs.ActiveId(x.Id))).ToArray() });
        app.MapPost("/api/projects", (HttpContext context, CreateProject request, ProjectStore projects) => Results.Json(projects.View(projects.Create(Owner(context), request)), statusCode: 201));
        app.MapPost("/api/projects/open", (HttpContext context, OpenProject request, ProjectStore projects) => projects.View(projects.Open(Owner(context), request)));
        app.MapGet("/api/projects/{id}", (HttpContext context, string id, ProjectStore projects, RunManager runs) => projects.View(projects.Get(Owner(context), id), runs.ActiveId(id)));
        app.MapGet("/api/projects/{id}/definition", (HttpContext context, string id, ProjectStore projects) => projects.ReadDefinition(projects.Get(Owner(context), id)));
        app.MapPut("/api/projects/{id}/definition", (HttpContext context, string id, SaveLayer request, ProjectStore projects) => projects.SaveDefinition(projects.Get(Owner(context), id), request));
        app.MapGet("/api/projects/{id}/layers", (HttpContext context, string id, string? environment, ProjectStore projects) => new { layers = projects.Layers(projects.Get(Owner(context), id), environment), environment });
        app.MapGet("/api/projects/{id}/layers/{layerId}", (HttpContext context, string id, string layerId, ProjectStore projects) => projects.ReadLayer(projects.Get(Owner(context), id), layerId));
        app.MapPut("/api/projects/{id}/layers/{layerId}", (HttpContext context, string id, string layerId, SaveLayer request, ProjectStore projects) => projects.Save(projects.Get(Owner(context), id), layerId, request));
        app.MapPost("/api/projects/{id}/environments", (HttpContext context, string id, AddEnvironment request, ProjectStore projects) => { var project = projects.Get(Owner(context), id); projects.AddEnvironment(project, request.Name); return projects.View(project); });
        app.MapPost("/api/projects/{id}/uploads", (HttpContext context, string id, UploadFile request, ProjectStore projects) => projects.Upload(projects.Get(Owner(context), id), request));
        async Task<JsonNode> Inspect(string owner, JsonObject request, EngineClient engine)
        {
            var scratchRoot = Path.Combine(settings.DataDirectory, "requests");
            var scratch = SafePaths.Within(scratchRoot, Guid.NewGuid().ToString("N"));
            Directory.CreateDirectory(scratch);
            using var timeout = new CancellationTokenSource(TimeSpan.FromMinutes(2));
            try { return await engine.InvokeAsync(owner, request, settings.EngineDirectory, scratch, null, null, timeout.Token); }
            finally { if (Directory.Exists(scratch)) Directory.Delete(scratch, true); }
        }
        app.MapGet("/api/catalog", async (HttpContext context, EngineClient engine) => new { engine = await Inspect(Owner(context), new JsonObject { ["Operation"] = "catalog" }, engine) });
        app.MapGet("/api/projects/{id}/configuration", async (HttpContext context, string id, string? environment, ProjectStore projects, EngineClient engine) =>
        {
            var project = projects.Get(Owner(context), id);
            var files = projects.Layers(project, environment).Select(x => SafePaths.RelativeFile(project.Directory, x.Path)).ToArray();
            return new { engine = await Inspect(Owner(context), engine.Request("inspect", project, files), engine) };
        });
        app.MapPost("/api/projects/{id}/plan", async (HttpContext context, string id, ExecutionRequest request, ProjectStore projects, EngineClient engine) =>
        {
            var project = projects.Get(Owner(context), id);
            var files = projects.Layers(project, request.Environment).Select(x => SafePaths.RelativeFile(project.Directory, x.Path)).ToArray();
            return new { engine = await Inspect(Owner(context), engine.Request("plan", project, files, request), engine) };
        });
        app.MapPost("/api/projects/{id}/runs", async (HttpContext context, string id, ExecutionRequest request, ProjectStore projects, RunManager runs) => Results.Json(await runs.Start(Owner(context), projects.Get(Owner(context), id), request), statusCode: 202));
        app.MapGet("/api/projects/{id}/runs", (HttpContext context, string id, RunManager runs) => new { runs = runs.List(Owner(context), id) });
        app.MapGet("/api/projects/{id}/runs/{runId}", (HttpContext context, string id, string runId, RunManager runs) => runs.Get(Owner(context), id, runId));
        app.MapGet("/api/projects/{id}/runs/{runId}/events", (HttpContext context, string id, string runId, long? after, RunManager runs) => runs.Events(Owner(context), id, runId, after ?? 0));
        app.MapPost("/api/projects/{id}/runs/{runId}/cancel", (HttpContext context, string id, string runId, RunManager runs) => runs.Cancel(Owner(context), id, runId));
        app.MapGet("/api/projects/{id}/wizard", (HttpContext context, string id, ProjectStore projects) => projects.Wizard(projects.Get(Owner(context), id)));
        app.MapPost("/api/projects/{id}/wizard", (HttpContext context, string id, WizardRequest request, ProjectStore projects) => projects.SaveWizard(projects.Get(Owner(context), id), request));
        app.MapGet("/api/secrets", (HttpContext context, SecretStore secrets) => secrets.List(Owner(context)));
        app.MapPut("/api/secrets/{name}", (HttpContext context, string name, SecretRequest request, SecretStore secrets) => secrets.Save(Owner(context), name, request.Value));
        app.MapDelete("/api/secrets/{name}", (HttpContext context, string name, SecretStore secrets) => { secrets.Delete(Owner(context), name); return Results.NoContent(); });
        if (settings.Mode == "local" && int.TryParse(builder.Configuration["PLOTMANAGER_PARENT_PID"], out var parentPid) && parentPid > 0)
        {
            app.MapPost("/api/lifecycle/shutdown", (IHostApplicationLifetime lifetime) => { lifetime.StopApplication(); return Results.Accepted(); });
            app.Lifetime.ApplicationStarted.Register(() => _ = WatchParent(parentPid, app.Lifetime));
        }
        app.UseDefaultFiles();
        app.UseStaticFiles();
        app.MapFallback((HttpContext context) =>
        {
            if (context.Request.Path.StartsWithSegments("/api")) return Results.NotFound(new { error = "API route not found.", code = "not_found" });
            var index = Path.Combine(app.Environment.WebRootPath ?? Path.Combine(AppContext.BaseDirectory, "wwwroot"), "index.html");
            return File.Exists(index) ? Results.File(index, "text/html") : Results.Content("Plot Manager API is ready. Build src/Management/Web and publish the service to serve the shared UI.", "text/plain");
        });
        return app;
    }
    private static bool IsLoopbackHost(string host) => host.Equals("localhost", StringComparison.OrdinalIgnoreCase) || System.Net.IPAddress.TryParse(host.Trim('[', ']'), out var ip) && System.Net.IPAddress.IsLoopback(ip);
    private static string TokenStamp(string token) => Convert.ToHexString(SHA256.HashData(Encoding.UTF8.GetBytes(token)));
    private static ClaimsPrincipal Principal(string user, string token) => new(new ClaimsIdentity(new[] { new Claim(ClaimTypes.Name, user), new Claim("plot:token-stamp", TokenStamp(token)) }, CookieAuthenticationDefaults.AuthenticationScheme));
    private static string? Authenticate(ServiceSettings settings, string? token)
    {
        if (string.IsNullOrEmpty(token)) return null;
        var supplied = SHA256.HashData(Encoding.UTF8.GetBytes(token));
        foreach (var user in settings.Users) if (CryptographicOperations.FixedTimeEquals(supplied, SHA256.HashData(Encoding.UTF8.GetBytes(user.Value)))) return user.Key;
        return null;
    }
    private static async Task WatchParent(int parentPid, IHostApplicationLifetime lifetime)
    {
        try
        {
            using var parent = Process.GetProcessById(parentPid);
            await parent.WaitForExitAsync(lifetime.ApplicationStopping);
            lifetime.StopApplication();
        }
        catch (ArgumentException) { lifetime.StopApplication(); }
        catch (OperationCanceledException) { }
    }
}
