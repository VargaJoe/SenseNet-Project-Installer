

# ******************************************************************  Steps ******************************************************************
Function Step-setcors {
	<#
		.SYNOPSIS
		set CORS policy in Portal.settings
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
			$PackagePath = Get-FullPath "$PackagesPath\CORS"
			& $ScriptBaseFolderPath\Deploy\Package-Module.ps1 -SnAdminPath "$SnAdminPath" -PackagePath "$PackagePath"
			$script:Result = $LASTEXITCODE
		}
		catch {
			$script:Result = 1
		}
	}
