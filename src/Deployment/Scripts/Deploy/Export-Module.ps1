[CmdletBinding(SupportsShouldProcess=$True)]
Param(
[Parameter(Mandatory=$true)]
[string]$SnAdminPath,
[Parameter(Mandatory=$true)]
[string]$TargetPath,
[Parameter(Mandatory=$false)]
[string]$ExportFromFilePath
)

$Output = if ($ShowOutput -eq $True) {"Out-Default"} else {"Out-Null"}

# filter logic must be implemented, for example if not full path then Queries subfolder must be used
# and have to think about parameter handle through run.ps1 script 
if($ExportFromFilePath)
{
	Write-Verbose "Export will be running: $SnAdminPath export source:/Root target:$TargetPath filter:Queries/$filter"
	$filter = Get-Content $Exportfromfilepath
	& $SnAdminPath export source:"/Root" target:"$TargetPath" filter:"$filter" | & $Output
	Write-Verbose "Export was running: $SnAdminPath export source:/Root target:$TargetPath filter:Queries/$filter"
}
else{
	Write-Verbose "Export will be running: $SnAdminPath export source:/Root target:$TargetPath" 
	& $SnAdminPath export source:"/Root" target:"$TargetPath" | & $Output
	Write-Verbose "Export was running: $SnAdminPath export source:/Root target:$TargetPath" 
}


