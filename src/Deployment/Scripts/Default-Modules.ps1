

# ******************************************************************  Modules ******************************************************************

Function Module-testmodul {
	Write-Host TESTMODUL
	Write-Host --------------------------------------------------
	Write-Host ---------------- FINISH INSTALL ------------------
	Write-Host --------------------------------------------------
}

Function Module-Stop {
	<#
	.SYNOPSIS
	Stop site
	.DESCRIPTION
	Stop IIS site and application pool
	#>
	$ProjectSiteName = $ProjectSettings.IIS.WebAppName
	 & .\Ops\Stop-IISSite.ps1 $ProjectSiteName
}

Function Module-Start {
<#
	.SYNOPSIS
	Start site
	.DESCRIPTION
	Start IIS site and application pool
	#>
	$ProjectSiteName = $ProjectSettings.IIS.WebAppName
	& .\Ops\Start-IISSite.ps1 $ProjectSiteName
}

Function Module-GetLatest {
<#
	.SYNOPSIS
	Get Latest Version
	.DESCRIPTION
	Initiate a Getlatest process on TFS
	#>
	# GET-LATEST - TODO: check if there is tfs
	$ProjectSourceFolderPath = Get-FullPath $ProjectSettings.Project.SourceFolderPath
	& .\Dev\GetLatestSolution.ps1 -tfexepath "${env:ProgramFiles(x86)}\Microsoft Visual Studio 14.0\Common7\IDE\tf.exe" -location "$ProjectSourceFolderPath"

}

Function Module-RestorePckgs {
<#
	.SYNOPSIS
	Nuget restore
	.DESCRIPTION
	
	#>
	Write-Host RESTORE PACKAGES REFERENCED BY SOLUTION -foregroundcolor "green"
	$NuGetFilePath = Get-FullPath $ProjectSettings.Tools.NuGetFilePath
	$ProjectSolutionFilePath = Get-FullPath $ProjectSettings.Project.SolutionFilePath
	Write-Host $NuGetFilePath restore $ProjectSolutionFilePath
	& $NuGetFilePath restore $ProjectSolutionFilePath
}

Function Module-PrBuild {
<#
	.SYNOPSIS
	Build Solution
	.DESCRIPTION
	
	#>
	$ProjectSolutionFilePath = Get-FullPath $ProjectSettings.Project.SolutionFilePath
	& .\Dev\Build-Solution.ps1 -slnPath $ProjectSolutionFilePath
}

Function Module-SnInstall {
<#
	.SYNOPSIS
	Sensenet install
	.DESCRIPTION
	
	#>
	Module-SnServices
	Module-SnWebPages
}

Function Module-SnServices {
<#
	.SYNOPSIS
	Sensenet install services
	.DESCRIPTION
	
	#>
	$ProjectWebConfigFilePath = Get-FullPath $ProjectSettings.Project.WebConfigFilePath
	if (Test-Path  ("$ProjectWebConfigFilePath")){
		Write-Host "Remove write protection from web.config: $ProjectWebConfigFilePath"
		Set-ItemProperty $ProjectWebConfigFilePath -Name IsReadOnly -Value $false
	}
	$ProjectToolsFolderPath = Get-FullPath $ProjectSettings.Project.ToolsFolderPath
	if (Test-Path  ("$ProjectToolsFolderPath")){
		Write-Host "Remove write protection from files under Tools folder: $ProjectToolsFolderPath"
		& "c:\Windows\System32\attrib.exe" -r "$ProjectToolsFolderPath\*.*" /s
	}
	
	$DataSource=$ProjectSettings.DataBase.DataSource
	$InitialCatalog=$ProjectSettings.DataBase.InitialCatalog 
	# Write-Host DataSource: $DataSource
	# Write-Host InitialCatalog: $InitialCatalog
	# & $ProjectSnAdminFilePath install-services datasource:$DataSource initialcatalog:$InitialCatalog FORCEDREINSTALL:true	
	& .\Deploy\Tool-Module.ps1 -ToolName "install-services" -ToolParameters "datasource:$DataSource","initialcatalog:$InitialCatalog","FORCEDREINSTALL:true"
}

Function Module-SnWebPages {
<#
	.SYNOPSIS
	Sensenet install webpages
	.DESCRIPTION
	
	#>
	Write-Host INSTALL WEBPAGES -foregroundcolor "green"
	# & $ProjectSnAdminFilePath install-webpages
	& .\Deploy\Tool-Module.ps1 -ToolName "install-webpages" 
}

Function Module-RemoveDemo {
<#
	.SYNOPSIS
	Remove demo contents
	.DESCRIPTION
	
	#>
	Write-Host Start remove script: Remove Demo
	$RemoveDemoPackagePath = Get-FullPath "..\Packages\RemoveDemo"
	& .\Deploy\Package-Module.ps1 "$RemoveDemoPackagePath"
	
	# $RemoveDemoPackagePath = Get-FullPath "..\Packages\RemoveDemo\import"
	# & .\Deploy\Import-Module.ps1 "$RemoveDemoPackagePath"
}


Function Module-PrInstall {
<#
	.SYNOPSIS
	Project solution structure install
	.DESCRIPTION
	
	#>
	Write-Host INSTALL PROJECT -foregroundcolor "green"
	$ProjectDeployFolderPath =  Get-FullPath $ProjectSettings.Project.DeployFolderPath
	& .\Deploy\Package-Module.ps1 "$ProjectDeployFolderPath"	
}

Function Module-CreateSite {
<#
	.SYNOPSIS
	Create IIS Site and Application Pool
	.DESCRIPTION
	
	#>
	$ProjectWebFolderPath = Get-FullPath $ProjectSettings.Project.WebFolderPath
	$ProjectSiteName = $ProjectSettings.IIS.WebAppName 
	$ProjectAppPoolName = $ProjectSettings.IIS.AppPoolName 
	$ProjectSiteHosts = $ProjectSettings.IIS.Hosts
	& .\Ops\Create-IISSite.ps1 -DirectoryPath $ProjectWebFolderPath -SiteName $ProjectSiteName -PoolName $ProjectAppPoolName -SiteHosts $ProjectSiteHosts
}

Function Module-SetHost {
<#
	.SYNOPSIS
	Set urls in hosts file
	.DESCRIPTION
	
	#>
	$ProjectSiteHosts = $ProjectSettings.IIS.Hosts
	& .\Ops\Set-Host.ps1 -SiteHosts $ProjectSiteHosts
}

Function Module-InitWebfolder {
<#
	.SYNOPSIS
	Unzip webfolder package
	.DESCRIPTION
	
	#>
	$SnWebfolderPackPath = Get-FullPath $ProjectSettings.Platform.PackageName
	Write-Host SnWebfolderPackPath: $SnWebfolderPackPath
	$SnWebfolderPackName = (Get-FullPath $ProjectSettings.Platform.PackageName) + ".zip"
	Write-Host SnWebfolderPackName: $SnWebfolderPackName
	& .\Tools\Unzip-File.ps1 -filename "$SnWebfolderPackName" -destname "$SnWebfolderPackPath"
}

Function Module-DeployWebFolder {
<#
	.SYNOPSIS
	Copy starter webfolder to detination
	.DESCRIPTION
	
	#>
	Write-host `r`nCopy webfolder files from package to destination
	$SnWebfolderPackPath = Get-FullPath $ProjectSettings.Platform.PackageName
	$ProjectWebFolderPath = Get-FullPath $ProjectSettings.Project.WebFolderPath
	Write-Host Source: $SnWebfolderPackPath
	Write-Host Target: $ProjectWebFolderPath
	Copy-Item -Path "$SnWebfolderPackPath" -Destination "$ProjectWebFolderPath" -recurse -Force
}


# ================================================
# ================ EXT SCRIPTS ===================
# ================================================
# unchecked

Function Module-PrIndex {
<#
	.SYNOPSIS
	Populate full index on repository
	.DESCRIPTION
	
	#>
	& iisreset
	& .\Deploy\Index-Project.ps1 
}

Function Module-PrImport {
<#
	.SYNOPSIS
	Import project - not refactored
	.DESCRIPTION
	
	#>
	Write-Host Start import script
	& .\Deploy\Import-Module.ps1 "$ProjectStructureFolderPath"
}

Function Module-PrExport {
<#
	.SYNOPSIS
	Export project 
	.DESCRIPTION
	
	#>
	& iisreset

	$GETDate = Get-Date
	$CurrentDateTime = "[$($GETDate.Year)-$($GETDate.Month)-$($GETDate.Day)_$($GETDate.Hour)-$($GETDate.Minute)-$($GETDate.Second)]"
	$ProjectWebFolderPath = Get-FullPath $ProjectSettings.Project.WebFolderPath
	if (!($Exportfromfilepath)){
		Write-Host Start export script
		& .\Deploy\Export-Module.ps1 "$ProjectWebFolderPath\App_Data\Export$CurrentDateTime"
	}else{
		Write-Host "Start export script by filter: $Exportfromfilepath"
		& .\Deploy\Export-Module.ps1 "$ProjectWebFolderPath\App_Data\Export$CurrentDateTime" "$ExportFilter"
	}
}

Function Module-CreatePackage {
<#
	.SYNOPSIS
	Create SnAdmin package - not refactored
	.DESCRIPTION
	
	#>
	$GETDate = Get-Date
	$currentdatetime = "[$($GETDate.Year)-$($GETDate.Month)-$($GETDate.Day)_$($GETDate.Hour)-$($GETDate.Minute)-$($GETDate.Second)]"
	Write-Host Start package creator
	Write-Host .\Create-Package.ps1 -SourceRootPath "$ProjectSourceFolderPath" -TargetRootPath "$ProjectSourceFolderPath/Packages"
	& .\Create-Package.ps1 -SourceRootPath "$ProjectSourceFolderPath" -TargetRootPath "$ProjectSourceFolderPath/Deployment/Packages"
}

