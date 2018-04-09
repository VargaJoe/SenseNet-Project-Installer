[CmdletBinding(SupportsShouldProcess=$True)]
Param(
[Parameter(Mandatory=$true)]
[string]$tfexepath,
[Parameter(Mandatory=$true)]
[string]$location
)

$tfexepath = [IO.Path]::GetFullPath($tfexepath)
$location = [IO.Path]::GetFullPath($location)
$Output = if ($ShowOutput) {'Out-Default'} else {'Out-Null'}

Write-Verbose "================================================"
Write-Verbose "====== TFS - GET Latest Version ================"
Write-Verbose "================================================"
Write-Verbose "Path: $location"
$modulename = $MyInvocation.MyCommand.Name

Try{
	& $tfexepath get $location /recursive
	exit 0
}	
Catch
{
	$ErrorMessage = $_.Exception.Message
	$functionname = $MyInvocation.MyCommand.Name
	Write-Verbose "[Error][$modulename : $functionname] => $ErrorMessage"
	exit 1
}
