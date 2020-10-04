# ******************************************************************  Steps ******************************************************************

# Meg kell:
# - admin bin deploy
# - admin tools deploy 
# - tools deploy + config

#============================================ snadmin operations ==================================================
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

Function Step-PrImport {
<#
	.SYNOPSIS
	Import project - not refactored
	.DESCRIPTION
	
	#>
		[CmdletBinding(SupportsShouldProcess=$True)]
	Param(
		[Parameter(Mandatory=$false)]
		[string]$Section="Project"
	)
	
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

#============================================ configurations ==================================================

Function Step-SetInstallerConnection {
	<#
	.SYNOPSIS
	temp Set installer json configurations
	.DESCRIPTION
	
	#>
	[CmdletBinding(SupportsShouldProcess=$True)]
	Param(
		[Parameter(Mandatory=$false)]
		[string]$Section="Project"
		)
	
	try {
		$instConfigFilePath = Get-FullPath $GlobalSettings."$Section".InstallerCfgFilePath
		$DataSource=$GlobalSettings."$Section".DataSource
		$InitialCatalog=$GlobalSettings."$Section".InitialCatalog 
		$UserName = $GlobalSettings."$Section".UserName
		$UserPsw = $GlobalSettings."$Section".UserPsw		
		
		Write-Verbose "installer config: $instConfigFilePath"
		& $ScriptBaseFolderPath\Deploy\Set-JsonConnection.ps1 -ConfigFilePath "$instConfigFilePath" -DataSource "$DataSource" -InitialCatalog "$InitialCatalog" -UserName $UserName -UserPsw $UserPsw
		$script:Result = $LASTEXITCODE
	}
	catch {
		$script:Result = 1
	}
}

Function Step-SetJsonPackages {
	<#
	.SYNOPSIS
	Set isntall packages with installer json configurations
	.DESCRIPTION
	
	#>
	[CmdletBinding(SupportsShouldProcess=$True)]
	Param(
		[Parameter(Mandatory=$false)]
		[string]$Section="Project"
		)

	try {
		$instConfigFilePath = Get-FullPath $GlobalSettings."$Section".InstallerCfgFilePath
		[string[]]$Packages=$GlobalSettings."$Section".InstallPackages
		
		Write-Verbose "installer config: $instConfigFilePath"
		& $ScriptBaseFolderPath\Deploy\Set-Packages-Json.ps1 -ConfigFilePath "$instConfigFilePath" -Packages $Packages -nodeName "packages"
		$script:Result = $LASTEXITCODE
	}
	catch {
		$script:Result = 1
	}
}

Function Step-SetJsonImports {
	<#
	.SYNOPSIS
	Set import packages with installer json configurations
	.DESCRIPTION
	
	#>
	[CmdletBinding(SupportsShouldProcess=$True)]
	Param(
		[Parameter(Mandatory=$false)]
		[string]$Section="Project"
		)

	try {
		$instConfigFilePath = Get-FullPath $GlobalSettings."$Section".InstallerCfgFilePath
		[string[]]$Packages=$GlobalSettings."$Section".ImportPackages
		Write-Output "importer config: $instConfigFilePath"
		& $ScriptBaseFolderPath\Deploy\Set-Packages-Json.ps1 -ConfigFilePath "$instConfigFilePath" -Packages $Packages -nodeName "import"
		$script:Result = $LASTEXITCODE
	}
	catch {
		$script:Result = 1
	}
}

#============================================ file operations ==================================================
Function Step-PrAsmDeploy {
<#
	.SYNOPSIS
	Copy assemblies to production
	.DESCRIPTION
	
	#>
	[CmdletBinding(SupportsShouldProcess=$True)]
		Param(
		[Parameter(Mandatory=$false)]
		[string]$Section="Production"
		)
	
	try {
		$ProjectAsmFolderPackPath = Get-FullPath $GlobalSettings.Project.AsmFolderPath
		$ProductionAsmFolderPath = Get-FullPath $GlobalSettings."$Section".AsmFolderPath
		Write-Verbose "Source: $ProjectAsmFolderPackPath"
		Write-Verbose "Target: $ProductionAsmFolderPath"
		Copy-Item -Path "$ProjectAsmFolderPackPath/*" -Destination "$ProductionAsmFolderPath" -recurse -Force
		$script:Result = $LASTEXITCODE
	}
	catch {
		$script:Result = 1
	}	
}

Function Step-PrLucDeploy {
<#
	.SYNOPSIS
	Copy lucene to production 
	.DESCRIPTION
	
	#>
	[CmdletBinding(SupportsShouldProcess=$True)]
		Param(
		[Parameter(Mandatory=$false)]
		[string]$Section="DemoSiteNlb2"
		)
	
	try {
		$ProjectLucFolderPackPath = Get-FullPath $GlobalSettings.Project.LucFolderPath
		$ProductionLucFolderPath = Get-FullPath $GlobalSettings."$Section".LucFolderPath
		Write-Verbose "Source: $ProjectLucFolderPackPath"
		Write-Verbose "Target: $ProductionLucFolderPath"
		Write-Verbose "Remove old files from $ProductionLucFolderPath/* has been started..."
		Remove-Item -Path "$ProductionLucFolderPath/*" -Recurse  
		Write-Verbose "...and now copy files..."
		Copy-Item -Path "$ProjectLucFolderPackPath/*" -Destination "$ProductionLucFolderPath" -Recurse -Force 
		Write-Verbose "Done!"		
		$script:Result = $LASTEXITCODE
	}
	catch {
		$script:Result = 1
	}	
}

Function Step-CleanWebFolder {
	<#
	.SYNOPSIS
	Clean webfolder
	.DESCRIPTION
	Remove all folders and files under webfolder, except app_offline.htm
	#>
	[CmdletBinding(SupportsShouldProcess=$True)]
		Param(
		[Parameter(Mandatory=$false)]
		[string]$Section="Project"
		)
	
	try {
		Write-Output "`r`nCleanup web folder"
		$ProjectWebFolderPath = Get-FullPath $GlobalSettings."$Section".WebFolderPath
		Write-Output "Target: $ProjectWebFolderPath"		
		
		Remove-Item "$($ProjectWebFolderPath)\*" -Recurse -Exclude "app_offline*.htm" -Force -ErrorAction "SilentlyContinue"
		$script:Result = $LASTEXITCODE		
	}
	catch {
		Write-Output "`tSomething went wrong: $_"
		$script:Result = 1
	}	
}

Function Step-CleanWebFolderWOIndex {
	<#
	.SYNOPSIS
	Clean webfolder without index
	.DESCRIPTION
	Remove all folders and files under webfolder, except app_offline.htm
	#>
	[CmdletBinding(SupportsShouldProcess=$True)]
		Param(
		[Parameter(Mandatory=$false)]
		[string]$Section="Project"
		)
	
	try {
		Write-Output "`r`nCleanup web folder"
		$ProjectWebFolderPath = Get-FullPath $GlobalSettings."$Section".WebFolderPath
		Write-Output "Target: $ProjectWebFolderPath"		
		
		Remove-Item "$($ProjectWebFolderPath)\*" -Recurse -Exclude "app_offline*.htm","LocalIndex" -Force -ErrorAction "SilentlyContinue"
		$script:Result = $LASTEXITCODE		
	}
	catch {
		Write-Output "`tSomething went wrong: $_"
		$script:Result = 1
	}	
}

Function Step-CreateWebFolder {
	<#
	.SYNOPSIS
	Create webfolder on destination if not exists
	.DESCRIPTION
	
	#>
	[CmdletBinding(SupportsShouldProcess=$True)]
		Param(
		[Parameter(Mandatory=$false)]
		[string]$Section="Project"
		)
	
	try {
		Write-Output "`r`nCopy webfolder files from package to destination"
		$ProjectWebFolderPath = Get-FullPath $GlobalSettings."$Section".WebFolderPath
		Write-Output "Target: $ProjectWebFolderPath"		
		
		if (-not(Test-Path $ProjectWebFolderPath)) {
			$parentPath = $ProjectWebFolderPath | split-path -parent
			$folderName = $ProjectWebFolderPath | split-path -leaf		
			Write-Output "Create target webfolder"
			Write-Output "`twith name: $folderName"
			Write-Output "`tunder: $parentPath"
			New-Item -Path "$parentPath" -Name "$folderName" -ItemType "directory"
		}	
		
		$script:Result = 0
	}
	catch {
		Write-Output "`tSomething went wrong: $_"
		$script:Result = 1
	}	
}

Function Step-DeployWebFolder {
	<#
	.SYNOPSIS
	Copy starter webfolder to destination from template
	.DESCRIPTION
	
	#>
	[CmdletBinding(SupportsShouldProcess=$True)]
		Param(
		[Parameter(Mandatory=$false)]
		[string]$Section="Project"
		)
	
	try {
		Write-Output "`r`nCopy webfolder files from package to destination"
		
		if ($GlobalSettings."$Section".TemplateWebFolderPath) {
			$TemplateWebfolderPath = Get-FullPath $GlobalSettings."$Section".TemplateWebFolderPath
		} else {
			$TemplateWebfolderPath = Get-FullPath $GlobalSettings.Source.TemplateWebFolderPath
		}
		$ProjectWebFolderPath = Get-FullPath $GlobalSettings."$Section".WebFolderPath
		Write-Output "Source: $TemplateWebfolderPath"
		Write-Output "Target: $ProjectWebFolderPath"		
		
		if (-not(Test-Path $ProjectWebFolderPath)) {
			$parentPath = $ProjectWebFolderPath | split-path -parent
			$folderName = $ProjectWebFolderPath | split-path -leaf		
			Write-Output "Create target webfolder"
			Write-Output "`twith name: $folderName"
			Write-Output "`tunder: $parentPath"
			New-Item -Path "$parentPath" -Name "$folderName" -ItemType "directory"
		}	
		
		Copy-Item -Path "$TemplateWebfolderPath/*" -Destination "$ProjectWebFolderPath" -recurse -Force
		$script:Result = 0
	}
	catch {
		Write-Output "`tSomething went wrong: $_"
		$script:Result = 1
	}	
}

Function Step-DeployWebFolderFromZip {
<#
	.SYNOPSIS
	Copy starter webfolder to detination / untested
	.DESCRIPTION
	
	#>
	[CmdletBinding(SupportsShouldProcess=$True)]
		Param(
		[Parameter(Mandatory=$false)]
		[string]$Section="Project"
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

#============================================ database operations ==================================================
Function Step-SetHostPermissionOnDb {
	<#
		.SYNOPSIS
		Set host permission on DB
		.DESCRIPTION
		Sites running with host machine user as application pool identity have to have permission to site database. This step will grant it.

		#>
		[CmdletBinding(SupportsShouldProcess=$True)]
		Param(
			[Parameter(Mandatory=$false)]
			[string]$Section="Project"
		)
		
		try {
			$DataSource = $GlobalSettings."$Section".DataSource
			$InitialCatalog = $GlobalSettings."$Section".InitialCatalog 
			$WebServer = $GlobalSettings."$Section".MachineName
			
			Write-Verbose "Start import script with the path: $ProjectRepoFsFolderPath"		
			& $ScriptBaseFolderPath\Ops\Grant-Permission.ps1 -DataSource "$DataSource" -Catalog "$InitialCatalog" -User "SN\$($WebServer)$"  -Verbose
			$script:Result = $LASTEXITCODE
		}
		catch {
			$script:Result = 1
		}	
	}

