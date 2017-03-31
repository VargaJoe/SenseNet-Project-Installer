[CmdletBinding(SupportsShouldProcess=$True)]
Param(
[Parameter(Mandatory=$false)]
[string]$Mode
)
[environment]::CurrentDirectory = Split-Path -Parent $MyInvocation.MyCommand.Path
$SettingsPath = 'project-test.json'

# ================================================
# ================ MAIN SCRIPT ===================
# ================================================

#nice to have: mode array 

Write-Host Helper functions initialization from $Initfunctions
. ".\Initialization.ps1"

# if (!($Mode)){
# $Mode = ""
# }

# $modulename = $MyInvocation.MyCommand.Name
# # GET-LATEST
# if ($Mode.ToLower() -eq "deploy" -or $Mode.ToLower() -eq "getlatest"){
# & .\GetLatestSolution.ps1 -tfexepath "${env:ProgramFiles(x86)}\Microsoft Visual Studio 14.0\Common7\IDE\tf.exe" -location "$ProjectSourceFolderPath"
# }

# # SOLUTION BUILD
# if ($Mode.ToLower() -eq "deploy" -or $Mode.ToLower() -eq "prbuild"){
# & .\BuildSnSolution.ps1 -slnPath $ProjectSolutionFilePath
# }

# # INIT-ASSEMBLIES
# if ($Mode.ToLower() -eq "deploy" -or $Mode.ToLower() -eq "initasm"){
# & .\Init-Assemblies.ps1 "$SnWebFolderPath" "$ProjectWebFolderPath" "$DataSource" "$InitialCatalog"
# & .\AddHostInWebConfig.ps1 "$ProjectWebConfigFilePath" $ProjectSiteName
# }
