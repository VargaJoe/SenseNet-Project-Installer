[CmdletBinding(SupportsShouldProcess=$True)]
Param(
[Parameter(Mandatory=$true)]
[string]$Name,
[Parameter(Mandatory=$true)]
[string]$DirectoryPath
)

Write-Host ================================================ -foregroundcolor "green"
Write-Host CREATE IIS SITE -foregroundcolor "green"
Write-Host ================================================ -foregroundcolor "green"

$scriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Definition
$root = Split-Path -Parent $scriptRoot

$DirectoryPath = [IO.Path]::GetFullPath($DirectoryPath)

Import-Module WebAdministration
$iisAppPoolName = $Name.ToLower()
$iisAppPoolDotNetVersion = "v4.0"
$iisAppName = $Name.ToLower()
$directoryPath = $DirectoryPath

$location = Get-Location
try
{
	#navigate to the app pools root
	cd IIS:\AppPools\

	#check if the app pool exists
	if (!(Test-Path $iisAppPoolName -pathType container))
	{
		#create the app pool
		$appPool = New-Item $iisAppPoolName
		$appPool | Set-ItemProperty -Name "managedRuntimeVersion" -Value $iisAppPoolDotNetVersion
	}

	#navigate to the sites root
	cd IIS:\Sites\

	#check if the site exists
	if (Test-Path $iisAppName -pathType container)
	{
		return
	}

	#create the site
	$iisApp = New-Item $iisAppName -bindings @{protocol="http";bindingInformation=":80:" + $iisAppName} -physicalPath $directoryPath
	$iisApp | Set-ItemProperty -Name "applicationPool" -Value $iisAppPoolName
}
finally
{
	Set-Location $location
}