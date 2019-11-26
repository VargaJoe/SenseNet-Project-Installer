[CmdletBinding(SupportsShouldProcess=$True)]
Param(
[Parameter(Mandatory=$true)]
[string]$SnAdminPath,
[Parameter(Mandatory=$true)]
[string]$PackagePath, 
[Parameter(Mandatory=$false)]
[string[]]$Parameters
)

$Output = if ($ShowOutput -eq $True) {"Out-Default"} else {"Out-Null"} 
Write-Verbose "Starting: $SnAdminPath $PackagePath $Parameters"
& $SnAdminPath $PackagePath $Parameters | & $Output
Write-Verbose "Completed: $SnAdminPath $PackagePath $Parameters"

