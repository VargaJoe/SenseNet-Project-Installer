[CmdletBinding(SupportsShouldProcess=$True)]
Param(
[Parameter(Mandatory=$true)]
[string]$SourcePath,
[Parameter(Mandatory=$false)]
[string[]]$ToolParameters = "target:/Root"
)

$ProjectSnAdminFilePath = Get-FullPath $ProjectSettings.Project.SnAdminFilePath
Write-Host Import will running: $ProjectSnAdminFilePath import source:"$SourcePath" $ToolParameters

& $ProjectSnAdminFilePath import source:"$SourcePath" $ToolParameters

Write-Host Import was running: $ProjectSnAdminFilePath import source:"$SourcePath" $ToolParameters
