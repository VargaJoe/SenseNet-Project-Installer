[CmdletBinding(SupportsShouldProcess=$True)]
Param(
[Parameter(Mandatory=$true)]
[string]$SourceWebFolderPath,
[Parameter(Mandatory=$true)]
[string]$TargetWebFolderPath,
[Parameter(Mandatory=$true)]
[string]$DataSource,
[Parameter(Mandatory=$true)]
[string]$InitialCatalog
)

Write-Host ================================================ -foregroundcolor "green"
Write-Host ====== Init Configs ================ -foregroundcolor "green"
Write-Host ================================================ -foregroundcolor "green"

$ScriptBaseFolderPath = Split-Path -Parent $MyInvocation.MyCommand.Path
$Initfunctions = [IO.Path]::Combine($ScriptBaseFolderPath, "init-functions.ps1") 

$Computer = $env:computername
Write-host Computer name: $Computer

Write-Host Helper functions initialization from $Initfunctions
. $Initfunctions

Write-host Webfolder path from param: $SourceWebFolderPath

$SourceWebFolderPath = [IO.Path]::GetFullPath($SourceWebFolderPath)
Write-host WebFolder combine: $SourceWebFolderPath

$TargetWebFolderPath = [IO.Path]::GetFullPath($TargetWebFolderPath)
Write-host ProjectWebFolder combine: $TargetWebFolderPath

$SnBinFolderPath = [IO.Path]::Combine($SourceWebFolderPath, 'bin') 
$SnToolsFolderPath  = [IO.Path]::Combine($SourceWebFolderPath, 'Tools') 
$ProjectWebConfigFilePath = [IO.Path]::Combine($TargetWebFolderPath, 'Web.config')

$ProjectBinFolderPath = [IO.Path]::Combine($TargetWebFolderPath, 'bin') 
$ProjectToolsFolderPath  = [IO.Path]::Combine($TargetWebFolderPath, 'Tools') 
$ProjectImportConfigFilePath = [IO.Path]::Combine($ProjectToolsFolderPath, 'Import.exe.config')
$ProjectIndexpopulatorConfigFilePath = [IO.Path]::Combine($ProjectToolsFolderPath, 'Indexpopulator.exe.config')
$ProjectExportFilePath = [IO.Path]::Combine($ProjectToolsFolderPath, 'Export.exe.config')

Write-host Variables are in place

Write-host Create new connection string value
$ConnectionString = 'Persist Security Info=False;Initial Catalog='+$InitialCatalog+';Data Source='+$DataSource+';Integrated Security=true'

Write-host "Edit import.config file" $ProjectWebConfigFilePath
Set-ConnectionString -ConfigPath "$ProjectWebConfigFilePath" -ConnectionString $ConnectionString

# Set connection string in IndexPopulator.exe.config, because it cannot be parametrized yet
Write-host "Edit import.config file" "$ProjectImportConfigFilePath"
Set-ConnectionString -ConfigPath "$ProjectImportConfigFilePath" -ConnectionString $ConnectionString

Write-host "Edit import.config file" "$ProjectIndexpopulatorConfigFilePath"
Set-ConnectionString -ConfigPath "$ProjectIndexpopulatorConfigFilePath" -ConnectionString $ConnectionString

Write-host "Edit export.config file" "$ProjectExportFilePath"
Set-ConnectionString -ConfigPath "$ProjectExportFilePath" -ConnectionString $ConnectionString
