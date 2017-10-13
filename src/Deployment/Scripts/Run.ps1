[CmdletBinding(SupportsShouldProcess=$True)]
Param(
[Parameter(Mandatory=$false)]
[string]$Mode,
[Parameter(Mandatory=$false)] 
[string]$Settings = "local",
[Parameter(Mandatory=$false)] 
[string]$Params,
[Parameter(Mandatory=$false)] 
[string]$ExportFilter
)

$ErrorActionPreference = "Stop"

# ================================================
# ================ MAIN SCRIPT ===================
# ================================================

. ".\Global-Variables.ps1"
. ".\Init-Functions.ps1"
. ".\Default-Modules.ps1"


if (Is-Administrator) {
	$DefaultSettingsPath = Set-SettingsPath -SettingName "default"
	Write-Host default setting path: $DefaultSettingsPath
	$DefaultSettings = Load-Settings -SettingsPath $DefaultSettingsPath

	$ProjectSettingsPath = Set-SettingsPath $Settings
	Write-Host project setting path: $ProjectSettingsPath 
	$ProjectSettings = Load-Settings -SettingsPath $ProjectSettingsPath

	Run-Modules "$Mode"
} else {
	Write-Host You have to run this script in administrator mode!
}
