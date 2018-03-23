[CmdletBinding(SupportsShouldProcess=$True)]
Param(
[Parameter(Mandatory=$true)]
[string]$PackagePath, 
[Parameter(Mandatory=$false)]
[string[]]$Parameters
)

$ProjectSnAdminFilePath = Get-FullPath $GlobalSettings.Project.SnAdminFilePath
write-host $ProjectSnAdminFilePath 
$Output = if ($ShowOutput -eq $True) {"Out-Default"} else {"Out-Null"}
write-host $Output 
Write-Verbose "$ProjectSnAdminFilePath $PackagePath $Parameters"
& $ProjectSnAdminFilePath $PackagePath $Parameters | & $Output


