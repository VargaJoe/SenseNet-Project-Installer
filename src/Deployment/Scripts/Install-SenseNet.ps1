[CmdletBinding(SupportsShouldProcess=$True)]
Param(
[Parameter(Mandatory=$true)]
[string]$SnSourceBasePath,
[Parameter(Mandatory=$true)]
[string]$DataSource,
[Parameter(Mandatory=$true)]
[string]$InitialCatalog
)

Write-Host ================================================ -foregroundcolor "green"
Write-Host INSTALL SENSENET -foregroundcolor "green"
Write-Host ================================================ -foregroundcolor "green"

Write-Host init
. ".\init-functions.ps1"

$InstallExeName = "cmd.exe"
$InstallParameters = "/c"
$SnInstallBatchName = 'InstallSenseNet.bat'

$ScriptBaseFolderPath = Split-Path -Parent $MyInvocation.MyCommand.Path
$SnDeploymentPath = [IO.Path]::Combine($SnSourceBasePath, 'Deployment')
$SnToolsFolderPath = [IO.Path]::Combine($SnSourceBasePath, 'Source\SenseNet\WebSite\Tools')
#$SnInstallBatchPath = [IO.Path]::Combine($SnSourceBasePath, 'Deployment\InstallSenseNet.bat')
#$SnToolsFolderPath  = [IO.Path]::Combine($ScriptBaseFolderPath, 'Source\SenseNet\WebSite\Tools') 
$SnImportConfigFilePath = [IO.Path]::Combine($SnToolsFolderPath, 'Import.exe.config')
$SnIndexpopulatorConfigFilePath = [IO.Path]::Combine($SnToolsFolderPath, 'Indexpopulator.exe.config')

# connection string
$ConnectionString = 'Persist Security Info=False;Initial Catalog='+$InitialCatalog+';Data Source='+$DataSource+';Integrated Security=true'

#Test-Path $SnDeploymentPath
#Write-host $ScriptBaseFolderPath 
#Write-host $SnDeploymentPath 
#Write-host $SnInstallBatchPath 
#Write-host $SnToolsFolderPath
#Write-host $SnImportConfigFilePath 
#Write-host $SnIndexpopulatorConfigFilePath 
#Write-host $ConnectionString 

 #   <add key="SqlCommandTimeout" value="0"/>
 #   <add key="LuceneActivityTimeoutInSeconds" value="600"/>
 #   <add key="SecuritActivityTimeoutInSeconds" value="600"/> <!-- default: 120 sec -->
 #   <add key="TransactionTimeout" value="7200" /> <!-- 2 hours. 0 does not mean infinite here! -->
 #   <add key="LongTransactionTimeout" value="7200" /> <!--  2 hours. 0 does not mean infinite here! -->

	
# Set connection string in Import.exe.config, because it cannot be parametrized yet
Write-host "Edit import.config file" $SnImportConfigFilePath
Set-ConnectionString -ConfigPath $SnImportConfigFilePath -ConnectionString $ConnectionString
Set-PathTooLongHandling -ConfigPath $SnImportConfigFilePath 
Set-AppSetting -ConfigPath $SnImportConfigFilePath -Key "SqlCommandTimeout" -Value "0"
Set-AppSetting -ConfigPath $SnImportConfigFilePath -Key "LuceneActivityTimeoutInSeconds" -Value "600"
Set-AppSetting -ConfigPath $SnImportConfigFilePath -Key "SecuritActivityTimeoutInSeconds" -Value "600"
Set-AppSetting -ConfigPath $SnImportConfigFilePath -Key "TransactionTimeout" -Value "7200"
Set-AppSetting -ConfigPath $SnImportConfigFilePath -Key "LongTransactionTimeout" -Value "7200"

# Set connection string in IndexPopulator.exe.config, because it cannot be parametrized yet
Write-host "Edif indexpopulator.config file" $SnIndexpopulatorConfigFilePath
Set-ConnectionString -ConfigPath $SnIndexpopulatorConfigFilePath -ConnectionString $ConnectionString

# Temporarily change to installer batch parent folder
Write-Host CD $SnDeploymentPath
Push-Location $SnDeploymentPath
Try
{
# do stuff, call ant, etc
Write-Host $InstallExeName $InstallParameters "$SnInstallBatchName" DATASOURCE:$DataSource INITIALCATALOG:$InitialCatalog
& "$InstallExeName" $InstallParameters "$SnInstallBatchName" DATASOURCE:$DataSource INITIALCATALOG:$InitialCatalog
}
Catch
{
	$ErrorMessage = $_.Exception.Message
	Write-Host "[Error][Install] => "$ErrorMessage
}
Finally
{
# Now back to the powershell scripts' folder
Pop-Location
}

