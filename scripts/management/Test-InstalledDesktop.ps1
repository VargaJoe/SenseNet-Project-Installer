#Requires -Version 7.0
[CmdletBinding()]
param([Parameter(Mandatory)][string]$Installer)
$ErrorActionPreference = 'Stop'
if (-not $IsWindows) { throw 'This helper is for the unsigned Windows NSIS package on a disposable Windows test machine.' }
$Installer = (Resolve-Path -LiteralPath $Installer).Path
# NSIS uses a stable application identity and standard shortcut names even when
# /D points at our temporary folder. Refuse to replace an existing installation.
$identityPattern = '(?i)(?:plot[ _-]*manager|io\.github\.vargajoe\.plotmanager)'
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
            throw "Existing Plot Manager registration prevents isolated installer smoke: $($registration.Name). Use a clean test VM or verify the extracted executable separately."
        }
    }
}
foreach ($folder in @('Programs', 'CommonPrograms', 'DesktopDirectory', 'CommonDesktopDirectory')) {
    $location = [Environment]::GetFolderPath($folder)
    if (-not $location -or -not (Test-Path -LiteralPath $location)) { continue }
    $existing = Get-ChildItem -LiteralPath $location -Force -ErrorAction Stop | Where-Object Name -Match $identityPattern | Select-Object -First 1
    if ($existing) { throw "Existing Plot Manager shortcut or menu directory prevents installer smoke: $($existing.FullName). Use a clean test VM or verify the extracted executable separately." }
}
$testRoot = Join-Path ([IO.Path]::GetTempPath()) ('plot-manager-install-' + [guid]::NewGuid().ToString('N'))
$installed = Join-Path $testRoot 'application'
New-Item -ItemType Directory -Path $testRoot | Out-Null
try {
    # /D must be last for NSIS and consumes the remaining directory path.
    $process = Start-Process -FilePath $Installer -ArgumentList @('/S', "/D=$installed") -WindowStyle Hidden -Wait -PassThru
    if ($process.ExitCode) { throw "Development installer exited with code $($process.ExitCode)." }
    $executables = @(Get-ChildItem -LiteralPath $installed -Filter '*.exe' -File | Where-Object Name -NotMatch '(?i)uninstall')
    if ($executables.Count -ne 1) { throw 'Installed main executable could not be identified.' }
    & (Join-Path $PSScriptRoot 'Test-DesktopSmoke.ps1') -Executable $executables[0].FullName
} finally {
    if (Test-Path -LiteralPath $installed) {
        $uninstaller = Get-ChildItem -LiteralPath $installed -Filter '*.exe' -File | Where-Object Name -Match '(?i)uninstall' | Select-Object -First 1
        if ($uninstaller) {
            # _?= prevents NSIS copying itself to another asynchronous process.
            $process = Start-Process -FilePath $uninstaller.FullName -ArgumentList @('/S', "_?=$installed") -WindowStyle Hidden -Wait -PassThru
            if ($process.ExitCode) { Write-Warning "Test uninstaller exited with code $($process.ExitCode)." }
        }
    }
    $resolved = [IO.Path]::GetFullPath($testRoot)
    $temp = [IO.Path]::GetFullPath([IO.Path]::GetTempPath()).TrimEnd([IO.Path]::DirectorySeparatorChar) + [IO.Path]::DirectorySeparatorChar
    if (-not $resolved.StartsWith($temp, [StringComparison]::OrdinalIgnoreCase) -or (Split-Path -Leaf $resolved) -notmatch '^plot-manager-install-[a-f0-9]{32}$') { throw 'Refusing cleanup outside the owned installer test directory.' }
    if (Test-Path -LiteralPath $resolved) { Remove-Item -LiteralPath $resolved -Recurse -Force }
}
