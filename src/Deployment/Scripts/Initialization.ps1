
 function Show-Value {
  [cmdletbinding()]param([string]$VariableName)
   $VariableValue = Get-Variable $VariableName -ValueOnly
   Write-Host $VariableName':' $VariableValue
 }

 function Set-Value {
  [cmdletbinding()]param([string]$VariableName, [string]$VariableValue)
   Set-Variable -Name "$VariableName" -Value "$VariableValue" -Scope global
   $CheckVariableValue = Get-Variable $VariableName -ValueOnly
   Write-Host $VariableName':' $CheckVariableValue
 }

 function Get-FullPath {
  [cmdletbinding()]param([string]$RelativePath)
	
	$FullPath = [IO.Path]::GetFullPath($RelativePath)
	return $FullPath
 }
 
# if ($SettingsPath -eq $null) 
Set-Value SettingsPath 'project-local.json'

# Powershell scripts starter folder path
$ScriptBaseFolderPath = Split-Path -Parent $MyInvocation.MyCommand.Path

$InitFilePath  = [IO.Path]::Combine($ScriptBaseFolderPath, "Initialization.ps1")
$ScriptBaseFolderPath = Get-FullPath "$ScriptBaseFolderPath"

#convert to fullpath

# Show-Value $ScriptBaseFolderPath
# Write-Host "aas:" Get-Variable $ScriptBaseFolderPath -valueOnly
Show-Value ScriptBaseFolderPath

$ProjectConfig = (Get-Content $SettingsPath) -join "`n" | ConvertFrom-Json 

# Tools
$UnZipperFilePath =Resolve-Path $ProjectConfig.Tools.UnZipperfilePath #[IO.Path]::GetFullPath($ProjectConfig.Tools.UnZipperfilePath) # static

# Project SQL server + DB catalog name
$DataSource=$ProjectConfig.DataBase.DataSource # static
$InitialCatalog=$ProjectConfig.DataBase.InitialCatalog # static
$connectionString = 'Persist Security Info=False;Initial Catalog='+$INITIALCATALOG+';Data Source='+$DATASOURCE+';Integrated Security=true' # generated
#Write-Host $connectionString 

# IIS AppPool name
$ProjectSiteName = $ProjectConfig.IIS.WebAppName # static
$ProjectAppPoolName = $ProjectConfig.IIS.AppPoolName # static
$ProjectAppPoolDotNetVersion = $ProjectConfig.IIS.DotNetVersion # static

# SN source package parent folder 	# $SNRELEASESPATH="..\..\Releases"
$SnPackageFolderPath = [IO.Path]::Combine($ScriptBaseFolderPath, $ProjectConfig.Platform.PackageFolderPath) # static relative starter path
# SN source package name = folder name / zip name without extension 	# $SNSRCNAME='sn-enterprise-src-6.5.4.9851'
$SnPackageName=$ProjectConfig.Platform.PackageName # static name
# SN package file name
$SnPackageFilePath = [IO.Path]::Combine($SnPackageFolderPath, $SnPackageName+'.zip') # name
# SN source folder path
$SnSourceBasePath = [IO.Path]::Combine($SnPackageFolderPath, $SnPackageName)
# SN deploy script path (contains 'Install-Sensenet.bat')
$SnDeploymentPath = [IO.Path]::Combine($SnSourceBasePath, 'Deployment')
#$SnDeploymentPath= [IO.Path]::GetFullPath((Join-Path $SnSourceBasePath 'Deployment'))

$SnWebFolderPath = [IO.Path]::Combine($SnSourceBasePath, 'Source\SenseNet\WebSite')

#Write-Host SnSourceBasePath: $SnSourceBasePath
#Write-Host SnDeploymentPath: $SnDeploymentPath

#$SnDeploymentFullPath=[IO.Path]::Combine($SnSourceBasePath, $SNDeploymentPATH)
#Join-Path -Path $scriptDir -ChildPath $SNDeploymentPATH

## SN tools folder path
#$SnToolsFolderPath=[IO.Path]::Combine($SnSourceBasePath, 'Source\SenseNet\WebSite\Tools')
## SN solution path 
$SnSolutionFilePath = [IO.Path]::Combine($SnSourceBasePath, $ProjectConfig.Platform.SolutionFilePath)
## SN installer batch path
#$batchPath = Join-Path $SNDeploymentPATH $installBatch

## Project folder path (this whill be updated by get latest from tfs)
$ProjectSourceFolderPath = [IO.Path]::Combine($ScriptBaseFolderPath, $ProjectConfig.Project.SourceFolderPath)  # static relative starter path

## Project webfolder path
$ProjectWebFolderPath = [IO.Path]::Combine($ScriptBaseFolderPath, $ProjectConfig.Project.WebFolderPath) #'..\..\Source\WebSite\' # static relative starter path
$ProjectWebConfigFilePath = [IO.Path]::Combine($ProjectWebFolderPath, 'Web.config')

## Project solution path 
$ProjectSolutionFilePath = [IO.Path]::Combine($ProjectSourceFolderPath, $ProjectConfig.Project.SolutionFilePath)


