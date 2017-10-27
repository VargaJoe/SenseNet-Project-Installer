[CmdletBinding(SupportsShouldProcess=$True)]
Param(
[Parameter(Mandatory=$false)]
[string]$Mode,
[Parameter(Mandatory=$false)] 
[string]$Settings = "local",
[Parameter(Mandatory=$false)] 
[string]$Params,
[Parameter(Mandatory=$false)] 
[string]$Exportfilter
)

$ErrorActionPreference = "Stop"

# ================================================
# ================ MAIN SCRIPT ===================
# ================================================

$scriptpath = split-path -parent $MyInvocation.MyCommand.Definition

. "$scriptpath\Global-Variables.ps1"
. "$scriptpath\Init-Functions.ps1"
. "$scriptpath\Default-Modules.ps1"
. "$scriptpath\RorWeb-Modules.ps1"

$DefaultSettingsPath = Set-SettingsPath -SettingName "default"
Write-Host default setting path: $DefaultSettingsPath
$DefaultSettings = Load-Settings -SettingsPath $DefaultSettingsPath

$ProjectSettingsPath = Set-SettingsPath $Settings
Write-Host project setting path: $ProjectSettingsPath 
$ProjectSettings = Load-Settings -SettingsPath $ProjectSettingsPath

Run-Modules "$Mode"