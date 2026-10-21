#Requires -Version 7.0
[CmdletBinding()]
param(
    [ValidateSet('win-x64','linux-x64')][string]$Runtime = $(if ($IsWindows) { 'win-x64' } else { 'linux-x64' }),
    [switch]$Desktop,
    [switch]$WindowsCross,
    [switch]$SkipWebInstall
)
$ErrorActionPreference = 'Stop'
$repo = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '../..'))
$web = Join-Path $repo 'src/Management/Web'
$desktopRoot = Join-Path $repo 'src/Desktop'
$output = Join-Path $repo "artifacts/management/$Runtime"

function Invoke-Checked([string]$Command, [string[]]$Arguments) {
    & $Command @Arguments
    if ($LASTEXITCODE -ne 0) { throw "$Command failed with exit code $LASTEXITCODE." }
}
function Reset-GeneratedDirectory([string]$Path) {
    $resolved = [IO.Path]::GetFullPath($Path)
    $allowed = @([IO.Path]::GetFullPath($output), [IO.Path]::GetFullPath((Join-Path $desktopRoot 'src-tauri/resources')))
    if ($resolved -notin $allowed -or -not $resolved.StartsWith($repo + [IO.Path]::DirectorySeparatorChar, [StringComparison]::OrdinalIgnoreCase)) { throw 'Refusing cleanup outside generated management output.' }
    $cursor = $resolved
    while ($cursor -and $cursor -ne $repo) {
        if ((Test-Path -LiteralPath $cursor) -and ((Get-Item -LiteralPath $cursor -Force).Attributes -band [IO.FileAttributes]::ReparsePoint)) { throw "Generated output may not traverse a link: $cursor" }
        $cursor = Split-Path -Parent $cursor
    }
    if (Test-Path -LiteralPath $resolved) { Remove-Item -LiteralPath $resolved -Recurse -Force }
    New-Item -ItemType Directory -Path $resolved -Force | Out-Null
}
foreach ($command in @('dotnet','node','npm','pwsh')) {
    if (-not (Get-Command $command -ErrorAction SilentlyContinue)) { throw "Required tool is missing: $command" }
}
if ($WindowsCross -and (-not $Desktop -or -not $IsLinux -or $Runtime -ne 'win-x64')) {
    throw '-WindowsCross is supported only on Linux with -Desktop -Runtime win-x64.'
}
if ($Desktop -and -not $WindowsCross -and (($IsWindows -and $Runtime -ne 'win-x64') -or ($IsLinux -and $Runtime -ne 'linux-x64'))) {
    throw 'Desktop installers must be built on the matching target OS; this script does not cross-compile Tauri.'
}
if ($WindowsCross) {
    foreach ($command in @('cargo-xwin','clang','lld-link','llvm-rc','makensis')) {
        if (-not (Get-Command $command -ErrorAction SilentlyContinue)) { throw "Windows cross-build tool is missing: $command" }
    }
}
if ($Desktop -and -not (Get-Command cargo -ErrorAction SilentlyContinue)) {
    throw 'Desktop builds require Rust, its native compiler/linker and target WebView development dependencies. See docs/management-deployment.md.'
}
Reset-GeneratedDirectory $output
Push-Location $web
try {
    if (-not $SkipWebInstall) { Invoke-Checked npm @('ci') }
    Invoke-Checked npm @('run','build')
} finally { Pop-Location }

Invoke-Checked dotnet @('publish',(Join-Path $repo 'src/Management/Server/PlotManager.Server.csproj'),
    '--configuration','Release','--runtime',$Runtime,'--self-contained','true',
    '-p:ContinuousIntegrationBuild=true','--output',(Join-Path $output 'service'))
$engine = Join-Path $output 'engine'
New-Item -ItemType Directory -Path $engine -Force | Out-Null
foreach ($directory in @('Auto','Core')) {
    Copy-Item -LiteralPath (Join-Path $repo "src/Deployment/Scripts/$directory") -Destination $engine -Recurse -Force
}
foreach ($file in @('Invoke-ManagedRequest.ps1','Invoke-Request.ps1','Run.ps1')) {
    Copy-Item -LiteralPath (Join-Path $repo "src/Deployment/Scripts/$file") -Destination $engine -Force
}
if ($IsLinux -and $Runtime -eq 'linux-x64') { Invoke-Checked chmod @('+x',(Join-Path $output 'service/PlotManager.Server')) }
Copy-Item -LiteralPath (Join-Path $repo 'LICENSE') -Destination $output -Force

if ($Desktop) {
    $resources = Join-Path $desktopRoot 'src-tauri/resources'
    Reset-GeneratedDirectory $resources
    Copy-Item -LiteralPath (Join-Path $output 'service') -Destination $resources -Recurse -Force
    Copy-Item -LiteralPath $engine -Destination $resources -Recurse -Force
    Push-Location $desktopRoot
    try {
        Invoke-Checked npm @('ci')
        if ($WindowsCross) {
            Invoke-Checked npm @('run','build','--','--runner','cargo-xwin','--target','x86_64-pc-windows-msvc','--bundles','nsis','--','--locked')
        } else {
            $bundle = if ($IsWindows) { 'nsis' } else { 'deb' }
            Invoke-Checked npm @('run','build','--','--bundles',$bundle,'--','--locked')
        }
    } finally { Pop-Location }
}
Write-Host "Published shared UI, self-contained service and engine to $output"
if ($Desktop) {
    $bundlePath = if ($WindowsCross) { 'src-tauri/target/x86_64-pc-windows-msvc/release/bundle' } else { 'src-tauri/target/release/bundle' }
    Write-Host "Desktop installer: $(Join-Path $desktopRoot $bundlePath)"
}
