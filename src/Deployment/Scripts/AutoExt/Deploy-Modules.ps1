

# ******************************************************************  Modules ******************************************************************
Function Module-PrToProdAsm {
<#
	.SYNOPSIS
	Copy assemblies to production
	.DESCRIPTION
	
	#>
	try {
		$ProjectAsmFolderPackPath = Get-FullPath $ProjectSettings.Project.AsmFolderPath
		$ProductionAsmFolderPath = Get-FullPath $ProjectSettings.Production.AsmFolderPath
		Write-Verbose "Source: $ProjectAsmFolderPackPath"
		Write-Verbose "Target: $ProductionAsmFolderPath"
		Copy-Item -Path "$ProjectAsmFolderPackPath/*" -Destination "$ProductionAsmFolderPath" -recurse -Force
		$script:Result = $LASTEXITCODE
	}
	catch {
		$script:Result = 1
	}
	
}