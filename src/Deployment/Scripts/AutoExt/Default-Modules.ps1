

# ******************************************************************  Steps ******************************************************************
Function Step-Test {
	<#
	.SYNOPSIS
	Stop site
	.DESCRIPTION
	Stop IIS site and application pool
	#>
	try{
		$ProjectSiteName = $GlobalSettings.IIS.WebAppName
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


Function Step-Stop {
	<#
	.SYNOPSIS
	Stop site
	.DESCRIPTION
	Stop IIS site and application pool
	#>
	try {
		$Output = if ($ShowOutput -eq $True) {"Out-Default"} else {"Out-Null"}
		$ProjectSiteName = $GlobalSettings.IIS.WebAppName
		
		& "$ScriptBaseFolderPath\Ops\Stop-IISSite.ps1" $ProjectSiteName
		$script:Result = $LASTEXITCODE		
	}
	catch {
		$script:Result = 1
	}
}

Function Step-Start {
<#
	.SYNOPSIS
	Start site
	.DESCRIPTION
	Start IIS site and application pool
	#>
	try {
		$ProjectSiteName = $GlobalSettings.IIS.WebAppName
		& $ScriptBaseFolderPath\Ops\Start-IISSite.ps1 $ProjectSiteName
		$script:Result = $LASTEXITCODE
	}
	catch {
		$script:Result = 1
	}
}

Function Step-GetLatest {
<#
	.SYNOPSIS
	Get Latest Version
	.DESCRIPTION
	Initiate a Getlatest process on TFS
	#>
	# GET-LATEST - TODO: check if there is tfs
	try {
		$ProjectSourceFolderPath = Get-FullPath $GlobalSettings.Project.SourceFolderPath
		$TfExePath = Get-FullPath $GlobalSettings.Tools.VisualStudio
		& $ScriptBaseFolderPath\Dev\GetLatestSolution.ps1 -tfexepath "$TfExePath" -location "$ProjectSourceFolderPath"
		$script:Result = $LASTEXITCODE
	}
	catch {
		$script:Result = 1
	}
	

}

Function Step-RestorePckgs {
<#
	.SYNOPSIS
	Nuget restore
	.DESCRIPTION
	
	#>
	try {
		$Output = if ($ShowOutput -eq $True) {"Out-Default"} else {"Out-Null"}
		Write-Verbose "RESTORE PACKAGES REFERENCED BY SOLUTION" 
		$NuGetSourcePath = $GlobalSettings.Tools.NuGetSourceUrl
		$NuGetFilePath = Get-FullPath $GlobalSettings.Tools.NuGetFilePath
		Write-Verbose "Check if $NuGetFilePath exists..."
		& $ScriptBaseFolderPath\Dev\Download-File.ps1 -Url $NuGetSourcePath -Output $NuGetFilePath
		$ProjectSolutionFilePath = Get-FullPath $GlobalSettings.Project.SolutionFilePath
		Write-Verbose "$NuGetFilePath restore $ProjectSolutionFilePath" 
		& "$NuGetFilePath" restore "$ProjectSolutionFilePath" | & $Output
		$script:Result = $LASTEXITCODE
	}
	catch {
		$script:Result = 1
		Write-Verbose $_
	}
	
}

Function Step-PrBuild {
<#
	.SYNOPSIS
	Build Solution
	.DESCRIPTION
	
	#>	
	try {
		$ProjectSolutionFilePath = Get-FullPath $GlobalSettings.Project.SolutionFilePath
		& $ScriptBaseFolderPath\Dev\Build-Solution.ps1 -slnPath $ProjectSolutionFilePath 
		$script:Result = $LASTEXITCODE
	}
	catch {
		$script:Result = 1
	}
	
}

Function Step-SnInstall {
<#
	.SYNOPSIS
	Sensenet install
	.DESCRIPTION
	
	#>
	try {
		Step-SnServices
		Step-SnWebPages
		$script:Result = $LASTEXITCODE
	}
	catch {
		$script:Result = 1
	}
	
}

Function Step-SnServices {
<#
	.SYNOPSIS
	Sensenet install services
	.DESCRIPTION
	
	#>
	try {
		$Output = if ($ShowOutput -eq $True) {"Out-Default"} else {"Out-Null"}
	
		$ProjectWebConfigFilePath = Get-FullPath $GlobalSettings.Project.WebConfigFilePath
		if (Test-Path  ("$ProjectWebConfigFilePath")){
			Write-Verbose "Remove write protection from web.config: $ProjectWebConfigFilePath"
			Set-ItemProperty $ProjectWebConfigFilePath -Name IsReadOnly -Value $false
		}
		$ProjectToolsFolderPath = Get-FullPath $GlobalSettings.Project.ToolsFolderPath
		if (Test-Path  ("$ProjectToolsFolderPath")){
			Write-Verbose "Remove write protection from files under Tools folder: $ProjectToolsFolderPath"
			& "c:\Windows\System32\attrib.exe" -r "$ProjectToolsFolderPath\*.*" /s | & $Output
		}
		
		$DataSource=$GlobalSettings.DataBase.DataSource
		$InitialCatalog=$GlobalSettings.DataBase.InitialCatalog 
		& $ScriptBaseFolderPath\Deploy\Tool-Module.ps1 -ToolName "install-services" -ToolParameters "datasource:$DataSource","initialcatalog:$InitialCatalog","FORCEDREINSTALL:true" 
		$script:Result = $LASTEXITCODE
	}
	catch {
		$script:Result = 1
	}
}

Function Step-SnWebPages {
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

Function Step-RemoveDemo {
<#
	.SYNOPSIS
	Remove demo contents
	.DESCRIPTION
	
	#>
	try {
		$PackagePath = Get-FullPath "..\Packages\RemoveDemo"
		& $ScriptBaseFolderPath\Deploy\Package-Module.ps1 -PackagePath "$PackagePath"
		$script:Result = $LASTEXITCODE
	}
	catch {
		$script:Result = 1
	}
}

Function Step-AdminUsers {
<#
	.SYNOPSIS
	Set common administrators and group memberships
	.DESCRIPTION
	
	#>
	try {
		$PackagePath = Get-FullPath "..\Packages\UsersStructure"
		& $ScriptBaseFolderPath\Deploy\Package-Module.ps1 -PackagePath "$PackagePath"
		$script:Result = $LASTEXITCODE
	}
	catch {
		$script:Result = 1
	}
	
}

Function Step-PrInstall {
<#
	.SYNOPSIS
	Project solution structure install
	.DESCRIPTION
	
	#>
	try {
		$PackagePath =  Get-FullPath $GlobalSettings.Project.DeployFolderPath
		& $ScriptBaseFolderPath\Deploy\Package-Module.ps1 -PackagePath "$PackagePath"	
		$script:Result = $LASTEXITCODE
	}
	catch {
		$script:Result = 1
	}
	
}

Function Step-CreateSite {
<#
	.SYNOPSIS
	Create IIS Site and Application Pool
	.DESCRIPTION
	
	#>
	try {
		$ProjectWebFolderPath = Get-FullPath $GlobalSettings.Project.WebFolderPath
		$ProjectSiteName = $GlobalSettings.IIS.WebAppName 
		$ProjectAppPoolName = $GlobalSettings.IIS.AppPoolName 
		$ProjectSiteHosts = $GlobalSettings.IIS.Hosts
		& $ScriptBaseFolderPath\Ops\Create-IISSite.ps1 -DirectoryPath $ProjectWebFolderPath -SiteName $ProjectSiteName -PoolName $ProjectAppPoolName -SiteHosts $ProjectSiteHosts
		$script:Result = $LASTEXITCODE
	}
	catch {
		$script:Result = 1
	}
	
}

Function Step-SetHost {
<#
	.SYNOPSIS
	Set urls in hosts file
	.DESCRIPTION
	
	#>
	try {
		$ProjectSiteHosts = $GlobalSettings.IIS.Hosts
		& $ScriptBaseFolderPath\Ops\Set-Host.ps1 -SiteHosts $ProjectSiteHosts
		$script:Result = $LASTEXITCODE
	}
	catch {
		$script:Result = 1
	}
	
}

Function Step-InitWebfolder {
<#
	.SYNOPSIS
	Unzip webfolder package
	.DESCRIPTION
	
	#>
	try {
		$SnWebfolderPackPath = Get-FullPath $GlobalSettings.Platform.PackageName
		Write-Verbose "SnWebfolderPackPath: $SnWebfolderPackPath"
		$SnWebfolderPackName = (Get-FullPath $GlobalSettings.Platform.PackageName) + ".zip"
		Write-Verbose "SnWebfolderPackName: $SnWebfolderPackName"
		& $ScriptBaseFolderPath\Tools\Unzip-File.ps1 -filename "$SnWebfolderPackName" -destname "$SnWebfolderPackPath"
		$script:Result = $LASTEXITCODE
	}
	catch {
		$script:Result = 1
	}
	
}

Function Step-DeployWebFolder {
<#
	.SYNOPSIS
	Copy starter webfolder to detination
	.DESCRIPTION
	
	#>
	try {
		Write-Verbose "`r`nCopy webfolder files from package to destination"
		$SnWebfolderPackPath = Get-FullPath $GlobalSettings.Platform.PackageName
		$ProjectWebFolderPath = Get-FullPath $GlobalSettings.Project.WebFolderPath
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

Function Step-PrIndex {
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

Function Step-PrImport {
<#
	.SYNOPSIS
	Import project - not refactored
	.DESCRIPTION
	
	#>
	try {
		$ProjectRepoFsFolderPath = Get-FullPath $GlobalSettings.Project.RepoFsFolderPath
		Write-Verbose "Start import script with the path: $ProjectRepoFsFolderPath"		
		& $ScriptBaseFolderPath\Deploy\Import-Module.ps1 -SourcePath "$ProjectRepoFsFolderPath"
		$script:Result = $LASTEXITCODE
	}
	catch {
		$script:Result = 1
	}
	
}

Function Step-PrExport {
<#
	.SYNOPSIS
	Export project 
	.DESCRIPTION
	
	#>
	[CmdletBinding(SupportsShouldProcess=$True)]
		Param(
		[Parameter(Mandatory=$false)]
		[string]$Section="Project"
		)
	
	try {
		# & iisreset

		$GETDate = Get-Date
		$CurrentDateTime = "[$($GETDate.Year)-$($GETDate.Month)-$($GETDate.Day)_$($GETDate.Hour)-$($GETDate.Minute)-$($GETDate.Second)]"
		$ProjectWebFolderPath = Get-FullPath $GlobalSettings."$Section".WebFolderPath
		if (!($Exportfromfilepath)){
			Write-Verbose "Start export script"
			& $ScriptBaseFolderPath\Deploy\Export-Module.ps1 -TargetPath "$ProjectWebFolderPath\App_Data\Export$CurrentDateTime"
		}else{
			Write-Verbose "Start export script by filter: $Exportfromfilepath"
			& $ScriptBaseFolderPath\Deploy\Export-Module.ps1 -TargetPath "$ProjectWebFolderPath\App_Data\Export$CurrentDateTime" -ExportFromFilePath "$ExportFilter"
		}
		$script:Result = $LASTEXITCODE
	}
	catch {
		$script:Result = 1
	}
	
}

Function Step-CreatePackage {
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

Function Step-SetRepoUrl {
<#
	.SYNOPSIS
	Set sensenet site repository url
	.DESCRIPTION
	-SiteHosts $ProjectSiteHosts
	#>
	# Technical Debt: it should be called an independent ps1 file from here, instead a hardcoded business logic
	try {
		# Site name, url and authentication type must be get from settings json, probably with iteration
		$ProjectSiteHosts = $GlobalSettings.IIS.Hosts
		# $ProjectSiteName = $GlobalSettings.IIS.WebAppName
		$AuthenticationType="Forms"
		
		foreach ($hostCombinedUrl in $ProjectSiteHosts) {				
			$hostUrlComponents = $hostCombinedUrl.Split(":")
			if ($hostUrlComponents[1] -eq $Null){
				$ProjectSiteName = "project"
				$hostUrl = $hostUrlComponents[0]
			} else {
				$ProjectSiteName = $hostUrlComponents[0]
				$hostUrl = $hostUrlComponents[1]
			}			
			
			$HostnameToLower = $hostUrl.ToLower()
			Write-Verbose "Set $HostnameToLower on $ProjectSiteName with $AuthenticationType authentication type"
			& $ScriptBaseFolderPath\Deploy\Tool-Module.ps1 -ToolName "seturl" -ToolParameters "site:$ProjectSiteName","url:$HostnameToLower","authenticationType:$AuthenticationType"
		}
		$script:Result = $LASTEXITCODE
	}
	catch {
		$script:Result = 1
	}
	
}

Function Step-DbBackup {
<#
	.SYNOPSIS
	Backup sql database
	.DESCRIPTION
	
	#>
	try {
		$DataSource=$GlobalSettings.DataBase.DataSource
		$InitialCatalog=$GlobalSettings.DataBase.InitialCatalog 
		$CurrentDateTime = Get-Date -format -yyyyMMdd-HHmm
		$BackupName = "$InitialCatalog" + $CurrentDateTime + ".bak"
		$DatabaseBackupsFolderPath = Get-FullPath $GlobalSettings.Sources.DatabasesPath
		& $ScriptBaseFolderPath\Ops\Backup-Db.ps1 -Server "$DataSource" -Catalog "$InitialCatalog" -FileName "$DatabaseBackupsFolderPath\$BackupName"
		$script:Result = $LASTEXITCODE
	}
	catch {
		$script:Result = 1
	}
	
}

Function Step-RestoreDb {
<#
	.SYNOPSIS
	Restore sql database
	.DESCRIPTION
	
	#>
	try {
		$DataSource=$GlobalSettings.DataBase.DataSource
		$InitialCatalog=$GlobalSettings.DataBase.InitialCatalog 
		$DatabaseBackupsFolderPath = Get-FullPath $GlobalSettings.Sources.DatabasesPath
		$DbBackupFilePath = Get-FullPath $GlobalSettings.Platform.DbBackupFilePath
		& $ScriptBaseFolderPath\Ops\Restore-Db.ps1 -ServerName "$DataSource" -CatalogName "$InitialCatalog" -FileName "$DbBackupFilePath"
		$script:Result = $LASTEXITCODE
	}
	catch {
		$script:Result = 1
	}
	
}

Function Step-SetConfigs {
<#
	.SYNOPSIS
	Set project configurations
	.DESCRIPTION
	
	#>
	# "LOGLEVEL:Console",
	try {
		$DataSource=$GlobalSettings.DataBase.DataSource
		# write-host $DataSource
		$InitialCatalog=$GlobalSettings.DataBase.InitialCatalog 
		# write-host $InitialCatalog
		$PackagePath = Get-FullPath "..\Packages\SetConfigs"
		# write-host $PackagePath
		# write-host "$ScriptBaseFolderPath\Deploy\Package-Module.ps1 -PackagePath $PackagePath -Parameters datasource:$DataSource initialcatalog:$InitialCatalog"
		& $ScriptBaseFolderPath\Deploy\Package-Module.ps1 -PackagePath "$PackagePath" -Parameters "datasource:$DataSource","initialcatalog:$InitialCatalog" 	
		$script:Result = $LASTEXITCODE
	}
	catch {
		$script:Result = 1
	}
}

Function Step-TestWebfolder {
<#
	.SYNOPSIS
	Unzip webfolder package
	.DESCRIPTION
	
	#>
	try {
		$SnWebFolderFilePath = Get-FullPath $GlobalSettings.Platform.SnWebFolderFilePath
		$ProjectWebFolderPath = Get-FullPath $GlobalSettings.Project.WebFolderPath
		Write-Verbose "SnWebfolderPackPath: $SnWebFolderFilePath"
		Write-Verbose "SnWebfolderDestName: $ProjectWebFolderPath"
		& $ScriptBaseFolderPath\Tools\Unzip-File.ps1 -filename "$SnWebFolderFilePath" -destname "$ProjectWebFolderPath"
		$script:Result = $LASTEXITCODE
	}
	catch {
		$script:Result = 1
	}
	
}


Function Step-GetSettings {
	<#
	.SYNOPSIS
	Get merged settings json
	.DESCRIPTION

	#>
	try {
		$script:JsonResult = $GlobalSettings 
		# | ConvertTo-Json
		$script:Result = 0
	}
	catch {
		$script:Result = 1
	}
}
