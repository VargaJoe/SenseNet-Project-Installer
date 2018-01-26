[CmdletBinding(SupportsShouldProcess=$True)]
Param(
[Parameter(Mandatory=$false)]
[string]$Mode,
[Parameter(Mandatory=$false)] 
[string]$Settings = "local",
[Parameter(Mandatory=$false)] 
[string]$Params,
[Parameter(Mandatory=$false)] 
[string]$ExportFilter,
[Parameter(Mandatory=$false)] 
[string]$ShowOutput = $True,
[Parameter(Mandatory=$false)] 
[string]$OutputMode = "Host"
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

$AutoLoadExtensions = [IO.Path]::GetFullPath([IO.Path]::Combine($ScriptBaseFolderPath, "AutoExt"))

# ================================================
# ================ MAIN SCRIPT ===================
# ================================================

$AutoLoadExtensionFiles = Get-ChildItem "$AutoLoadExtensions\*.ps1"
foreach ($file in $AutoLoadExtensionFiles) {
	. "$file"
}

 if (Is-Administrator) {
	$defaultsettingspath = set-settingspath -settingname "default"
	Write-Log "default setting path: $defaultsettingspath"
	$defaultsettings = load-settings -settingspath $defaultsettingspath

	$projectsettingspath = set-settingspath $settings
	Write-Log "project setting path: $projectsettingspath"
	$ProjectSettings = load-settings -settingspath $projectsettingspath

	# $mergedsettings = Join-Object -Left $projectsettings -Right $defaultsettings -LeftJoinProperty * -RightJoinProperty * -Type AllInBoth | ConvertTo-Json -depth 100  | Out-File "test.json"
	# Write-Verbose 3 $mergedsettings
	
	# Start-Transcript -path output.txt 
	Run-Modules "$Mode"  
	# Stop-Transcript
	
	# Package list	
	 # $pckgs = List-Packages
	 # Write-Verbose $pckgs
} else {
	Write-Verbose you have to run this script in administrator mode!
}

exit $Result