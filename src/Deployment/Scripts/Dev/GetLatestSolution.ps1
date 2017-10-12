[CmdletBinding(SupportsShouldProcess=$True)]
Param(
[Parameter(Mandatory=$true)]
[string]$tfexepath,
[Parameter(Mandatory=$true)]
[string]$location
)

$tfexepath = [IO.Path]::GetFullPath($tfexepath)
$location = [IO.Path]::GetFullPath($location)

Write-Host ================================================ -foregroundcolor "green"
Write-Host ====== TFS - GET Latest Version ================ -foregroundcolor "green"
Write-Host ================================================ -foregroundcolor "green"
Write-Host Path: $location
$modulename = $MyInvocation.MyCommand.Name

Function Get-LatestVersion() { 
	Try{
		$GetLatest = & $tfexepath get $location /recursive
		Write-Host "Result:"$GetLatest
		exit 0
	}	
	Catch
	{
		$ErrorMessage = $_.Exception.Message
		$functionname = $MyInvocation.MyCommand.Name
		Write-Host "[Error][$modulename : $functionname] => "$ErrorMessage
		exit 1
	}
}
Get-LatestVersion