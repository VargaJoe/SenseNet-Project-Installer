[CmdletBinding(SupportsShouldProcess=$True)]
Param(
[Parameter(Mandatory=$true)]
[string]$WebFolderPath,
[Parameter(Mandatory=$true)]
[string]$TargetPath,
[Parameter(Mandatory=$false)]
[string]$ExportFromFilePath 
)

$ScriptBaseFolderPath = Split-Path -Parent $MyInvocation.MyCommand.Path
$Initfunctions = [IO.Path]::Combine($ScriptBaseFolderPath, "init-functions.ps1") 

Write-Host Helper functions initialization from $Initfunctions
. $Initfunctions

$WebFolderPath = [IO.Path]::GetFullPath($WebFolderPath)
Write-host WebFolder combine: $WebFolderPath

$BinFolderPath = [IO.Path]::Combine($WebFolderPath, 'bin') 
$ToolsFolderPath  = [IO.Path]::Combine($WebFolderPath, 'Tools') 
$ExportExeFilePath = [IO.Path]::Combine($ToolsFolderPath, 'Export.exe')
$ExportConfigFilePath = [IO.Path]::Combine($ToolsFolderPath, 'Export.exe.config')

if($ExportFromFilePath)
{
	& $ExportExeFilePath -TARGET "$TargetPath" -SOURCE /Root -ASM $BinFolderPath -FILTER $ExportFromFilePath
	Write-Host "Export was running: $ExportExeFilePath -TARGET /Root -SOURCE $StructureFolderPath -ASM $BinFolderPath (-SCHEMA $SchemaFolderPath) -FILTER $ExportFromFilePath"
}
else{
	& $ExportExeFilePath -TARGET "$TargetPath" -SOURCE /Root -ASM $BinFolderPath 
	Write-Host "Export was running: $ExportExeFilePath -TARGET /Root -SOURCE $StructureFolderPath -ASM $BinFolderPath (-SCHEMA $SchemaFolderPath)"
}


