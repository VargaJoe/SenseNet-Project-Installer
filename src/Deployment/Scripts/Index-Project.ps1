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
Write-Host INDEXPOPULATION -foregroundcolor "green"
Write-Host ================================================ -foregroundcolor "green"

Write-Host init
. ".\init-functions.ps1"

$BinFolderPath = [IO.Path]::Combine($WebFolderPath, 'bin') 
$ToolsFolderPath  = [IO.Path]::Combine($WebFolderPath, 'Tools') 
$IndexpopulatorExeFilePath = [IO.Path]::Combine($ToolsFolderPath, 'Indexpopulator.exe')
$IndexpopulatorConfigFilePath = [IO.Path]::Combine($ToolsFolderPath, 'Indexpopulator.exe.config')

# connection string
if($DataSource -and $InitialCatalog){
$ConnectionString = 'Persist Security Info=False;Initial Catalog='+$InitialCatalog+';Data Source='+$DataSource+';Integrated Security=true'

# Set connection string in IndexPopulator.exe.config, because it cannot be parametrized yet
Write-host "Edit indexpopulator.config file" $IndexpopulatorConfigFilePath
Set-ConnectionString -ConfigPath $IndexpopulatorConfigFilePath -ConnectionString $ConnectionString
}

Write-Host "$IndexpopulatorExeFilePath" -ASM "$BinFolderPath"
& "$IndexpopulatorExeFilePath" -ASM "$BinFolderPath"
