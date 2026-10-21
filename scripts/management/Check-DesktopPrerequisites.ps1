#Requires -Version 7.0
[CmdletBinding()]
param([switch]$Build)
$ErrorActionPreference = 'Stop'
$missing = [Collections.Generic.List[string]]::new()
if (-not (Get-Command pwsh -ErrorAction SilentlyContinue)) { $missing.Add('PowerShell 7 (pwsh on PATH)') }
if ($Build) {
    foreach ($tool in @('dotnet','node','npm','cargo','rustc')) {
        if (-not (Get-Command $tool -ErrorAction SilentlyContinue)) { $missing.Add($tool) }
    }
    if ($IsWindows) {
        $vswhere = Join-Path ${env:ProgramFiles(x86)} 'Microsoft Visual Studio/Installer/vswhere.exe'
        $compiler = if (Test-Path -LiteralPath $vswhere) { & $vswhere -latest -products '*' -requires Microsoft.VisualStudio.Component.VC.Tools.x86.x64 -property installationPath }
        if (-not $compiler) { $missing.Add('Visual Studio C++ build tools with Windows SDK') }
    } elseif ($IsLinux) {
        & pkg-config --exists webkit2gtk-4.1 gtk+-3.0
        if ($LASTEXITCODE) { $missing.Add('WebKitGTK 4.1 and GTK 3 development packages') }
    }
} elseif ($IsWindows) {
    $clientKey = 'HKLM:\SOFTWARE\WOW6432Node\Microsoft\EdgeUpdate\Clients\{F3017226-FE2A-4295-8BDF-00C72FB1D55E}'
    if (-not (Test-Path $clientKey)) {
        Write-Warning 'WebView2 was not found in the system registration. The NSIS installer offers the Microsoft WebView2 bootstrapper; offline machines must install WebView2 separately.'
    }
} elseif ($IsLinux) {
    Write-Host 'The .deb declares GTK/WebKitGTK/ICU/OpenSSL dependencies. A graphical session is required for desktop use.'
}
if ($missing.Count) { throw "Missing prerequisites: $($missing -join '; '). See docs/management-deployment.md." }
Write-Host "Plot Manager $(if ($Build) { 'build' } else { 'runtime' }) prerequisites passed on $([Runtime.InteropServices.RuntimeInformation]::OSDescription)."
