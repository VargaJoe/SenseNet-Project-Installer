[CmdletBinding(SupportsShouldProcess=$True)]
Param(
[Parameter(Mandatory=$false)]
[string]$Plot,
[Parameter(Mandatory=$false)] 
[string]$Settings = "local",
[Parameter(Mandatory=$false)] 
[string]$Params,
[Parameter(Mandatory=$false)] 
[string]$Step,
[Parameter(Mandatory=$false)] 
[string]$ExportFilter,
[Parameter(Mandatory=$false)] 
[string]$ShowOutput = $True,
[Parameter(Mandatory=$false)] 
[string]$OutputMode = "Host",
[Parameter(Mandatory=$false)] 
[string]$Help
)

$ErrorActionPreference = "Stop"
$Result = 0

# ================================================
# ============== GLOBAL VARIABLES ================
# ================================================

$Global:ScriptBaseFolderPath = Split-Path -Parent $MyInvocation.MyCommand.Path
$Global:ProjectSettingsPath = $null
$Global:DefaultSettingsPath = $null
$Global:ProjectSettings = $null
$Global:DefaultSettings = $null
$Global:OutputMode = $OutputMode
$Global:ShowOutput = $ShowOutput

$Global:GlobalSettings = $null
$Global:JsonResult=$Null

$AutoLoadExtensions = [IO.Path]::GetFullPath([IO.Path]::Combine($ScriptBaseFolderPath, "AutoExt"))

# ================================================
# ================ MAIN SCRIPT ===================
# ================================================

# Load steps and functions for plot manager
$AutoLoadExtensionFiles = Get-ChildItem "$AutoLoadExtensions\*.ps1"
foreach ($file in $AutoLoadExtensionFiles) {
	. "$file"
}

 if (Is-Administrator) {
	# Load default settings
	$defaultsettingspath = set-settingspath -settingname "default"
	Write-Log "default setting path: $defaultsettingspath"
	$DefaultSettings = load-settings -settingspath $defaultsettingspath

	# Load Project settings
	$projectsettingspath = set-settingspath $settings
	Write-Log "project setting path: $projectsettingspath"
	$ProjectSettings = load-settings -settingspath $projectsettingspath

	# Extend project settings with default
	$GlobalSettings = Merge-Settings -prior $ProjectSettings -fallback $DefaultSettings
	
	# Add steps section to settings
	$GlobalSettings = Steps-Settings -setting $GlobalSettings
	
	if ($help -eq "steps") {
		Write-Output "You can call steps* by the following syntaxt:"
		Write-Output "`t.\Run.ps1 <stepname>"
		Write-Output "`n*Please note that if there is a plot with similar name, it will triggered instead."
		Write-Output "`nAvailable steps:"
	
		# Set output field separator for this logic
		$OFS = "`r`n`t- "
	
		$GlobalSettings.Steps | Sort-Object | ForEach-Object {
			Write-Output "`t- $_"
		}	
	
		# Set back output field separator back to default
		$OFS = " "
	
		exit 0
	}
	
	if ($help -eq "plots") {
		Write-Output "You can call plots by the following syntaxt:"
		Write-Output "`t.\Run.ps1 <plotname>"
		Write-Output "`nAvailable plots:"
	
		Get-Member -Type NoteProperty -InputObject $GlobalSettings.Plots | 
			Sort-Object Name | 
			% { Write-Output "`t- $($_.Name)" }
	
		exit 0
	}
	
	if (!$plot) {
		exit
	} 
	elseif (Is-Administrator) {
	# Run given process
	Run-Steps -Plot "$Plot" -Step "$Step"

	$Global:JsonResult=$JsonResult
} else {
	Write-Verbose you have to run this script in administrator mode!
}

exit $Result