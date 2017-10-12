[CmdletBinding(SupportsShouldProcess=$True)]
Param(
[Parameter(Mandatory=$true)]
[string]$PackagePath
)

#mode: export, import, stb
# schema???
$ProjectSnAdminFilePath = Get-FullPath $ProjectSettings.Project.SnAdminFilePath

Write-Host $ProjectSnAdminFilePath "$PackagePath"
& $ProjectSnAdminFilePath "$PackagePath"
