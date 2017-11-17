

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
		$script:ResultJson = @"
			{
				 "ExitCode": "$LASTEXITCODE"
			}
"@
	}
	catch {
		$script:ResultJson = @"
			{
				 "ExitCode": 1,
				"ErrorCode": "$ERRORLEVEL",
				"ErrorMessage": "$_.Exception.Message"
			   }
"@
	}
	Json
}


Function Module-Stop {
	<#
	.SYNOPSIS
	Stop site
	.DESCRIPTION
	Stop IIS site and application pool
	#>
	try {
		$Output = if ($ShowOutput -eq $True) {"Out-Default"} else {"Out-Null"}
		$ProjectSiteName = $ProjectSettings.IIS.WebAppName
		
		& "$ScriptBaseFolderPath\Ops\Stop-IISSite.ps1" $ProjectSiteName
		$script:Result = $LASTEXITCODE		
	}
	catch {
		$script:Result = 1
	}
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
		$script:Result = $LASTEXITCODE
	}
	catch {
		$script:Result = 1
	}
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
		$TfExePath = Get-FullPath $ProjectSettings.Tools.VisualStudio
		& $ScriptBaseFolderPath\Dev\GetLatestSolution.ps1 -tfexepath "$TfExePath" -location "$ProjectSourceFolderPath"
		$script:Result = $LASTEXITCODE
	}
	catch {
		$script:Result = 1
	}
	

}

Function Module-RestorePckgs {
<#
	.SYNOPSIS
	Nuget restore
	.DESCRIPTION
	
	#>
	try {
		$Output = if ($ShowOutput -eq $True) {"Out-Default"} else {"Out-Null"}
		Write-Verbose "RESTORE PACKAGES REFERENCED BY SOLUTION" 
		$NuGetFilePath = Get-FullPath $ProjectSettings.Tools.NuGetFilePath
		Write-Verbose "$NuGetFilePath"
		$ProjectSolutionFilePath = Get-FullPath $ProjectSettings.Project.SolutionFilePath
		Write-Verbose "$NuGetFilePath restore $ProjectSolutionFilePath" 
		& "$NuGetFilePath" restore "$ProjectSolutionFilePath" | & $Output
		$script:Result = $LASTEXITCODE
	}
	catch {
		$script:Result = 1
		Write-Verbose $_
	}
	
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
		$script:Result = $LASTEXITCODE
	}
	catch {
		$script:Result = 1
	}
	
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
		$script:Result = $LASTEXITCODE
	}
	catch {
		$script:Result = 1
	}
	
}

Function Module-SnServices {
<#
	.SYNOPSIS
	Sensenet install services
	.DESCRIPTION
	
	#>
	try {
		$Output = if ($ShowOutput -eq $True) {"Out-Default"} else {"Out-Null"}
	
		$ProjectWebConfigFilePath = Get-FullPath $ProjectSettings.Project.WebConfigFilePath
		if (Test-Path  ("$ProjectWebConfigFilePath")){
			Write-Verbose "Remove write protection from web.config: $ProjectWebConfigFilePath"
			Set-ItemProperty $ProjectWebConfigFilePath -Name IsReadOnly -Value $false
		}
		$ProjectToolsFolderPath = Get-FullPath $ProjectSettings.Project.ToolsFolderPath
		if (Test-Path  ("$ProjectToolsFolderPath")){
			Write-Verbose "Remove write protection from files under Tools folder: $ProjectToolsFolderPath"
			& "c:\Windows\System32\attrib.exe" -r "$ProjectToolsFolderPath\*.*" /s | & $Output
		}
		
		$DataSource=$ProjectSettings.DataBase.DataSource
		$InitialCatalog=$ProjectSettings.DataBase.InitialCatalog 
		& $ScriptBaseFolderPath\Deploy\Tool-Module.ps1 -ToolName "install-services" -ToolParameters "datasource:$DataSource","initialcatalog:$InitialCatalog","FORCEDREINSTALL:true" 
		$script:Result = $LASTEXITCODE
	}
	catch {
		$script:Result = 1
	}
}

Function Module-SnWebPages {
<#
	.SYNOPSIS
	Sensenet install webpages
	.DESCRIPTION
	
	#>
	try {
		& $ScriptBaseFolderPath\Deploy\Tool-Module.ps1 -ToolName "install-webpages" 
		$script:Result = $LASTEXITCODE
	}
	catch {
		$script:Result = 1
	}
	
}

Function Module-RemoveDemo {
<#
	.SYNOPSIS
	Remove demo contents
	.DESCRIPTION
	
	#>
	try {
		$RemoveDemoPackagePath = Get-FullPath "..\Packages\RemoveDemo"
		& $ScriptBaseFolderPath\Deploy\Package-Module.ps1 "$RemoveDemoPackagePath"
		$script:Result = $LASTEXITCODE
	}
	catch {
		$script:Result = 1
	}
	
}


Function Module-PrInstall {
<#
	.SYNOPSIS
	Project solution structure install
	.DESCRIPTION
	
	#>
	try {
		$ProjectDeployFolderPath =  Get-FullPath $ProjectSettings.Project.DeployFolderPath
		& $ScriptBaseFolderPath\Deploy\Package-Module.ps1 "$ProjectDeployFolderPath"	
		$script:Result = $LASTEXITCODE
	}
	catch {
		$script:Result = 1
	}
	
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
		$script:Result = $LASTEXITCODE
	}
	catch {
		$script:Result = 1
	}
	
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
		$script:Result = $LASTEXITCODE
	}
	catch {
		$script:Result = 1
	}
	
}

Function Module-InitWebfolder {
<#
	.SYNOPSIS
	Unzip webfolder package
	.DESCRIPTION
	
	#>
	try {
		$SnWebfolderPackPath = Get-FullPath $ProjectSettings.Platform.PackageName
		Write-Verbose "SnWebfolderPackPath: $SnWebfolderPackPath"
		$SnWebfolderPackName = (Get-FullPath $ProjectSettings.Platform.PackageName) + ".zip"
		Write-Verbose "SnWebfolderPackName: $SnWebfolderPackName"
		& $ScriptBaseFolderPath\Tools\Unzip-File.ps1 -filename "$SnWebfolderPackName" -destname "$SnWebfolderPackPath"
		$script:Result = $LASTEXITCODE
	}
	catch {
		$script:Result = 1
	}
	
}

Function Module-DeployWebFolder {
<#
	.SYNOPSIS
	Copy starter webfolder to detination
	.DESCRIPTION
	
	#>
	try {
		Write-Verbose "`r`nCopy webfolder files from package to destination"
		$SnWebfolderPackPath = Get-FullPath $ProjectSettings.Platform.PackageName
		$ProjectWebFolderPath = Get-FullPath $ProjectSettings.Project.WebFolderPath
		Write-Verbose "Source: $SnWebfolderPackPath"
		Write-Verbose "Target: $ProjectWebFolderPath"
		Copy-Item -Path "$SnWebfolderPackPath" -Destination "$ProjectWebFolderPath" -recurse -Force
		$script:Result = $LASTEXITCODE
	}
	catch {
		$script:Result = 1
	}
	
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
		# & iisreset
		& $ScriptBaseFolderPath\Deploy\Index-Project.ps1 
		$script:Result = $LASTEXITCODE
	}
	catch {
		$script:Result = 1
	}
	
}

Function Module-PrImport {
<#
	.SYNOPSIS
	Import project - not refactored
	.DESCRIPTION
	
	#>
	try {
		Write-Verbose "Start import script"
		& $ScriptBaseFolderPath\Deploy\Import-Module.ps1 "$ProjectStructureFolderPath"
		$script:Result = $LASTEXITCODE
	}
	catch {
		$script:Result = 1
	}
	
}

Function Module-PrExport {
<#
	.SYNOPSIS
	Export project 
	.DESCRIPTION
	
	#>
	try {
		# & iisreset

		$GETDate = Get-Date
		$CurrentDateTime = "[$($GETDate.Year)-$($GETDate.Month)-$($GETDate.Day)_$($GETDate.Hour)-$($GETDate.Minute)-$($GETDate.Second)]"
		$ProjectWebFolderPath = Get-FullPath $ProjectSettings.Project.WebFolderPath
		if (!($Exportfromfilepath)){
			Write-Verbose "Start export script"
			& $ScriptBaseFolderPath\Deploy\Export-Module.ps1 "$ProjectWebFolderPath\App_Data\Export$CurrentDateTime"
		}else{
			Write-Verbose "Start export script by filter: $Exportfromfilepath"
			& $ScriptBaseFolderPath\Deploy\Export-Module.ps1 "$ProjectWebFolderPath\App_Data\Export$CurrentDateTime" "$ExportFilter"
		}
		$script:Result = $LASTEXITCODE
	}
	catch {
		$script:Result = 1
	}
	
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
		$script:Result = $LASTEXITCODE
	}
	catch {
		$script:Result = 1
	}
	
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
		$script:Result = $LASTEXITCODE
	}
	catch {
		$script:Result = 1
	}
	
}
