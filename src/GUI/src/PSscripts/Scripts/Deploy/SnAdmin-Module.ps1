[CmdletBinding(SupportsShouldProcess=$True)]
Param(
[Parameter(Mandatory=$true)]
[string]$PackagePath,
[Parameter(Mandatory=$false)]
[string]$WebFolderPath = "$ProjectWebFolderPath"
)

#& .\SnAdmin-Module.ps1 -WebFolderPath: "$ProjectWebFolderPath" -PackagePath "..\ProjectImport"

$ScriptBaseFolderPath = Split-Path -Parent $MyInvocation.MyCommand.Path
$Initfunctions = [IO.Path]::Combine($ScriptBaseFolderPath, "init-functions.ps1") 

#mode: export, import, stb

# if meg nincs behuzva
#{
#$SettingsPath = 'project-local.json' #ezt kulso parameternek kellene eldonteni melyik legyen
#$ProjectConfig = (Get-Content $SettingsPath) -join "`n" | ConvertFrom-Json 
#$NuGetFolderPath = [IO.Path]::GetFullPath($ProjectConfig.Tools.NuGetFolderPath) 
#$NuGetFilePath = [IO.Path]::Combine($NuGetFolderPath, "NuGet.exe")
#}

Write-Verbose "Helper functions initialization from $Initfunctions"
. $Initfunctions

$WebFolderPath = [IO.Path]::GetFullPath($WebFolderPath)
Write-Verbose "WebFolder combine: $WebFolderPath"

$AdminExeFilePath = [IO.Path]::Combine($WebFolderPath, 'Admin\bin\snadmin.exe')

$PackageFullPath  = [IO.Path]::GetFullPath($PackagePath)

Write-Verbose "$AdminExeFilePath $PackageFullPath"
& $AdminExeFilePath "$PackageFullPath"
