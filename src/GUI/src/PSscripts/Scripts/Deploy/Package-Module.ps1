[CmdletBinding(SupportsShouldProcess=$True)]
Param(
[Parameter(Mandatory=$true)]
[string]$PackagePath
)

#mode: export, import, stb
# schema???
$ProjectSnAdminFilePath = Get-FullPath $ProjectSettings.Project.SnAdminFilePath
$Output = if ($ShowOutput -eq $True) {"Out-Default"} else {"Out-Null"}

Write-Verbose "$ProjectSnAdminFilePath $PackagePath"
& $ProjectSnAdminFilePath "$PackagePath" | & $Output
