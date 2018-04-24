

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
	[CmdletBinding(SupportsShouldProcess=$True)]
	Param(
		[parameter(Mandatory=$false)]
		[String]$section="Project"
	)
		
	try {		
		$Output = if ($ShowOutput -eq $True) {"Out-Default"} else {"Out-Null"}
		$ProjectSiteName = $GlobalSettings."$section".WebAppName
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
	[CmdletBinding(SupportsShouldProcess=$True)]
		Param(
		[Parameter(Mandatory=$false)]
		[string]$Section="Project"
		)
	
	try {
		$ProjectSiteName = $GlobalSettings."$Section".WebAppName
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
	
	[CmdletBinding(SupportsShouldProcess=$True)]
	Param(
		[Parameter(Mandatory=$false)]
		[string]$Section="Project"
	)
	
	try {
		$Output = if ($ShowOutput -eq $True) {"Out-Default"} else {"Out-Null"}
	
		$ProjectWebConfigFilePath = Get-FullPath $GlobalSettings."$Section".WebConfigFilePath
		if (Test-Path  ("$ProjectWebConfigFilePath")){
			Write-Verbose "Remove write protection from web.config: $ProjectWebConfigFilePath"
			Set-ItemProperty $ProjectWebConfigFilePath -Name IsReadOnly -Value $false
		}
		$ProjectToolsFolderPath = Get-FullPath $GlobalSettings."$Section".ToolsFolderPath
		if (Test-Path  ("$ProjectToolsFolderPath")){
			Write-Verbose "Remove write protection from files under Tools folder: $ProjectToolsFolderPath"
			& "c:\Windows\System32\attrib.exe" -r "$ProjectToolsFolderPath\*.*" /s | & $Output
		}
		
		$DataSource=$GlobalSettings."$Section".DataSource
		$InitialCatalog=$GlobalSettings."$Section".InitialCatalog 
		$SnAdminPath = Get-FullPath $GlobalSettings."$Section".SnAdminFilePath
		& $ScriptBaseFolderPath\Deploy\Tool-Module.ps1 -SnAdminPath $SnAdminPath -ToolName "install-services" -ToolParameters "datasource:$DataSource","initialcatalog:$InitialCatalog","FORCEDREINSTALL:true" 
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
	[CmdletBinding(SupportsShouldProcess=$True)]
	Param(
		[Parameter(Mandatory=$false)]
		[string]$Section="Project"
	)
	
	try {
		$SnAdminPath = Get-FullPath $GlobalSettings."$Section".SnAdminFilePath
		& $ScriptBaseFolderPath\Deploy\Tool-Module.ps1 -SnAdminPath $SnAdminPath -ToolName "install-webpages" 
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
	[CmdletBinding(SupportsShouldProcess=$True)]
	Param(
		[Parameter(Mandatory=$false)]
		[string]$Section="Project"
	)
	
	try {
		$PackagesPath = Get-FullPath $GlobalSettings.Source.PackagesPath
		$SnAdminPath = Get-FullPath $GlobalSettings."$Section".SnAdminFilePath
		$PackagePath = Get-FullPath "$PackagesPath\RemoveDemo"
		& $ScriptBaseFolderPath\Deploy\Package-Module.ps1 -SnAdminPath "$SnAdminPath" -PackagePath "$PackagePath"
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
	[CmdletBinding(SupportsShouldProcess=$True)]
	Param(
		[Parameter(Mandatory=$false)]
		[string]$Section="Project"
	)
	
	try {
		$PackagesPath = Get-FullPath $GlobalSettings.Source.PackagesPath
		$SnAdminPath = Get-FullPath $GlobalSettings."$Section".SnAdminFilePath
		$PackagePath = Get-FullPath "$PackagesPath\UsersStructure"
		& $ScriptBaseFolderPath\Deploy\Package-Module.ps1 -SnAdminPath "$SnAdminPath" -PackagePath "$PackagePath"
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
	[CmdletBinding(SupportsShouldProcess=$True)]
	Param(
		[Parameter(Mandatory=$false)]
		[string]$Section="Project"
	)
	
	try {
		$SnAdminPath = Get-FullPath $GlobalSettings."$Section".SnAdminFilePath
		$PackagePath =  Get-FullPath $GlobalSettings.Project.DeployFolderPath
		& $ScriptBaseFolderPath\Deploy\Package-Module.ps1 -SnAdminPath "$SnAdminPath" -PackagePath "$PackagePath"	
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
	[CmdletBinding(SupportsShouldProcess=$True)]
		Param(
		[Parameter(Mandatory=$false)]
		[string]$Section="Project"
		)
	
	try {
		$ProjectWebFolderPath = Get-FullPath $GlobalSettings."$Section".WebFolderPath
		$ProjectSiteName = $GlobalSettings."$Section".WebAppName 
		$ProjectAppPoolName = $GlobalSettings."$Section".AppPoolName 
		$ProjectSiteHosts = $GlobalSettings."$Section".Hosts
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
	[CmdletBinding(SupportsShouldProcess=$True)]
		Param(
		[Parameter(Mandatory=$false)]
		[string]$Section="Project"
		)
	
	try {
		$ProjectSiteHosts = $GlobalSettings."$Section".Hosts
		& $ScriptBaseFolderPath\Ops\Set-Host.ps1 -SiteHosts $ProjectSiteHosts
		$script:Result = $LASTEXITCODE
	}
	catch {
		$script:Result = 1
	}
	
}

Function Step-DeployWebFolder {
<#
	.SYNOPSIS
	Copy starter webfolder to detination / untested
	.DESCRIPTION
	
	#>
	[CmdletBinding(SupportsShouldProcess=$True)]
		Param(
		[Parameter(Mandatory=$false)]
		[string]$Section="Production"
		)
	
	try {
		Write-Verbose "`r`nCopy webfolder files from package to destination"
		$SnWebfolderPackPath = Get-FullPath $GlobalSettings.Source.SnWebFolderFilePath
		$ProjectWebFolderPath = Get-FullPath $GlobalSettings."$Section".WebFolderPath
		Write-Verbose "Source: $SnWebfolderPackPath"
		Write-Verbose "Target: $ProjectWebFolderPath"
		& $ScriptBaseFolderPath\Tools\Unzip-File.ps1 -filename "$SnWebfolderPackPath" -destname "$ProjectWebFolderPath"
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
	[CmdletBinding(SupportsShouldProcess=$True)]
		Param(
		[Parameter(Mandatory=$false)]
		[string]$Section="Project"
		)
		
	try {
		$SnAdminPath = Get-FullPath $GlobalSettings."$Section".SnAdminFilePath
		& $ScriptBaseFolderPath\Deploy\Index-Project.ps1 -SnAdminPath $SnAdminPath
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
		$SnAdminPath = Get-FullPath $GlobalSettings."$Section".SnAdminFilePath
		Write-Verbose "Start import script with the path: $ProjectRepoFsFolderPath"		
		& $ScriptBaseFolderPath\Deploy\Import-Module.ps1 -SnAdminPath $SnAdminPath -SourcePath "$ProjectRepoFsFolderPath"
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
		$CurrentDateTime = Get-Date -format [yyyy-MM-dd-HH-mm-ss]
		$ProjectWebFolderPath = Get-FullPath $GlobalSettings."$Section".WebFolderPath
		$SnAdminPath = Get-FullPath $GlobalSettings."$Section".SnAdminFilePath
		if (!($Exportfromfilepath)){
			Write-Verbose "Start export script"
			& $ScriptBaseFolderPath\Deploy\Export-Module.ps1 -SnAdminPath $SnAdminPath -TargetPath "$ProjectWebFolderPath\App_Data\Export$CurrentDateTime"
		}else{
			Write-Verbose "Start export script by filter: $Exportfromfilepath"
			& $ScriptBaseFolderPath\Deploy\Export-Module.ps1 -SnAdminPath $SnAdminPath -TargetPath "$ProjectWebFolderPath\App_Data\Export$CurrentDateTime" -ExportFromFilePath "$ExportFilter"
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
	[CmdletBinding(SupportsShouldProcess=$True)]
		Param(
		[Parameter(Mandatory=$false)]
		[string]$Section="Project"
		)
		
	# Technical Debt: it should be called an independent ps1 file from here, instead a hardcoded business logic
	try {
		# Site name, url and authentication type must be get from settings json, probably with iteration
		$ProjectSiteHosts = $GlobalSettings."$Section".Hosts
		# $ProjectSiteName = $GlobalSettings.IIS.WebAppName
		$AuthenticationType="Forms"
		$SnAdminPath = Get-FullPath $GlobalSettings."$Section".SnAdminFilePath
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
			& $ScriptBaseFolderPath\Deploy\Tool-Module.ps1 -SnAdminPath $SnAdminPath -ToolName "seturl" -ToolParameters "site:$ProjectSiteName","url:$HostnameToLower","authenticationType:$AuthenticationType"
		}
		$script:Result = $LASTEXITCODE
	}
	catch {
		$script:Result = 1
	}
	
}

Function Step-BackupDb {
<#
	.SYNOPSIS
	Backup sql database
	.DESCRIPTION
	
	#>
	[CmdletBinding(SupportsShouldProcess=$True)]
		Param(
		[Parameter(Mandatory=$false)]
		[string]$Section="Project"
		)
		
	try {
		$DataSource=$GlobalSettings."$Section".DataSource
		$InitialCatalog=$GlobalSettings."$Section".InitialCatalog 
		$DbBackupFilePath = Get-FullPath $GlobalSettings.Source.DbBackupFilePath
		& $ScriptBaseFolderPath\Ops\Backup-Db.ps1 -ServerName "$DataSource" -CatalogName "$InitialCatalog" -FileName "$DbBackupFilePath"
		$script:Result = $LASTEXITCODE
	}
	catch {
		$script:Result = 1
	}
	
}

Function Step-AutoBackupDb {
<#
	.SYNOPSIS
	Backup sql database
	.DESCRIPTION
	
	#>
	[CmdletBinding(SupportsShouldProcess=$True)]
		Param(
		[Parameter(Mandatory=$false)]
		[string]$Section="Project"
		)
		
	try {
		$DataSource=$GlobalSettings."$Section".DataSource
		$InitialCatalog=$GlobalSettings."$Section".InitialCatalog 
		$CurrentDateTime = Get-Date -format -yyyyMMddHHmm
		$BackupName = "$InitialCatalog" + $CurrentDateTime + ".bak"
		$DatabaseBackupsFolderPath = Get-FullPath $GlobalSettings.Source.DatabasesPath
		& $ScriptBaseFolderPath\Ops\Backup-Db.ps1 -ServerName "$DataSource" -CatalogName "$InitialCatalog" -FileName "$DatabaseBackupsFolderPath\$BackupName"
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
	[CmdletBinding(SupportsShouldProcess=$True)]
		Param(
		[Parameter(Mandatory=$false)]
		[string]$Section="DataBase"
		)
		
	try {
		$DataSource=$GlobalSettings."$Section".DataSource
		$InitialCatalog=$GlobalSettings."$Section".InitialCatalog 
		$DbBackupFilePath = Get-FullPath $GlobalSettings.Source.DbBackupFilePath
		& $ScriptBaseFolderPath\Ops\Restore-Db.ps1 -ServerName "$DataSource" -CatalogName "$InitialCatalog" -FileName "$DbBackupFilePath"
		$script:Result = $LASTEXITCODE
	}
	catch {
		$script:Result = 1
	}
	
}

Function Step-DropDb {
<#
	.SYNOPSIS
	Drop sql database
	.DESCRIPTION
	
	#>
	[CmdletBinding(SupportsShouldProcess=$True)]
		Param(
		[Parameter(Mandatory=$false)]
		[string]$Section="Project"
		)
		
	try {
		$DataSource=$GlobalSettings."$Section".DataSource
		$InitialCatalog=$GlobalSettings."$Section".InitialCatalog 
		& $ScriptBaseFolderPath\Ops\Drop-Db.ps1 -ServerName "$DataSource" -CatalogName "$InitialCatalog" 
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
	[CmdletBinding(SupportsShouldProcess=$True)]
		Param(
		[Parameter(Mandatory=$false)]
		[string]$Section="Project"
		)
	
	# "LOGLEVEL:Console",
	try {
		$PackagesPath = Get-FullPath $GlobalSettings.Source.PackagesPath
		$DataSource=$GlobalSettings."$Section".DataSource
		$InitialCatalog=$GlobalSettings."$Section".InitialCatalog 
		$PackagePath = Get-FullPath "$PackagesPath\SetConfigs"
		$SnAdminPath = Get-FullPath $GlobalSettings."$Section".SnAdminFilePath
		& $ScriptBaseFolderPath\Deploy\Package-Module.ps1 -SnAdminPath $SnAdminPath -PackagePath "$PackagePath" -Parameters "datasource:$DataSource","initialcatalog:$InitialCatalog" 	
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

Function Step-SetConnection {
<#
	.SYNOPSIS
	Set project configurations
	.DESCRIPTION
	
	#>
	[CmdletBinding(SupportsShouldProcess=$True)]
		Param(
		[Parameter(Mandatory=$false)]
		[string]$Section="Project"
		)
	
	try {
		$aConfigFilePath = Get-FullPath $GlobalSettings."$Section".SnAdminRCFilePath
		$wConfigFilePath = Get-FullPath $GlobalSettings."$Section".WebConfigFilePath
		$DataSource=$GlobalSettings."$Section".DataSource
		$InitialCatalog=$GlobalSettings."$Section".InitialCatalog 
		& $ScriptBaseFolderPath\Deploy\Set-Connection.ps1 -ConfigFilePath "$aConfigFilePath" -DataSource "$DataSource" -InitialCatalog "$InitialCatalog" 
		& $ScriptBaseFolderPath\Deploy\Set-Connection.ps1 -ConfigFilePath "$wConfigFilePath" -DataSource "$DataSource" -InitialCatalog "$InitialCatalog" 
		$script:Result = $LASTEXITCODE
	}
	catch {
		$script:Result = 1
	}
}