[CmdletBinding(SupportsShouldProcess=$True)]
Param(
[Parameter(Mandatory=$true)]
[string]$SourceWebFolderPath,
[Parameter(Mandatory=$true)]
[string]$TargetWebFolderPath,
[Parameter(Mandatory=$false)]
[string]$DataSource,
[Parameter(Mandatory=$false)]
[string]$InitialCatalog
)

Write-Host ================================================ -foregroundcolor "green"
Write-Host ====== Init Assemblies ================ -foregroundcolor "green"
Write-Host ================================================ -foregroundcolor "green"

$ScriptBaseFolderPath = Split-Path -Parent $MyInvocation.MyCommand.Path
$Initfunctions = [IO.Path]::Combine($ScriptBaseFolderPath, "init-functions.ps1") 
#$EnvDirectoryPath = [environment]::CurrentDirectory 

$Computer = $env:computername
Write-host Computer name: $Computer

Write-Host Helper functions initialization from $Initfunctions
. $Initfunctions

#Write-host Script base path: $ScriptBaseFolderPath
Write-host Webfolder path from param: $SourceWebFolderPath
#Write-Host Agent build directory path: $Env:AGENT_BUILDDIRECTORY
#Write-Host Environment directory path: $EnvDirectoryPath

#[environment]::CurrentDirectory = $ScriptBaseFolderPath
#Write-Host Environment directory path modified: $EnvDirectoryPath

#$SourceWebFolderPath = [IO.Path]::Combine($ScriptBaseFolderPath, $SourceWebFolderPath) 
$SourceWebFolderPath = [IO.Path]::GetFullPath($SourceWebFolderPath)
Write-host WebFolder combine: $SourceWebFolderPath

$TargetWebFolderPath = [IO.Path]::GetFullPath($TargetWebFolderPath)
Write-host ProjectWebFolder combine: $TargetWebFolderPath

# $SourceWebFolderPath = [IO.Path]::Combine($SnSourceBaseFolderPath, 'Source\SenseNet\WebSite')
$SnBinFolderPath = [IO.Path]::Combine($SourceWebFolderPath, 'bin') 
$SnToolsFolderPath  = [IO.Path]::Combine($SourceWebFolderPath, 'Tools') 
# $SnImportExeFilePath = [IO.Path]::Combine($SnToolsFolderPath, 'Import.exe')
# $SnImportConfigFilePath = [IO.Path]::Combine($SnToolsFolderPath, 'Import.exe.config')

$ProjectWebConfigFilePath = [IO.Path]::Combine($TargetWebFolderPath, 'Web.config')

$ProjectBinFolderPath = [IO.Path]::Combine($TargetWebFolderPath, 'bin') 
$ProjectToolsFolderPath  = [IO.Path]::Combine($TargetWebFolderPath, 'Tools') 
# $ProjectImportExeFilePath = [IO.Path]::Combine($ProjectToolsFolderPath, 'Import.exe')
$ProjectImportConfigFilePath = [IO.Path]::Combine($ProjectToolsFolderPath, 'Import.exe.config')
# $ProjectIndexpopulatorExeFilePath = [IO.Path]::Combine($ProjectToolsFolderPath, 'Indexpopulator.exe')
$ProjectIndexpopulatorConfigFilePath = [IO.Path]::Combine($ProjectToolsFolderPath, 'Indexpopulator.exe.config')
$ProjectExportFilePath = [IO.Path]::Combine($ProjectToolsFolderPath, 'Export.exe.config')

Write-host Variables are in place

Write-host `r`nCopy bin folder files from sn to project
Write-Host Source: $SnBinFolderPath
Write-Host Target: $TargetWebFolderPath
Copy-Item -Path "$SnBinFolderPath" -Destination "$TargetWebFolderPath" -recurse -Force

Write-host `r`nCopy Tools folder files from sn to project
Write-Host Source: $SnToolsFolderPath
Write-Host Target: $TargetWebFolderPath
Copy-Item -Path "$SnToolsFolderPath" -Destination "$TargetWebFolderPath" -recurse -Force

if($DataSource -and $InitialCatalog){
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
}
