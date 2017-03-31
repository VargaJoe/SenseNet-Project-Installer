[CmdletBinding(SupportsShouldProcess=$True)]
Param(
[Parameter(Mandatory=$true)]
[string]$WebFolderPath,
[Parameter(Mandatory=$false)]
[string]$DataSource,
[Parameter(Mandatory=$false)]
[string]$InitialCatalog
)

Write-Host ================================================ -foregroundcolor "green"
Write-Host IMPORT PROJECT -foregroundcolor "green"
Write-Host ================================================ -foregroundcolor "green"

$ScriptBaseFolderPath = Split-Path -Parent $MyInvocation.MyCommand.Path
$Initfunctions = [IO.Path]::Combine($ScriptBaseFolderPath, "init-functions.ps1") 

Write-Host Helper functions initialization from $Initfunctions
. $Initfunctions

$WebFolderPath = [IO.Path]::GetFullPath($WebFolderPath)
Write-host WebFolder combine: $WebFolderPath

$BinFolderPath = [IO.Path]::Combine($WebFolderPath, 'bin') 
$ToolsFolderPath  = [IO.Path]::Combine($WebFolderPath, 'Tools') 
$StructureFolderPath  = [IO.Path]::Combine($WebFolderPath, 'Root') 
$SchemaFolderPath = [IO.Path]::Combine($StructureFolderPath, 'System\Schema') 
$ImportExeFilePath = [IO.Path]::Combine($ToolsFolderPath, 'Import.exe')
$ImportConfigFilePath = [IO.Path]::Combine($ToolsFolderPath, 'Import.exe.config')

## $SNRELEASESPATH="..\..\Releases"
#$SNRELEASESPATH="..\.."
## $SNSRCNAME='sn-enterprise-src-6.5.4.9851'
#$SNSRCNAME='SN6.4.0.7426test'
#$SNSRCBASEPATH=Join-Path $SNRELEASESPATH $SNSRCNAME 
#$SNDeploymentPATH=Join-Path $SNSRCBASEPATH 'Deployment'
#$SNToolsPATH=Join-Path $SNSRCBASEPATH 'Source\SenseNet\WebSite\Tools'
#$DATASOURCE='MySenseNetContentRepositoryDatasource'
#$INITIALCATALOG='powertest'

#$projectWebFolder='..\..\Source\WebSite\'
#$ProjectToolsPath = [IO.Path]::Combine($projectWebFolder, 'Tools')
#$ImportExePath = [IO.Path]::Combine($ProjectToolsPath, 'Import.exe')
#$RootFolderPath = [IO.Path]::Combine($projectWebFolder, 'Root')
#$SchemaFolderPath = [IO.Path]::Combine($projectWebFolder, 'Root\System\Schema')
#$AsmPath = [IO.Path]::Combine($projectWebFolder, 'bin')

# connection string
#$connectionString = 'Persist Security Info=False;Initial Catalog='+$INITIALCATALOG+';Data Source='+$DATASOURCE+';Integrated Security=true'


# connection string
if($DataSource -and $InitialCatalog){
$ConnectionString = 'Persist Security Info=False;Initial Catalog='+$InitialCatalog+';Data Source='+$DataSource+';Integrated Security=true'

# Set connection string in IndexPopulator.exe.config, because it cannot be parametrized yet
Write-host "Edit import.config file" $ImportConfigFilePath
Set-ConnectionString -ConfigPath $ImportConfigFilePath -ConnectionString $ConnectionString

Set-PathTooLongHandling -ConfigPath $ImportConfigFilePath 
}

Write-Host "Import was running: $ImportExeFilePath -TARGET /Root -SOURCE $StructureFolderPath -ASM $BinFolderPath (-SCHEMA $SchemaFolderPath)"
if (Test-Path $SchemaFolderPath){
& $ImportExeFilePath -TARGET /Root -SOURCE $StructureFolderPath -ASM $BinFolderPath -SCHEMA $SchemaFolderPath
} else {
& $ImportExeFilePath -TARGET /Root -SOURCE $StructureFolderPath -ASM $BinFolderPath 
}
Write-Host "Import was running: $ImportExeFilePath -TARGET /Root -SOURCE $StructureFolderPath -ASM $BinFolderPath (-SCHEMA $SchemaFolderPath)"
