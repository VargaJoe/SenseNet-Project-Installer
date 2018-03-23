[CmdletBinding(SupportsShouldProcess=$True)]
Param(
[Parameter(Mandatory=$true)]
[string]$SourcePath,
[Parameter(Mandatory=$false)]
[string[]]$ToolParameters = "target:/Root"
)

$Output = if ($ShowOutput -eq $True) {"Out-Default"} else {"Out-Null"}
$ProjectSnAdminFilePath = Get-FullPath $GlobalSettings.Project.SnAdminFilePath
Write-Verbose "Import will running: $ProjectSnAdminFilePath import source:$SourcePath $ToolParameters"

& $ProjectSnAdminFilePath import source:"$SourcePath" $ToolParameters | & $Output

Write-Verbose "Import was running: $ProjectSnAdminFilePath import source:$SourcePath $ToolParameters"
