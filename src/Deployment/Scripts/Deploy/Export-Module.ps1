[CmdletBinding(SupportsShouldProcess=$True)]
Param(
[Parameter(Mandatory=$true)]
[string]$TargetPath,
[Parameter(Mandatory=$false)]
[string]$ExportFromFilePath 
)

$ProjectSnAdminFilePath = Get-FullPath $ProjectSettings.Project.SnAdminFilePath

Write-Host $ProjectSnAdminFilePath "$PackagePath"
& $ProjectSnAdminFilePath "$PackagePath"

# filter logic must be implemented, for example if not full path then Queries subfolder must be used
# and have to think about parameter handle through run.ps1 script 
if($ExportFromFilePath)
{
	#& $ExportExeFilePath -TARGET "$TargetPath" -SOURCE /Root -ASM $BinFolderPath -FILTER $ExportFromFilePath
	$filter = Get-Content $Exportfromfilepath
	& $ProjectSnAdminFilePath export source:"/Root" target:"$TargetPath" filter:"$filter"
	Write-Host Export was running: $ProjectSnAdminFilePath export source:"/Root" target:"$TargetPath" filter:"Queries/$filter"
}
else{
	#& $ExportExeFilePath -TARGET "$TargetPath" -SOURCE /Root -ASM $BinFolderPath 
	& $ProjectSnAdminFilePath export source:"/Root" target:"$TargetPath" 
	Write-Host Export was running: $ProjectSnAdminFilePath export source:"/Root" target:"$TargetPath" 
}


