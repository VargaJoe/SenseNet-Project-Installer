[CmdletBinding(SupportsShouldProcess=$True)]
Param(
[Parameter(Mandatory=$true)]
[string]$SnAdminPath,
[Parameter(Mandatory=$true)]
[string]$ToolName,
[Parameter(Mandatory=$false)]
[string[]]$ToolParameters
)

$Output = if ($ShowOutput -eq $True) {"Out-Default"} else {"Out-Null"}

Write-Verbose "$SnAdminPath $ToolName $ToolParameters"
& $SnAdminPath $ToolName $ToolParameters | & $Output
