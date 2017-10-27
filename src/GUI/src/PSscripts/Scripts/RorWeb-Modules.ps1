# ******************************************************************  Modules ******************************************************************
$AttribToolFilePath = "c:\Windows\System32\attrib.exe"

Function Module-UpdateProduct {
	<#
	.SYNOPSIS
	Update Product package
	.DESCRIPTION
	
	#>
	$CustomPackagePath = Get-FullPath "..\Packages\UpdateProduct"
	$CustomPackageBinPath = Get-FullPath "$CustomPackagePath\bin"
	
	if (Test-Path  ("$CustomPackageBinPath")){
		Write-Host "Remove write protection from package bin folder: $CustomPackageBinPath"
		& "$AttribToolFilePath" -r "$CustomPackageBinPath\*.*" /s
	}
	
	Write-Host Start install script: Update Product 	
	& .\Deploy\Package-Module.ps1 -PackagePath "$CustomPackagePath"
}

Function Module-Survey {
<#
	.SYNOPSIS
	Survey Demo package
	.DESCRIPTION
	
	#>
	$CustomPackagePath = Get-FullPath "..\Packages\SurveyEditor"
	$CustomPackageBinPath = Get-FullPath "$CustomPackagePath\bin"
	
	if (Test-Path  ("$CustomPackageBinPath")){
		Write-Host "Remove write protection from package bin folder: $CustomPackageBinPath"
		& "$AttribToolFilePath" -r "$CustomPackageBinPath\*.*" /s
	}

	Write-Host Start install script: Survey Demo	
	& .\Deploy\Package-Module.ps1 "$CustomPackagePath"
}

Function Module-ShortUrl {
<#
	.SYNOPSIS
	Share url package
	.DESCRIPTION
	
	#>
	$CustomPackagePath = Get-FullPath "..\Packages\ShortUrl"
	$CustomPackageBinPath = Get-FullPath "$CustomPackagePath\bin"
	
	if (Test-Path  ("$CustomPackageBinPath")){
		Write-Host "Remove write protection from package bin folder: $CustomPackageBinPath"
		& "$AttribToolFilePath" -r "$CustomPackageBinPath\*.*" /s
	}

	Write-Host Start install script: ShortUrl
	& .\Deploy\Package-Module.ps1 "$CustomPackagePath"
}

Function Module-PrInstall {
<#
	.SYNOPSIS
	Sample and test content package
	.DESCRIPTION
	
	#>
	$SnAdminToolName = "install-rorweb"	
	
	Write-Host Start install project: RorWeb
	& .\Deploy\Tool-Module.ps1 -ToolName $SnAdminToolName
}

Function Module-PrSample {
<#
	.SYNOPSIS
	Sample and test content package
	.DESCRIPTION
	
	#>
	$CustomPackagePath = Get-FullPath "..\Packages\RorWebSample"
	$CustomPackageBinPath = Get-FullPath "$CustomPackagePath\bin"
	
	if (Test-Path  ("$CustomPackageBinPath")){
		Write-Host "Remove write protection from package bin folder: $CustomPackageBinPath"
		& "$AttribToolFilePath" -r "$CustomPackageBinPath\*.*" /s
	}

	Write-Host Start install script: RorWebSample
	& .\Deploy\Package-Module.ps1 "$CustomPackagePath"
}
