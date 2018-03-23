[CmdletBinding(SupportsShouldProcess=$True)]
Param(
[Parameter(Mandatory=$true)]
[string]$ToolName,
[Parameter(Mandatory=$false)]
[string[]]$ToolParameters
)

$ProjectSnAdminFilePath = Get-FullPath $GlobalSettings.Project.SnAdminFilePath
$Output = if ($ShowOutput -eq $True) {"Out-Default"} else {"Out-Null"}

Write-Verbose "$ProjectSnAdminFilePath $ToolName $ToolParameters"
& $ProjectSnAdminFilePath $ToolName $ToolParameters | & $Output
