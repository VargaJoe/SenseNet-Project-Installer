# ******************************************************************  Steps ******************************************************************

Function Step-CallConsoleInstaller {
	<#
	.SYNOPSIS
	Simple console install caller
	.DESCRIPTION
	
	#>
	[CmdletBinding(SupportsShouldProcess=$True)]
	Param(
		[Parameter(Mandatory=$false)]
		[string]$Section="Project"
	)
	
	$LASTEXITCODE = 0
	try {
		$InstallerPath = Get-FullPath $GlobalSettings."$Section".InstallerFilePath
		$parentPath = $InstallerPath | split-path -parent
		$appName = $InstallerPath | split-path -leaf	
		Write-Output "working directory: $parentPath"
		Write-Output "console app: $appName"
		Start-Process -FilePath $InstallerPath -WorkingDirectory $parentPath -NoNewWindow 
		$script:Result = $LASTEXITCODE
	}
	catch {
		Write-Output "Error: $_.Exception"
		$script:Result = 1
	}
}

Function Step-SetJsonConnection {
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
		$aConfigFilePath = Get-FullPath $GlobalSettings."$Section".InstallerCfgFilePath
		$wConfigFilePath = Get-FullPath $GlobalSettings."$Section".AppConfigFilePath
		$DataSource=$GlobalSettings."$Section".DataSource
		$InitialCatalog=$GlobalSettings."$Section".InitialCatalog 
		& $ScriptBaseFolderPath\Deploy\Set-JsonConnection.ps1 -ConfigFilePath "$aConfigFilePath" -DataSource "$DataSource" -InitialCatalog "$InitialCatalog" 
		& $ScriptBaseFolderPath\Deploy\Set-JsonConnection.ps1 -ConfigFilePath "$wConfigFilePath" -DataSource "$DataSource" -InitialCatalog "$InitialCatalog" 
		$script:Result = $LASTEXITCODE
	}
	catch {
		$script:Result = 1
	}
}