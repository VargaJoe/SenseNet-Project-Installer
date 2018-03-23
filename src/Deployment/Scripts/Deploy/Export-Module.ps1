[CmdletBinding(SupportsShouldProcess=$True)]
Param(
[Parameter(Mandatory=$true)]
[string]$TargetPath,
[Parameter(Mandatory=$false)]
[string]$ExportFromFilePath 
)

$ProjectSnAdminFilePath = Get-FullPath $GlobalSettings.Project.SnAdminFilePath
$Output = if ($ShowOutput -eq $True) {"Out-Default"} else {"Out-Null"}

Write-Verbose "$ProjectSnAdminFilePath $PackagePath"
& $ProjectSnAdminFilePath "$PackagePath"

# filter logic must be implemented, for example if not full path then Queries subfolder must be used
# and have to think about parameter handle through run.ps1 script 
if($ExportFromFilePath)
{
	$filter = Get-Content $Exportfromfilepath
	& $ProjectSnAdminFilePath export source:"/Root" target:"$TargetPath" filter:"$filter" | & $Output
	Write-Verbose "Export was running: $ProjectSnAdminFilePath export source:/Root target:$TargetPath filter:Queries/$filter"
}
else{
	& $ProjectSnAdminFilePath export source:"/Root" target:"$TargetPath" | & $Output
	Write-Verbose "Export was running: $ProjectSnAdminFilePath export source:/Root target:$TargetPath" 
}


