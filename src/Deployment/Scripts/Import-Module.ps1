[CmdletBinding(SupportsShouldProcess=$True)]
Param(
[Parameter(Mandatory=$true)]
[string]$WebFolderPath,
[Parameter(Mandatory=$true)]
[string]$SourcePath
)

$ScriptBaseFolderPath = Split-Path -Parent $MyInvocation.MyCommand.Path
$Initfunctions = [IO.Path]::Combine($ScriptBaseFolderPath, "init-functions.ps1") 

Write-Host Helper functions initialization from $Initfunctions
. $Initfunctions

$WebFolderPath = [IO.Path]::GetFullPath($WebFolderPath)
Write-host WebFolder combine: $WebFolderPath

$BinFolderPath = [IO.Path]::Combine($WebFolderPath, 'bin') 
$ToolsFolderPath  = [IO.Path]::Combine($WebFolderPath, 'Tools') 
$StructureFolderPath  = [IO.Path]::GetFullPath($SourcePath)
$SchemaFolderPath = [IO.Path]::Combine($StructureFolderPath, 'System\Schema') 
$ImportExeFilePath = [IO.Path]::Combine($ToolsFolderPath, 'Import.exe')
$ImportConfigFilePath = [IO.Path]::Combine($ToolsFolderPath, 'Import.exe.config')

Write-Host "Import was running: $ImportExeFilePath -TARGET /Root -SOURCE $StructureFolderPath -ASM $BinFolderPath (-SCHEMA $SchemaFolderPath)"
if (Test-Path $SchemaFolderPath){
& $ImportExeFilePath -TARGET /Root -SOURCE $StructureFolderPath -ASM $BinFolderPath -SCHEMA $SchemaFolderPath
} else {
& $ImportExeFilePath -TARGET /Root -SOURCE $StructureFolderPath -ASM $BinFolderPath 
}
Write-Host "Import was running: $ImportExeFilePath -TARGET /Root -SOURCE $StructureFolderPath -ASM $BinFolderPath (-SCHEMA $SchemaFolderPath)"

