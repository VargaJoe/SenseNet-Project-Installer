[CmdletBinding(SupportsShouldProcess=$True)]
Param(
[Parameter(Mandatory=$false)]
[string]$Mode
)

# ================================================
# ================ REMOVE DEFAULT SITE ===================
# ================================================

Write-Host ================================================ -foregroundcolor "green"
Write-Host REMOVE DEFAULT SITE -foregroundcolor "green"
Write-Host ================================================ -foregroundcolor "green"

#nice to have: mode array 

if (!($Mode)){
$Mode = ""
}

$ScriptBaseFolderPath = Split-Path -Parent $MyInvocation.MyCommand.Path
$InitFileCombPath = [IO.Path]::Combine($ScriptBaseFolderPath, "Initialization.ps1")
$InitFilePath = [IO.Path]::GetFullPath($InitFileCombPath)

[environment]::CurrentDirectory = Split-Path -Parent $MyInvocation.MyCommand.Path

$modulename = $MyInvocation.MyCommand.Name
Write-Host "========================================================"
Write-Host "================ START REMOVEDEMO SCRIPT =================="
Write-Host "========================================================"
Write-Host Mode: $Mode
# READ FROM JSON
# INITIALIZATION
. "$InitFilePath"

# STOP SITE
if ($Mode.ToLower() -eq "fullinstall" -or $Mode.ToLower() -eq "stop"){
& .\StopWebsiteAppPool.ps1 $ProjectSiteName
}

# GET-LATEST
if ($Mode.ToLower() -eq "fullinstall" -or $Mode.ToLower() -eq "getlatest"){
& .\GetLatestSolution.ps1 -tfexepath "${env:ProgramFiles(x86)}\Microsoft Visual Studio 14.0\Common7\IDE\tf.exe" -location "$ProjectSourceFolderPath"
}

# IMPORT
if ($Mode.ToLower() -eq "removedemo"){
Write-Host Start import script
& .\Import-Module.ps1 "$ProjectWebFolderPath"  "..\RemoveDemo" 
}

# INDEXPOPULATION
if ($Mode.ToLower() -eq "fullinstall" -or $Mode.ToLower() -eq "prindex"){
& .\Index-Project.ps1 "$ProjectWebFolderPath" $DataSource $InitialCatalog
}

# SITE START
#Write-Host `n**************Start Site: $ProjectSiteName
if ($Mode.ToLower() -eq "fullinstall" -or $Mode.ToLower() -eq "start"){
& .\StartWebsiteAppPool.ps1 $ProjectSiteName
}