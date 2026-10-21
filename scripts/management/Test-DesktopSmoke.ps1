#Requires -Version 7.0
[CmdletBinding()]
param(
    [Parameter(Mandatory)][string]$Executable,
    [string]$ResultPath
)
$ErrorActionPreference = 'Stop'
$Executable = (Resolve-Path -LiteralPath $Executable).Path
if (-not (Test-Path -LiteralPath $Executable -PathType Leaf)) { throw 'Desktop executable missing.' }
$repo = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '../..'))
if (-not $ResultPath) { $ResultPath = Join-Path $repo "artifacts/management/desktop-smoke-$(if ($IsWindows) {'windows'} else {'linux'}).json" }
$ResultPath = [IO.Path]::GetFullPath($ResultPath)
New-Item -ItemType Directory -Path (Split-Path -Parent $ResultPath) -Force | Out-Null
$testRoot = Join-Path ([IO.Path]::GetTempPath()) ('plot-manager-desktop-' + [guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Path $testRoot | Out-Null
$smokeOutput = Join-Path $testRoot 'result.json'
$start = [Diagnostics.ProcessStartInfo]::new($Executable)
$start.ArgumentList.Add('--smoke-test')
$start.WorkingDirectory = Split-Path -Parent $Executable
$start.UseShellExecute = $false
$start.CreateNoWindow = $true
$start.Environment['PLOTMANAGER_DESKTOP_SMOKE_OUTPUT'] = $smokeOutput
$start.Environment['PLOTMANAGER_DESKTOP_SMOKE_DATA'] = Join-Path $testRoot 'data'
$desktop = $null
try {
    $desktop = [Diagnostics.Process]::Start($start)
    if (-not $desktop.WaitForExit(90000)) { $desktop.Kill($true); $desktop.WaitForExit(); throw 'Native desktop smoke exceeded 90 seconds.' }
    if ($desktop.ExitCode -ne 0) { throw "Native desktop smoke exited with code $($desktop.ExitCode)." }
    if (-not (Test-Path -LiteralPath $smokeOutput)) { throw 'Native desktop did not write its smoke result.' }
    $result = Get-Content -LiteralPath $smokeOutput -Raw | ConvertFrom-Json
    if (-not $result.webviewReady -or -not $result.serviceStopped -or $result.protocolVersion -ne 1) { throw 'Native WebView, authenticated session or owned-service shutdown failed.' }
    $evidence = [ordered]@{ os=[Runtime.InteropServices.RuntimeInformation]::OSDescription; architecture=[Runtime.InteropServices.RuntimeInformation]::OSArchitecture.ToString(); executableSha256=(Get-FileHash -LiteralPath $Executable -Algorithm SHA256).Hash.ToLowerInvariant(); checkedAt=[DateTime]::UtcNow.ToString('o'); result=$result }
    $evidence | ConvertTo-Json -Depth 10 | Set-Content -LiteralPath $ResultPath -Encoding utf8
    Write-Host "Native desktop WebView, authenticated UI and service shutdown passed: $ResultPath"
} finally {
    if ($desktop -and -not $desktop.HasExited) { $desktop.Kill($true); $desktop.WaitForExit() }
    if ($desktop) { $desktop.Dispose() }
    $resolved = [IO.Path]::GetFullPath($testRoot)
    $temp = [IO.Path]::GetFullPath([IO.Path]::GetTempPath()).TrimEnd([IO.Path]::DirectorySeparatorChar) + [IO.Path]::DirectorySeparatorChar
    if (-not $resolved.StartsWith($temp, [StringComparison]::OrdinalIgnoreCase) -or (Split-Path -Leaf $resolved) -notmatch '^plot-manager-desktop-[a-f0-9]{32}$') { throw 'Refusing cleanup outside the owned test directory.' }
    Remove-Item -LiteralPath $resolved -Recurse -Force
}
