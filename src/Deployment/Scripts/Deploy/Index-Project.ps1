[CmdletBinding(SupportsShouldProcess=$True)]
Param(
[Parameter(Mandatory=$true)]
[string]$SnAdminPath
)

Write-Verbose "$SnAdminPath index"
& $SnAdminPath index
