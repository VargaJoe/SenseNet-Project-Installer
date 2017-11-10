

# ******************************************************************  Modules ******************************************************************
Function Module-Test {
	<#
	.SYNOPSIS
	Stop site
	.DESCRIPTION
	Stop IIS site and application pool
	#>
	try{
		$ProjectSiteName = $ProjectSettings.IIS.WebAppName
		& "$ScriptBaseFolderPath\Ops\Stop-IISSite.ps1" $ProjectSiteName
		$resultJson = @"
			{
				 "ExitCode": "$LASTEXITCODE"
			}
"@
	}
	catch {
		$resultJson = @"
			{
				 "ExitCode": 1,
				"ErrorCode": "$ERRORLEVEL",
				"ErrorMessage": "$_.Exception.Message"
			   }
"@
	}
	return $resultJson
}


Function Module-Stop {
	<#
	.SYNOPSIS
	Stop site
	.DESCRIPTION
	Stop IIS site and application pool
	#>
	try {
		$ProjectSiteName = $ProjectSettings.IIS.WebAppName
		& "$ScriptBaseFolderPath\Ops\Stop-IISSite.ps1" $ProjectSiteName
		$Result = $LASTEXITCODE
	}
	catch {
		$Result = 1
	}
	return @($Result)
}

Function Module-Start {
<#
	.SYNOPSIS
	Start site
	.DESCRIPTION
	Start IIS site and application pool
	#>
	try {
		$ProjectSiteName = $ProjectSettings.IIS.WebAppName
		& $ScriptBaseFolderPath\Ops\Start-IISSite.ps1 $ProjectSiteName
		$Result = $LASTEXITCODE
	}
	catch {
		$Result = 1
	}
	return $Result
}

Function Module-GetLatest {
<#
	.SYNOPSIS
	Get Latest Version
	.DESCRIPTION
	Initiate a Getlatest process on TFS
	#>
	# GET-LATEST - TODO: check if there is tfs
	try {
		$ProjectSourceFolderPath = Get-FullPath $ProjectSettings.Project.SourceFolderPath
		& $ScriptBaseFolderPath\Dev\GetLatestSolution.ps1 -tfexepath "${env:ProgramFiles(x86)}\Microsoft Visual Studio 14.0\Common7\IDE\tf.exe" -location "$ProjectSourceFolderPath"
		$Result = $LASTEXITCODE
	}
	catch {
		$Result = 1
	}
	return $Result

}

Function Module-RestorePckgs {
<#
	.SYNOPSIS
	Nuget restore
	.DESCRIPTION
	
	#>
	try {
		Write-Log "RESTORE PACKAGES REFERENCED BY SOLUTION" -foregroundcolor "green"
		$NuGetFilePath = Get-FullPath $ProjectSettings.Tools.NuGetFilePath
		Write-Log "$NuGetFilePath"
		$ProjectSolutionFilePath = Get-FullPath $ProjectSettings.Project.SolutionFilePath
		Write-Log "$NuGetFilePath restore $ProjectSolutionFilePath" 
		& "$NuGetFilePath" restore "$ProjectSolutionFilePath"
		$Result = $LASTEXITCODE
	}
	catch {
		$Result = 1
	}
	return $Result
}

Function Module-PrBuild {
<#
	.SYNOPSIS
	Build Solution
	.DESCRIPTION
	
	#>	
	try {
		$ProjectSolutionFilePath = Get-FullPath $ProjectSettings.Project.SolutionFilePath
		& $ScriptBaseFolderPath\Dev\Build-Solution.ps1 -slnPath $ProjectSolutionFilePath
		$Result = $LASTEXITCODE
	}
	catch {
		$Result = 1
	}
	return $Result
}

Function Module-SnInstall {
<#
	.SYNOPSIS
	Sensenet install
	.DESCRIPTION
	
	#>
	try {
		Module-SnServices
		Module-SnWebPages
		$Result = $LASTEXITCODE
	}
	catch {
		$Result = 1
	}
	return $Result
}

Function Module-SnServices {
<#
	.SYNOPSIS
	Sensenet install services
	.DESCRIPTION
	
	#>
	try {
		$ProjectWebConfigFilePath = Get-FullPath $ProjectSettings.Project.WebConfigFilePath
		if (Test-Path  ("$ProjectWebConfigFilePath")){
			Write-Log "Remove write protection from web.config: $ProjectWebConfigFilePath"
			Set-ItemProperty $ProjectWebConfigFilePath -Name IsReadOnly -Value $false
		}
		$ProjectToolsFolderPath = Get-FullPath $ProjectSettings.Project.ToolsFolderPath
		if (Test-Path  ("$ProjectToolsFolderPath")){
			Write-Log "Remove write protection from files under Tools folder: $ProjectToolsFolderPath"
			& "c:\Windows\System32\attrib.exe" -r "$ProjectToolsFolderPath\*.*" /s
		}
		
		$DataSource=$ProjectSettings.DataBase.DataSource
		$InitialCatalog=$ProjectSettings.DataBase.InitialCatalog 
		& $ScriptBaseFolderPath\Deploy\Tool-Module.ps1 -ToolName "install-services" -ToolParameters "datasource:$DataSource","initialcatalog:$InitialCatalog","FORCEDREINSTALL:true"
		$Result = $LASTEXITCODE
	}
	catch {
		$Result = 1
	}
	return $Result
}

Function Module-SnWebPages {
<#
	.SYNOPSIS
	Sensenet install webpages
	.DESCRIPTION
	
	#>
	try {
		Write-Log "INSTALL WEBPAGES" -foregroundcolor "green"
		& $ScriptBaseFolderPath\Deploy\Tool-Module.ps1 -ToolName "install-webpages" 
		$Result = $LASTEXITCODE
	}
	catch {
		$Result = 1
	}
	return $Result
}

Function Module-RemoveDemo {
<#
	.SYNOPSIS
	Remove demo contents
	.DESCRIPTION
	
	#>
	try {
		Write-Log "Start remove script: Remove Demo"
		$RemoveDemoPackagePath = Get-FullPath "..\Packages\RemoveDemo"
		& $ScriptBaseFolderPath\Deploy\Package-Module.ps1 "$RemoveDemoPackagePath"
		$Result = $LASTEXITCODE
	}
	catch {
		$Result = 1
	}
	return $Result
}


Function Module-PrInstall {
<#
	.SYNOPSIS
	Project solution structure install
	.DESCRIPTION
	
	#>
	try {
		Write-Log "INSTALL PROJECT" -foregroundcolor "green"
		$ProjectDeployFolderPath =  Get-FullPath $ProjectSettings.Project.DeployFolderPath
		& $ScriptBaseFolderPath\Deploy\Package-Module.ps1 "$ProjectDeployFolderPath"	
		$Result = $LASTEXITCODE
	}
	catch {
		$Result = 1
	}
	return $Result
}

Function Module-CreateSite {
<#
	.SYNOPSIS
	Create IIS Site and Application Pool
	.DESCRIPTION
	
	#>
	try {
		$ProjectWebFolderPath = Get-FullPath $ProjectSettings.Project.WebFolderPath
		$ProjectSiteName = $ProjectSettings.IIS.WebAppName 
		$ProjectAppPoolName = $ProjectSettings.IIS.AppPoolName 
		$ProjectSiteHosts = $ProjectSettings.IIS.Hosts
		& $ScriptBaseFolderPath\Ops\Create-IISSite.ps1 -DirectoryPath $ProjectWebFolderPath -SiteName $ProjectSiteName -PoolName $ProjectAppPoolName -SiteHosts $ProjectSiteHosts
		$Result = $LASTEXITCODE
	}
	catch {
		$Result = 1
	}
	return $Result
}

Function Module-SetHost {
<#
	.SYNOPSIS
	Set urls in hosts file
	.DESCRIPTION
	
	#>
	try {
		$ProjectSiteHosts = $ProjectSettings.IIS.Hosts
		& $ScriptBaseFolderPath\Ops\Set-Host.ps1 -SiteHosts $ProjectSiteHosts
		$Result = $LASTEXITCODE
	}
	catch {
		$Result = 1
	}
	return $Result
}

Function Module-InitWebfolder {
<#
	.SYNOPSIS
	Unzip webfolder package
	.DESCRIPTION
	
	#>
	try {
		$SnWebfolderPackPath = Get-FullPath $ProjectSettings.Platform.PackageName
		Write-Log "SnWebfolderPackPath: $SnWebfolderPackPath"
		$SnWebfolderPackName = (Get-FullPath $ProjectSettings.Platform.PackageName) + ".zip"
		Write-Log "SnWebfolderPackName: $SnWebfolderPackName"
		& $ScriptBaseFolderPath\Tools\Unzip-File.ps1 -filename "$SnWebfolderPackName" -destname "$SnWebfolderPackPath"
		$Result = $LASTEXITCODE
	}
	catch {
		$Result = 1
	}
	return $Result
}

Function Module-DeployWebFolder {
<#
	.SYNOPSIS
	Copy starter webfolder to detination
	.DESCRIPTION
	
	#>
	try {
		Write-Log "`r`nCopy webfolder files from package to destination"
		$SnWebfolderPackPath = Get-FullPath $ProjectSettings.Platform.PackageName
		$ProjectWebFolderPath = Get-FullPath $ProjectSettings.Project.WebFolderPath
		Write-Log "Source: $SnWebfolderPackPath"
		Write-Log "Target: $ProjectWebFolderPath"
		Copy-Item -Path "$SnWebfolderPackPath" -Destination "$ProjectWebFolderPath" -recurse -Force
		$Result = $LASTEXITCODE
	}
	catch {
		$Result = 1
	}
	return $Result
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
	try {
		& iisreset
		& $ScriptBaseFolderPath\Deploy\Index-Project.ps1 
		$Result = $LASTEXITCODE
	}
	catch {
		$Result = 1
	}
	return $Result
}

Function Module-PrImport {
<#
	.SYNOPSIS
	Import project - not refactored
	.DESCRIPTION
	
	#>
	try {
		Write-Log "Start import script"
		& $ScriptBaseFolderPath\Deploy\Import-Module.ps1 "$ProjectStructureFolderPath"
		$Result = $LASTEXITCODE
	}
	catch {
		$Result = 1
	}
	return $Result
}

Function Module-PrExport {
<#
	.SYNOPSIS
	Export project 
	.DESCRIPTION
	
	#>
	try {
		& iisreset

		$GETDate = Get-Date
		$CurrentDateTime = "[$($GETDate.Year)-$($GETDate.Month)-$($GETDate.Day)_$($GETDate.Hour)-$($GETDate.Minute)-$($GETDate.Second)]"
		$ProjectWebFolderPath = Get-FullPath $ProjectSettings.Project.WebFolderPath
		if (!($Exportfromfilepath)){
			Write-Log "Start export script"
			& $ScriptBaseFolderPath\Deploy\Export-Module.ps1 "$ProjectWebFolderPath\App_Data\Export$CurrentDateTime"
		}else{
			Write-Log "Start export script by filter: $Exportfromfilepath"
			& $ScriptBaseFolderPath\Deploy\Export-Module.ps1 "$ProjectWebFolderPath\App_Data\Export$CurrentDateTime" "$ExportFilter"
		}
		$Result = $LASTEXITCODE
	}
	catch {
		$Result = 1
	}
	return $Result
}

Function Module-CreatePackage {
<#
	.SYNOPSIS
	Create SnAdmin package - not refactored
	.DESCRIPTION
	
	#>
	try {
		$GETDate = Get-Date
		$currentdatetime = "[$($GETDate.Year)-$($GETDate.Month)-$($GETDate.Day)_$($GETDate.Hour)-$($GETDate.Minute)-$($GETDate.Second)]"
		Write-Log "Start package creator"
		Write-Log "$ScriptBaseFolderPath\Create-Package.ps1 -SourceRootPath $ProjectSourceFolderPath -TargetRootPath $ProjectSourceFolderPath/Packages"
		& $ScriptBaseFolderPath\Create-Package.ps1 -SourceRootPath "$ProjectSourceFolderPath" -TargetRootPath "$ProjectSourceFolderPath/Deployment/Packages"
		$Result = $LASTEXITCODE
	}
	catch {
		$Result = 1
	}
	return $Result
}

Function Module-SetRepoUrl {
<#
	.SYNOPSIS
	Set sensenet site repository url
	.DESCRIPTION
	
	#>
	try {
		# Site name, url and authentication type must be get from settings json, probably with iteration
		$SiteName="Defaul_Site"
		$Url="project"
		$AuthenticationType="Forms"
		& $ScriptBaseFolderPath\Deploy\Tool-Module.ps1 -ToolName "seturl" -ToolParameters "site:$SiteName","url:$Url","authenticationType:$AuthenticationType"
		$Result = $LASTEXITCODE
	}
	catch {
		$Result = 1
	}
	return $Result
}
