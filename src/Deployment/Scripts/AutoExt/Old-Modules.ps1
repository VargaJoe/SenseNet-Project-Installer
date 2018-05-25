# ******************************************************************  Steps ******************************************************************
Function Step-PrOldImport {
<#
	.SYNOPSIS
	Import project for sn 6.5 (before snadmin)
	.DESCRIPTION
	
	#>
		[CmdletBinding(SupportsShouldProcess=$True)]
	Param(
		[Parameter(Mandatory=$false)]
		[string]$Section="Project"
	)
	
	try {
		$ProjectRepoFsFolderPath = Get-FullPath $GlobalSettings.Project.RepoFsFolderPath
		$ImporterPath = Get-FullPath $GlobalSettings."$Section".ImporterPath
		$AsmFolderPath = Get-FullPath $GlobalSettings."$Section".AsmFolderPath		
		Write-Verbose "Start import script with the path: $ProjectRepoFsFolderPath"		
		& $ScriptBaseFolderPath\Old\Import-Module.ps1 -ImporterPath $ImporterPath -SourcePath "$ProjectRepoFsFolderPath" -AsmFolderPath "$AsmFolderPath"
		$script:Result = $LASTEXITCODE
	}
	catch {
		$script:Result = 1
	}
	
}

Function Step-PrOldExport {
<#
	.SYNOPSIS
	Export project for sn 6.5 (before snadmin)
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
		$ProjectRepoFsFolderPath = Get-FullPath $GlobalSettings.Project.RepoFsFolderPath
		$ExporterPath = Get-FullPath $GlobalSettings."$Section".ExporterPath
		$AsmFolderPath = Get-FullPath $GlobalSettings."$Section".AsmFolderPath	
		if (!($Exportfromfilepath)){
			Write-Verbose "Start export script"
			& $ScriptBaseFolderPath\Old\Export-Module.ps1 -ExporterPath $ExporterPath -TargetPath "$ProjectWebFolderPath\App_Data\Export$CurrentDateTime" -AsmFolderPath "$AsmFolderPath"
		}else{
			Write-Verbose "Start export script by filter: $Exportfromfilepath"
			& $ScriptBaseFolderPath\Old\Export-Module.ps1 -ExporterPath $ExporterPath -TargetPath "$ProjectWebFolderPath\App_Data\Export$CurrentDateTime" -AsmFolderPath "$AsmFolderPath" -ExportFromFilePath "$ExportFilter"
		}
		$script:Result = $LASTEXITCODE
	}
	catch {
		$script:Result = 1
	}
	
}


Function Step-PrOldIndex {
<#
	.SYNOPSIS
	Import project for sn 6.5 (beofre snadmin)
	.DESCRIPTION
	
	#>
		[CmdletBinding(SupportsShouldProcess=$True)]
	Param(
		[Parameter(Mandatory=$false)]
		[string]$Section="Project"
	)
	
	try {
		$IndexerPath = Get-FullPath $GlobalSettings."$Section".IndexerPath
		$AsmFolderPath = Get-FullPath $GlobalSettings."$Section".AsmFolderPath		
		& $ScriptBaseFolderPath\Old\Index-Module.ps1 -IndexerPath $IndexerPath -AsmFolderPath "$AsmFolderPath"
		$script:Result = $LASTEXITCODE
	}
	catch {
		$script:Result = 1
	}
	
}