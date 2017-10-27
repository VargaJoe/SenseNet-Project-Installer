[CmdletBinding(SupportsShouldProcess=$True)]
Param(
[Parameter(Mandatory=$true)]
[string]$ToolName,
[Parameter(Mandatory=$false)]
[string[]]$ToolParameters
)

$ProjectSnAdminFilePath = Get-FullPath $ProjectSettings.Project.SnAdminFilePath

Write-Host $ProjectSnAdminFilePath $ToolName $ToolParameters
& $ProjectSnAdminFilePath $ToolName $ToolParameters
