namespace PlotManager.Server;

/// <summary>Prevents two services from replaying or mutating one runner state.</summary>
public sealed class StateLease(ServiceSettings settings) : IHostedService, IDisposable
{
    private FileStream? lease;
    public Task StartAsync(CancellationToken cancellationToken)
    {
        var path = SafePaths.Within(settings.DataDirectory, "service.lock");
        try { lease = new FileStream(path, FileMode.OpenOrCreate, FileAccess.ReadWrite, FileShare.None); }
        catch (IOException) { throw new InvalidOperationException("Another Plot Manager service is using PLOTMANAGER_DATA. Close that service or select a different data directory."); }
        return Task.CompletedTask;
    }
    public Task StopAsync(CancellationToken cancellationToken) { Dispose(); return Task.CompletedTask; }
    public void Dispose() { lease?.Dispose(); lease = null; }
}
