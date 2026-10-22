#Requires -Version 7.0
[CmdletBinding()]
param(
    [Parameter(Mandatory)][string]$Installer,
    [string]$ExpectedPayloadRoot,
    [string]$ResultPath
)
$ErrorActionPreference = 'Stop'
if (-not $IsWindows) { throw 'This helper is for the unsigned Windows NSIS package on a disposable Windows test machine.' }
$Installer = (Resolve-Path -LiteralPath $Installer).Path
$repo = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '../..'))
if (-not $ResultPath) { $ResultPath = Join-Path $repo 'artifacts/management/desktop-smoke-windows.json' }
$ResultPath = [IO.Path]::GetFullPath($ResultPath)
if ($ExpectedPayloadRoot) { $ExpectedPayloadRoot = (Resolve-Path -LiteralPath $ExpectedPayloadRoot).Path }
# NSIS uses a stable application identity and standard shortcut names even when
# /D points at our temporary folder. Refuse to replace an existing installation.
$identityPattern = '(?i)(?:plot[ _-]*manager|io\.github\.vargajoe\.plotmanager)'
function Get-PlotManagerIntegration {
    foreach ($registryRoot in @(
        'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall',
        'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall',
        'HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall'
    )) {
        if (-not (Test-Path -LiteralPath $registryRoot)) { continue }
        foreach ($registration in Get-ChildItem -LiteralPath $registryRoot -ErrorAction Stop) {
            $properties = Get-ItemProperty -LiteralPath $registration.PSPath -ErrorAction Stop
            $displayProperty = $properties.PSObject.Properties['DisplayName']
            $displayName = if ($displayProperty) { [string]$displayProperty.Value } else { '' }
            if ($registration.PSChildName -match $identityPattern -or $displayName -match $identityPattern) {
                $registration.Name
            }
        }
    }
    foreach ($folder in @('Programs', 'CommonPrograms', 'DesktopDirectory', 'CommonDesktopDirectory')) {
        $location = [Environment]::GetFolderPath($folder)
        if (-not $location -or -not (Test-Path -LiteralPath $location)) { continue }
        $existing = Get-ChildItem -LiteralPath $location -Force -ErrorAction Stop | Where-Object Name -Match $identityPattern | Select-Object -First 1
        if ($existing) { $existing.FullName }
    }
}
$existingIntegration = @(Get-PlotManagerIntegration)
if ($existingIntegration.Count) { throw "Existing Plot Manager integration prevents isolated installer smoke: $($existingIntegration -join '; '). Use a clean test VM or verify the extracted executable separately." }
$testRoot = Join-Path ([IO.Path]::GetTempPath()) ('plot-manager-install-' + [guid]::NewGuid().ToString('N'))
$installed = Join-Path $testRoot 'application'
New-Item -ItemType Directory -Path $testRoot | Out-Null
try {
    # /D must be last for NSIS and consumes the remaining directory path.
    $process = Start-Process -FilePath $Installer -ArgumentList @('/S', "/D=$installed") -WindowStyle Hidden -Wait -PassThru
    if ($process.ExitCode) { throw "Development installer exited with code $($process.ExitCode)." }
    $executables = @(Get-ChildItem -LiteralPath $installed -Filter '*.exe' -File | Where-Object Name -NotMatch '(?i)uninstall')
    if ($executables.Count -ne 1) { throw 'Installed main executable could not be identified.' }
    $manifest = [Collections.Generic.List[string]]::new()
    if ($ExpectedPayloadRoot) {
        foreach ($directory in @('service', 'engine')) {
            $expectedDirectory = Join-Path $ExpectedPayloadRoot $directory
            if (-not (Test-Path -LiteralPath $expectedDirectory -PathType Container)) { throw "Expected payload directory is missing: $directory" }
            foreach ($file in Get-ChildItem -LiteralPath $expectedDirectory -Recurse -File | Sort-Object FullName) {
                $relative = [IO.Path]::GetRelativePath($ExpectedPayloadRoot, $file.FullName)
                $actualFile = Join-Path $installed $relative
                if (-not (Test-Path -LiteralPath $actualFile -PathType Leaf)) { throw "Installer omitted payload file: $relative" }
                $expectedHash = (Get-FileHash -LiteralPath $file.FullName -Algorithm SHA256).Hash
                if ((Get-FileHash -LiteralPath $actualFile -Algorithm SHA256).Hash -ne $expectedHash) { throw "Installed payload differs from the published source: $relative" }
                $manifest.Add($relative.Replace('\', '/') + ' ' + $expectedHash.ToLowerInvariant())
            }
        }
    }
    & (Join-Path $PSScriptRoot 'Test-DesktopSmoke.ps1') -Executable $executables[0].FullName -ResultPath $ResultPath
    $evidence = Get-Content -LiteralPath $ResultPath -Raw | ConvertFrom-Json -AsHashtable
    $evidence['installerSha256'] = (Get-FileHash -LiteralPath $Installer -Algorithm SHA256).Hash.ToLowerInvariant()
    if ($ExpectedPayloadRoot) {
        $evidence['payloadFileCount'] = $manifest.Count
        $manifestText = [Text.Encoding]::UTF8.GetBytes(($manifest -join "`n"))
        $sha = [Security.Cryptography.SHA256]::Create()
        try { $evidence['payloadManifestSha256'] = [BitConverter]::ToString($sha.ComputeHash($manifestText)).Replace('-', '').ToLowerInvariant() }
        finally { $sha.Dispose() }
    }
} finally {
    $cleanupFailures = [Collections.Generic.List[string]]::new()
    if (Test-Path -LiteralPath $installed) {
        $uninstaller = Get-ChildItem -LiteralPath $installed -Filter '*.exe' -File | Where-Object Name -Match '(?i)uninstall' | Select-Object -First 1
        if ($uninstaller) {
            # _?= prevents NSIS copying itself to another asynchronous process.
            $process = Start-Process -FilePath $uninstaller.FullName -ArgumentList @('/S', "_?=$installed") -WindowStyle Hidden -Wait -PassThru
            if ($process.ExitCode) { $cleanupFailures.Add("Test uninstaller exited with code $($process.ExitCode).") }
        } else {
            $cleanupFailures.Add('Installed application has no identifiable uninstaller.')
        }
    }
    $resolved = [IO.Path]::GetFullPath($testRoot)
    $temp = [IO.Path]::GetFullPath([IO.Path]::GetTempPath()).TrimEnd([IO.Path]::DirectorySeparatorChar) + [IO.Path]::DirectorySeparatorChar
    if (-not $resolved.StartsWith($temp, [StringComparison]::OrdinalIgnoreCase) -or (Split-Path -Leaf $resolved) -notmatch '^plot-manager-install-[a-f0-9]{32}$') { throw 'Refusing cleanup outside the owned installer test directory.' }
    if (Test-Path -LiteralPath $resolved) { Remove-Item -LiteralPath $resolved -Recurse -Force }
    $remainingIntegration = @(Get-PlotManagerIntegration)
    if ($remainingIntegration.Count) { $cleanupFailures.Add("Installer left registration or shortcuts: $($remainingIntegration -join '; ').") }
    if ($cleanupFailures.Count) { throw "Installer cleanup failed: $($cleanupFailures -join ' ')" }
}
$evidence['installationRemoved'] = $true
$evidence | ConvertTo-Json -Depth 10 | Set-Content -LiteralPath $ResultPath -Encoding utf8
