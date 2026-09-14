# ******************************************************************  Steps ******************************************************************

# set example
# [System.Environment]::SetEnvironmentVariable('PLOTMANAGER_DataSource','testing')

Function Step-MergeEnvironmentSettings {
	<#
		.SYNOPSIS
		Merge environment settings to global settings
		.DESCRIPTION

		#>
	[CmdletBinding(SupportsShouldProcess = $True)]
	Param(
		[Parameter(Mandatory = $false)]
		[string]$Section = "Project"
	)

	Write-Output "environmentalism"
	try {

		Get-ChildItem env:PLOTMANAGER_* | ForEach-Object {
			$settingName=$_.Name.Substring(12)
			$settingValue=$_.Value
			Write-Output "Process $($settingName)... "
			if ($null -ne $GlobalSettings."$Section" -and $GlobalSettings."$Section".PSObject.Properties.Match($settingName).Count -gt 0) {
				$GlobalSettings."$Section"."$settingName"=$settingValue
			} else {
				Write-Output "setting does not exists"
			}
		}

		$script:Result = $LASTEXITCODE
	}
	catch {
		$script:Result = 1
	}
}
