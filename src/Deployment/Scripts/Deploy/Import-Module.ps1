[CmdletBinding(SupportsShouldProcess=$True)]
Param(
[Parameter(Mandatory=$true)]
[string]$SnAdminPath,
[Parameter(Mandatory=$true)]
[string]$SourcePath,
[Parameter(Mandatory=$false)]
[string[]]$ToolParameters = "target:/Root"
)

$Output = if ($ShowOutput -eq $True) {"Out-Default"} else {"Out-Null"}

Write-Verbose "Import will running: $SnAdminPath import source:$SourcePath $ToolParameters"

& $SnAdminPath import source:"$SourcePath" $ToolParameters | & $Output

Write-Verbose "Import was running: $SnAdminPath import source:$SourcePath $ToolParameters"
