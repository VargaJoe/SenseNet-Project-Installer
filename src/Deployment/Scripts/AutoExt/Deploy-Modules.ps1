# ******************************************************************  Steps ******************************************************************

# Meg kell:
# - admin bin deploy
# - admin tools deploy 
# - tools deploy + config

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