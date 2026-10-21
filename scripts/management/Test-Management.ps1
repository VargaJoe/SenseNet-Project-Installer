#Requires -Version 7.0
[CmdletBinding()]
param([switch]$SkipBuild, [switch]$SkipBrowser)
$ErrorActionPreference = 'Stop'
$repo = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '../..'))
$web = Join-Path $repo 'src/Management/Web'
function Invoke-Checked([string]$Command, [string[]]$Arguments) {
    & $Command @Arguments
    if ($LASTEXITCODE) { throw "$Command failed with exit code $LASTEXITCODE." }
}
Push-Location $repo
try {
    if (-not $SkipBuild) {
        Push-Location $web
        try { Invoke-Checked npm @('ci'); Invoke-Checked npm @('run','build'); Invoke-Checked npm @('test') }
        finally { Pop-Location }
        Invoke-Checked dotnet @('build','src/Management/Server/PlotManager.Server.csproj','-c','Release')
    }
    Invoke-Checked dotnet @('run','--project','tests/Management.Server.Tests/Management.Server.Tests.csproj','--configuration','Release')
    if ($SkipBrowser) { return }
    $testRoot = Join-Path ([IO.Path]::GetTempPath()) ('plot-manager-browser-' + [guid]::NewGuid().ToString('N'))
    $null = New-Item -ItemType Directory -Path $testRoot
    $socket = [Net.Sockets.TcpListener]::new([Net.IPAddress]::Loopback, 0)
    $socket.Start()
    $origin = "http://127.0.0.1:$($socket.LocalEndpoint.Port)"
    $token = [Convert]::ToHexString([Security.Cryptography.RandomNumberGenerator]::GetBytes(32)).ToLowerInvariant()
    $start = [Diagnostics.ProcessStartInfo]::new((Get-Command dotnet).Source)
    $start.ArgumentList.Add((Join-Path $repo 'src/Management/Server/bin/Release/net8.0/PlotManager.Server.dll'))
    $start.WorkingDirectory = Join-Path $repo 'src/Management/Server'
    $start.UseShellExecute = $false
    $start.CreateNoWindow = $true
    $start.Environment['ASPNETCORE_URLS'] = $origin
    $start.Environment['PLOTMANAGER_MODE'] = 'local'
    $start.Environment['PLOTMANAGER_TOKEN'] = $token
    $start.Environment['PLOTMANAGER_DATA'] = Join-Path $testRoot 'data'
    $start.Environment['PLOTMANAGER_PROJECT_ROOT'] = Join-Path $testRoot 'projects'
    $start.Environment['PLOTMANAGER_ENGINE'] = Join-Path $repo 'src/Deployment/Scripts'
    $start.Environment['PLOTMANAGER_PARENT_PID'] = [string]$PID
    $service = $null
    $previous = @{}
    foreach ($key in @('PLOTMANAGER_E2E_URL','PLOTMANAGER_E2E_TOKEN','PLOTMANAGER_E2E_PROJECT_ROOT')) {
        $previous[$key] = [Environment]::GetEnvironmentVariable($key, 'Process')
    }
    try {
        $socket.Stop()
        $service = [Diagnostics.Process]::Start($start)
        $headers = @{ Authorization = "Bearer $token"; 'X-Plot-Request' = '1' }
        $deadline = [DateTime]::UtcNow.AddSeconds(30)
        $ready = $false
        while ([DateTime]::UtcNow -lt $deadline -and -not $service.HasExited) {
            try { $null = Invoke-RestMethod "$origin/api/runner" -Headers $headers -TimeoutSec 1; $ready = $true; break }
            catch { Start-Sleep -Milliseconds 150 }
        }
        if (-not $ready) { throw 'Browser E2E backend did not become ready.' }
        $env:PLOTMANAGER_E2E_URL = $origin
        $env:PLOTMANAGER_E2E_TOKEN = $token
        $env:PLOTMANAGER_E2E_PROJECT_ROOT = Join-Path $testRoot 'projects'
        Push-Location $web
        try { Invoke-Checked npm @('run','test:e2e') } finally { Pop-Location }
    } finally {
        foreach ($key in $previous.Keys) { [Environment]::SetEnvironmentVariable($key, $previous[$key], 'Process') }
        $socket.Stop()
        if ($service -and -not $service.HasExited) {
            try { $null = Invoke-RestMethod "$origin/api/lifecycle/shutdown" -Method Post -Headers $headers -TimeoutSec 2 } catch { }
            if (-not $service.WaitForExit(5000)) { $service.Kill($true); $service.WaitForExit() }
        }
        if ($service) { $service.Dispose() }
        $resolved = [IO.Path]::GetFullPath($testRoot)
        $temp = [IO.Path]::GetFullPath([IO.Path]::GetTempPath()).TrimEnd([IO.Path]::DirectorySeparatorChar) + [IO.Path]::DirectorySeparatorChar
        if (-not $resolved.StartsWith($temp, [StringComparison]::OrdinalIgnoreCase) -or (Split-Path -Leaf $resolved) -notmatch '^plot-manager-browser-[a-f0-9]{32}$') { throw 'Refusing cleanup outside the owned test directory.' }
        Remove-Item -LiteralPath $resolved -Recurse -Force
    }
} finally { Pop-Location }
