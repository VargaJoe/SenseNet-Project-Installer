[CmdletBinding(SupportsShouldProcess=$True)]
Param(
[Parameter(Mandatory=$false)]
[string]$Mode,
[Parameter(Mandatory=$false)] 
[string]$ExportFromFilePath
)

# ================================================
# ================ MAIN SCRIPT ===================
# ================================================

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
Write-Host "================ START INSTALL SCRIPT =================="
Write-Host "========================================================"
Write-Host Mode: $Mode
# READ FROM JSON
# INITIALIZATION
. "$InitFilePath"

# STOP SITE
if ($Mode.ToLower() -eq "fullinstall" -or $Mode.ToLower() -eq "stop"){
& .\StopWebsiteAppPool.ps1 $ProjectSiteName
}

# UNZIP
if ($Mode.ToLower() -eq "fullinstall" -or $Mode.ToLower() -eq "unzip"){
	$valami = [IO.Path]::GetFullPath($SnPackageFilePath)
	Write-Host SnPackageFilePath: $valami
& .\unzip.ps1 -filename "$SnPackageFilePath" -destname "$SnSourceBasePath"
}

# SN SOLUTION BUILD
if ($Mode.ToLower() -eq "fullinstall" -or $Mode.ToLower() -eq "snbuild"){
& .\BuildSnSolution.ps1 -slnPath "$SnSolutionFilePath"
& .\BuildSnSolution.ps1 -slnPath "$SnSolutionFilePath" #maybe the first build was not successful
}

# SN-INSTALL
if ($Mode.ToLower() -eq "fullinstall" -or $Mode.ToLower() -eq "sninstall"){
& .\Install-SenseNet.ps1 "$SnSourceBasePath" $DataSource $InitialCatalog
}

# INIT-ASSEMBLIES
if ($Mode.ToLower() -eq "fullinstall" -or $Mode.ToLower() -eq "initasm"){
& .\Init-Assemblies.ps1 "$SnWebFolderPath" "$ProjectWebFolderPath" "$DataSource" "$InitialCatalog"
#& .\AddHostInWebConfig.ps1 "$ProjectWebConfigFilePath" $ProjectSiteName
}

# GET-LATEST
if ($Mode.ToLower() -eq "fullinstall" -or $Mode.ToLower() -eq "getlatest"){
& .\GetLatestSolution.ps1 -tfexepath "${env:ProgramFiles(x86)}\Microsoft Visual Studio 14.0\Common7\IDE\tf.exe" -location "$ProjectSourceFolderPath"
}

# REMOVE DEMO CONTENTS
if ($Mode.ToLower() -eq "fullinstall" -or $Mode.ToLower() -eq "removedemo"){
Write-Host Start remove script
& .\Import-Module.ps1 "$ProjectWebFolderPath"  "..\RemoveDemo" 
}

# SOLUTION BUILD
if ($Mode.ToLower() -eq "fullinstall" -or $Mode.ToLower() -eq "prbuild"){
& .\BuildSnSolution.ps1 -slnPath $ProjectSolutionFilePath
}

# IMPORT
if ($Mode.ToLower() -eq "fullinstall"){
Write-Host Start import script
& .\Import-Project.ps1 "$ProjectWebFolderPath" $DataSource $InitialCatalog
} elseif ($Mode.ToLower() -eq "primport"){
Write-Host Start import script
& .\Import-Project.ps1 "$ProjectWebFolderPath" 
}


# INDEXPOPULATION
if ($Mode.ToLower() -eq "fullinstall" -or $Mode.ToLower() -eq "prindex"){
& .\Index-Project.ps1 "$ProjectWebFolderPath" $DataSource $InitialCatalog
}

# CREATE IIS SITE
if ($Mode.ToLower() -eq "fullinstall" -or $Mode.ToLower() -eq "createsite"){
& .\Create-IISSite.ps1 $ProjectSiteName $ProjectWebFolderPath
}

# MODIFY HOST FILE
if ($Mode.ToLower() -eq "fullinstall" -or $Mode.ToLower() -eq "sethost"){
& .\SetHostFile.ps1 -hostname $ProjectSiteName
}

# SITE START
#Write-Host `n**************Start Site: $ProjectSiteName
if ($Mode.ToLower() -eq "fullinstall" -or $Mode.ToLower() -eq "start"){
& .\StartWebsiteAppPool.ps1 $ProjectSiteName
}

# ================================================
# ================ EXT SCRIPTS ===================
# ================================================


# EXPORT PROJECT
if ($Mode.ToLower() -eq "prexport"){
$GETDate = Get-Date
$currentdatetime = "[$($GETDate.Year)-$($GETDate.Month)-$($GETDate.Day)_$($GETDate.Hour)-$($GETDate.Minute)-$($GETDate.Second)]"
	if (!($Exportfromfilepath)){
		Write-Host Start export script
		& .\Export-Module.ps1 "$ProjectWebFolderPath" "$ProjectWebFolderPath/App_Data/Export$currentdatetime"
	}else{
		Write-Host "Start export script by filter: $Exportfromfilepath"
		& .\Export-Module.ps1 "$ProjectWebFolderPath" "$ProjectWebFolderPath/App_Data/Export$currentdatetime" "$Exportfromfilepath"
	}
}
