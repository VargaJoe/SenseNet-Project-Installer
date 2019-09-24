[CmdletBinding(SupportsShouldProcess=$True)]
Param(
[Parameter(Mandatory=$true)]
[string]$ExporterPath,
[Parameter(Mandatory=$true)]
[string]$TargetPath,
[Parameter(Mandatory=$false)]
[string]$AsmFolderPath = "..\bin",
[Parameter(Mandatory=$false)]
[string]$ExportFromFilePath
)

$Output = if ($ShowOutput -eq $True) {"Out-Default"} else {"Out-Null"}

# filter logic must be implemented, for example if not full path then Queries subfolder must be used
# and have to think about parameter handle through run.ps1 script 
if($ExportFromFilePath)
{
	Write-Verbose "Export will be running: $ExporterPath -SOURCE /Root -TARGET $TargetPath -FILTER $filter"
	$filter = Get-Content $Exportfromfilepath
	& $ExporterPath -SOURCE "/Root" -TARGET "$TargetPath" -ASM "$AsmFolderPath" -FILTER "$filter" | & $Output
	Write-Verbose "Export will be running: $ExporterPath -SOURCE /Root -TARGET $TargetPath -FILTER $filter"
}
else{
	Write-Verbose "Export will be running: $ExporterPath export source:/Root target:$TargetPath" 
	& $ExporterPath -SOURCE "/Root" -TARGET "$TargetPath" -ASM "$AsmFolderPath"  | & $Output
	Write-Verbose "Export was running: $ExporterPath export source:/Root target:$TargetPath" 
}


