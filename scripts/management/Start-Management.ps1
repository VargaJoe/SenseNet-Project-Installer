#Requires -Version 7.0
[CmdletBinding()]
param(
    [string]$PublishDirectory,
    [string]$DataDirectory,
    [string]$ProjectRoot,
    [ValidateRange(0,65535)][int]$Port = 0,
    [switch]$NoBrowser
)
$ErrorActionPreference = 'Stop'
$repo = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '../..'))
$runtime = if ($IsWindows) { 'win-x64' } else { 'linux-x64' }
if (-not $PublishDirectory) { $PublishDirectory = Join-Path $repo "artifacts/management/$runtime" }
$PublishDirectory = [IO.Path]::GetFullPath($PublishDirectory)
if (-not $DataDirectory) {
    $base = [Environment]::GetFolderPath('LocalApplicationData')
    if (-not $base) { $base = Join-Path ([Environment]::GetFolderPath('UserProfile')) '.local/share' }
    $DataDirectory = Join-Path $base 'PlotManager/browser'
}
$DataDirectory = [IO.Path]::GetFullPath($DataDirectory)
if (-not $ProjectRoot) { $ProjectRoot = Join-Path $DataDirectory 'projects' }
$ProjectRoot = [IO.Path]::GetFullPath($ProjectRoot)
$server = Join-Path $PublishDirectory $(if ($IsWindows) { 'service/PlotManager.Server.exe' } else { 'service/PlotManager.Server' })
if (-not (Test-Path -LiteralPath $server -PathType Leaf)) { throw 'Published service missing. Run scripts/management/Build-Management.ps1 first.' }
if (-not (Get-Command pwsh -ErrorAction SilentlyContinue)) { throw 'PowerShell 7 must be installed and available as pwsh.' }
New-Item -ItemType Directory -Path $DataDirectory -Force | Out-Null
if (-not $IsWindows) { & chmod 700 $DataDirectory; if ($LASTEXITCODE) { throw 'Cannot restrict data directory permissions.' } }

$token = $env:PLOTMANAGER_TOKEN
if (-not $token) { $token = [Convert]::ToHexString([Security.Cryptography.RandomNumberGenerator]::GetBytes(32)).ToLowerInvariant() }
if ($NoBrowser -and -not $env:PLOTMANAGER_TOKEN) { throw '-NoBrowser requires a caller-supplied PLOTMANAGER_TOKEN so the login credential is known without printing or saving it.' }
$socket = [Net.Sockets.TcpListener]::new([Net.IPAddress]::Loopback, $Port)
$socket.Start()
$Port = $socket.LocalEndpoint.Port
$origin = "http://127.0.0.1:$Port"
$start = [Diagnostics.ProcessStartInfo]::new($server)
$start.WorkingDirectory = Split-Path -Parent $server
$start.UseShellExecute = $false
$start.CreateNoWindow = $true
$start.Environment['ASPNETCORE_URLS'] = $origin
$start.Environment['PLOTMANAGER_MODE'] = 'local'
$start.Environment['PLOTMANAGER_TOKEN'] = $token
$start.Environment['PLOTMANAGER_DATA'] = $DataDirectory
$start.Environment['PLOTMANAGER_PROJECT_ROOT'] = $ProjectRoot
$start.Environment['PLOTMANAGER_ENGINE'] = Join-Path $PublishDirectory 'engine'
$start.Environment['PLOTMANAGER_PARENT_PID'] = [string]$PID
$service = $null
try {
    $socket.Stop()
    $service = [Diagnostics.Process]::Start($start)
    $ready = $false
    $headers = @{ Authorization = "Bearer $token"; 'X-Plot-Request' = '1' }
    $deadline = [DateTime]::UtcNow.AddSeconds(30)
    while ([DateTime]::UtcNow -lt $deadline -and -not $service.HasExited) {
        try { $null = Invoke-RestMethod "$origin/api/runner" -Headers $headers -TimeoutSec 1; $ready = $true; break }
        catch { Start-Sleep -Milliseconds 150 }
    }
    if (-not $ready) { throw 'Local service did not become ready. Check the console output and prerequisites.' }
    Write-Host "Plot Manager: $origin — execution target: this service host, identity $([Environment]::UserName)."
    Write-Host 'Keep this terminal running. Closing the browser leaves runs active; stopping this service stops its workers, without rollback.'
    if (-not $NoBrowser) {
        $url = "$origin/#token=$token"
        if ($IsWindows) { Start-Process $url }
        elseif ($IsLinux) { & xdg-open $url | Out-Null }
        else { & open $url | Out-Null }
    }
    while (-not $service.WaitForExit(500)) { }
    if ($service.ExitCode) { throw "Plot Manager service exited with code $($service.ExitCode)." }
} finally {
    $socket.Stop()
    if ($service -and -not $service.HasExited) {
        try { $null = Invoke-RestMethod "$origin/api/lifecycle/shutdown" -Method Post -Headers $headers -TimeoutSec 2 } catch { }
        if (-not $service.WaitForExit(5000)) { $service.Kill($true); $service.WaitForExit() }
    }
    if ($service) { $service.Dispose() }
}
