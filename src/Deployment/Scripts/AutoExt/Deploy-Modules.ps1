# ******************************************************************  Steps ******************************************************************

# Meg kell:
# - admin bin deploy
# - admin tools deploy 
# - tools deploy + config

#============================================ snadmin operations ==================================================
Function Step-Deploy-PrInstall {
<#
    .SYNOPSIS
    Project solution structure install
    .DESCRIPTION
    Installs the project solution structure using SnAdmin and package paths from StepSettings.
    .PARAMETER StepSettings
    Hashtable of settings. Must include 'SnAdminFilePath', 'DeployFolderPath'.
    .EXAMPLE
    Step-Deploy-PrInstall -StepSettings @{ SnAdminFilePath = '...'; DeployFolderPath = '...' }
#>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [hashtable]$StepSettings
    )
    try {
        Assert-RequiredSetting -Settings $StepSettings -Key 'SnAdminFilePath'
        Assert-RequiredSetting -Settings $StepSettings -Key 'DeployFolderPath'
        $snAdminPath = Get-FullPath $StepSettings['SnAdminFilePath']
        $packagePath = Get-FullPath $StepSettings['DeployFolderPath']
        Write-Log -Message "Running Package-Module.ps1 with SnAdminPath: $snAdminPath, PackagePath: $packagePath" -Severity Info
        & $ScriptBaseFolderPath\Deploy\Package-Module.ps1 -SnAdminPath "$snAdminPath" -PackagePath "$packagePath"
        $script:Result = $LASTEXITCODE
    } catch {
        Write-Log -Message $_ -Severity Error
        $script:Result = 1
    }
}

Function Step-Deploy-PrImport {
<#!
    .SYNOPSIS
    Import project
    .DESCRIPTION
    Imports the project using SnAdmin and RepoFsFolderPath from StepSettings.
    .PARAMETER StepSettings
    Hashtable of settings. Must include 'SnAdminFilePath', 'RepoFsFolderPath'.
    .EXAMPLE
    Step-Deploy-PrImport -StepSettings @{ SnAdminFilePath = '...'; RepoFsFolderPath = '...' }
#>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [hashtable]$StepSettings
    )
    try {
        Assert-RequiredSetting -Settings $StepSettings -Key 'SnAdminFilePath'
        Assert-RequiredSetting -Settings $StepSettings -Key 'RepoFsFolderPath'
        $projectRepoFsFolderPath = Get-FullPath $StepSettings['RepoFsFolderPath']
        $snAdminPath = Get-FullPath $StepSettings['SnAdminFilePath']
        Write-Log -Message "Running Import-Module.ps1 with SnAdminPath: $snAdminPath, SourcePath: $projectRepoFsFolderPath" -Severity Info
        & $ScriptBaseFolderPath\Deploy\Import-Module.ps1 -SnAdminPath $snAdminPath -SourcePath "$projectRepoFsFolderPath"
        $script:Result = $LASTEXITCODE
    } catch {
        Write-Log -Message $_ -Severity Error
        $script:Result = 1
    }
}

#============================================ configurations ==================================================

Function Step-Deploy-SetInstallerConnection {
<#!
    .SYNOPSIS
    Set installer json configurations
    .DESCRIPTION
    Sets installer configuration using values from StepSettings.
    .PARAMETER StepSettings
    Hashtable of settings. Must include 'InstallerCfgFilePath', 'DataSource', 'InitialCatalog', 'UserName', 'UserPsw'.
    .EXAMPLE
    Step-Deploy-SetInstallerConnection -StepSettings @{ InstallerCfgFilePath = '...'; DataSource = '...'; InitialCatalog = '...'; UserName = '...'; UserPsw = '...' }
#>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [hashtable]$StepSettings
    )
    try {
        Assert-RequiredSetting -Settings $StepSettings -Key 'InstallerCfgFilePath'
        Assert-RequiredSetting -Settings $StepSettings -Key 'DataSource'
        Assert-RequiredSetting -Settings $StepSettings -Key 'InitialCatalog'
        Assert-RequiredSetting -Settings $StepSettings -Key 'UserName'
        Assert-RequiredSetting -Settings $StepSettings -Key 'UserPsw'
        $instConfigFilePath = Get-FullPath $StepSettings['InstallerCfgFilePath']
        $dataSource = $StepSettings['DataSource']
        $initialCatalog = $StepSettings['InitialCatalog']
        $userName = $StepSettings['UserName']
        $userPsw = $StepSettings['UserPsw']
        Write-Log -Message "Setting installer config: $instConfigFilePath" -Severity Info
        & $ScriptBaseFolderPath\Deploy\Set-JsonConnection.ps1 -ConfigFilePath "$instConfigFilePath" -DataSource "$dataSource" -InitialCatalog "$initialCatalog" -UserName $userName -UserPsw $userPsw
        $script:Result = $LASTEXITCODE
    } catch {
        Write-Log -Message $_ -Severity Error
        $script:Result = 1
    }
}

Function Step-Deploy-SetJsonPackages {
<#!
    .SYNOPSIS
    Set install packages with installer json configurations
    .DESCRIPTION
    Sets install packages in installer config using StepSettings.
    .PARAMETER StepSettings
    Hashtable of settings. Must include 'InstallerCfgFilePath', 'InstallPackages'.
    .EXAMPLE
    Step-Deploy-SetJsonPackages -StepSettings @{ InstallerCfgFilePath = '...'; InstallPackages = @('pkg1','pkg2') }
#>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [hashtable]$StepSettings
    )
    try {
        Assert-RequiredSetting -Settings $StepSettings -Key 'InstallerCfgFilePath'
        Assert-RequiredSetting -Settings $StepSettings -Key 'InstallPackages'
        $instConfigFilePath = Get-FullPath $StepSettings['InstallerCfgFilePath']
        $packages = $StepSettings['InstallPackages']
        Write-Log -Message "Setting install packages in config: $instConfigFilePath" -Severity Info
        & $ScriptBaseFolderPath\Deploy\Set-Packages-Json.ps1 -ConfigFilePath "$instConfigFilePath" -Packages $packages -nodeName "packages"
        $script:Result = $LASTEXITCODE
    } catch {
        Write-Log -Message $_ -Severity Error
        $script:Result = 1
    }
}

Function Step-Deploy-SetJsonImports {
<#!
    .SYNOPSIS
    Set import packages with installer json configurations
    .DESCRIPTION
    Sets import packages in installer config using StepSettings.
    .PARAMETER StepSettings
    Hashtable of settings. Must include 'InstallerCfgFilePath', 'ImportPackages'.
    .EXAMPLE
    Step-Deploy-SetJsonImports -StepSettings @{ InstallerCfgFilePath = '...'; ImportPackages = @('pkg1','pkg2') }
#>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [hashtable]$StepSettings
    )
    try {
        Assert-RequiredSetting -Settings $StepSettings -Key 'InstallerCfgFilePath'
        Assert-RequiredSetting -Settings $StepSettings -Key 'ImportPackages'
        $instConfigFilePath = Get-FullPath $StepSettings['InstallerCfgFilePath']
        $packages = $StepSettings['ImportPackages']
        Write-Log -Message "Setting import packages in config: $instConfigFilePath" -Severity Info
        & $ScriptBaseFolderPath\Deploy\Set-Packages-Json.ps1 -ConfigFilePath "$instConfigFilePath" -Packages $packages -nodeName "import"
        $script:Result = $LASTEXITCODE
    } catch {
        Write-Log -Message $_ -Severity Error
        $script:Result = 1
    }
}

#============================================ file operations ==================================================
Function Step-Deploy-PrAsmDeploy {
<#!
    .SYNOPSIS
    Copy assemblies to production
    .DESCRIPTION
    Copies assemblies from project to production using StepSettings.
    .PARAMETER StepSettings
    Hashtable of settings. Must include 'ProjectAsmFolderPath', 'ProductionAsmFolderPath'.
    .EXAMPLE
    Step-Deploy-PrAsmDeploy -StepSettings @{ ProjectAsmFolderPath = '...'; ProductionAsmFolderPath = '...' }
#>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [hashtable]$StepSettings
    )
    try {
        Assert-RequiredSetting -Settings $StepSettings -Key 'ProjectAsmFolderPath'
        Assert-RequiredSetting -Settings $StepSettings -Key 'ProductionAsmFolderPath'
        $projectAsmFolderPackPath = Get-FullPath $StepSettings['ProjectAsmFolderPath']
        $productionAsmFolderPath = Get-FullPath $StepSettings['ProductionAsmFolderPath']
        Write-Log -Message "Copying assemblies from $projectAsmFolderPackPath to $productionAsmFolderPath" -Severity Info
        Copy-Item -Path "$projectAsmFolderPackPath/*" -Destination "$productionAsmFolderPath" -Recurse -Force
        $script:Result = $LASTEXITCODE
    } catch {
        Write-Log -Message $_ -Severity Error
        $script:Result = 1
    }
}

Function Step-Deploy-PrLucDeploy {
<#!
    .SYNOPSIS
    Copy lucene to production
    .DESCRIPTION
    Copies Lucene files from project to production using StepSettings.
    .PARAMETER StepSettings
    Hashtable of settings. Must include 'ProjectLucFolderPath', 'ProductionLucFolderPath'.
    .EXAMPLE
    Step-Deploy-PrLucDeploy -StepSettings @{ ProjectLucFolderPath = '...'; ProductionLucFolderPath = '...' }
#>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [hashtable]$StepSettings
    )
    try {
        Assert-RequiredSetting -Settings $StepSettings -Key 'ProjectLucFolderPath'
        Assert-RequiredSetting -Settings $StepSettings -Key 'ProductionLucFolderPath'
        $projectLucFolderPackPath = Get-FullPath $StepSettings['ProjectLucFolderPath']
        $productionLucFolderPath = Get-FullPath $StepSettings['ProductionLucFolderPath']
        Write-Log -Message "Copying Lucene files from $projectLucFolderPackPath to $productionLucFolderPath" -Severity Info
        Remove-Item -Path "$productionLucFolderPath/*" -Recurse
        Copy-Item -Path "$projectLucFolderPackPath/*" -Destination "$productionLucFolderPath" -Recurse -Force
        Write-Log -Message "Done!" -Severity Info
        $script:Result = $LASTEXITCODE
    } catch {
        Write-Log -Message $_ -Severity Error
        $script:Result = 1
    }
}

Function Step-Deploy-CleanWebFolder {
<#!
    .SYNOPSIS
    Clean webfolder
    .DESCRIPTION
    Remove all folders and files under webfolder, except app_offline.htm
    .PARAMETER StepSettings
    Hashtable of settings. Must include 'WebFolderPath'.
    .EXAMPLE
    Step-Deploy-CleanWebFolder -StepSettings @{ WebFolderPath = '...' }
#>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [hashtable]$StepSettings
    )
    try {
        Assert-RequiredSetting -Settings $StepSettings -Key 'WebFolderPath'
        $projectWebFolderPath = Get-FullPath $StepSettings['WebFolderPath']
        Write-Log -Message "Cleaning up web folder: $projectWebFolderPath" -Severity Info
        Remove-Item "$($projectWebFolderPath)\*" -Recurse -Exclude "app_offline*.htm" -Force -ErrorAction SilentlyContinue
        $script:Result = $LASTEXITCODE
    } catch {
        Write-Log -Message $_ -Severity Error
        $script:Result = 1
    }
}

Function Step-Deploy-CleanWebFolderWOIndex {
<#!
    .SYNOPSIS
    Clean webfolder without index
    .DESCRIPTION
    Remove all folders and files under webfolder, except app_offline.htm and LocalIndex
    .PARAMETER StepSettings
    Hashtable of settings. Must include 'WebFolderPath'.
    .EXAMPLE
    Step-Deploy-CleanWebFolderWOIndex -StepSettings @{ WebFolderPath = '...' }
#>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [hashtable]$StepSettings
    )
    try {
        Assert-RequiredSetting -Settings $StepSettings -Key 'WebFolderPath'
        $projectWebFolderPath = Get-FullPath $StepSettings['WebFolderPath']
        Write-Log -Message "Cleaning up web folder (without index): $projectWebFolderPath" -Severity Info
        Remove-Item "$($projectWebFolderPath)\*" -Recurse -Exclude "app_offline*.htm","LocalIndex" -Force -ErrorAction SilentlyContinue
        $script:Result = $LASTEXITCODE
    } catch {
        Write-Log -Message $_ -Severity Error
        $script:Result = 1
    }
}

Function Step-Deploy-CreateWebFolder {
<#!
    .SYNOPSIS
    Create webfolder on destination if not exists
    .DESCRIPTION
    Creates the webfolder if it does not exist using StepSettings.
    .PARAMETER StepSettings
    Hashtable of settings. Must include 'WebFolderPath'.
    .EXAMPLE
    Step-Deploy-CreateWebFolder -StepSettings @{ WebFolderPath = '...' }
#>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [hashtable]$StepSettings
    )
    try {
        Assert-RequiredSetting -Settings $StepSettings -Key 'WebFolderPath'
        $projectWebFolderPath = Get-FullPath $StepSettings['WebFolderPath']
        Write-Log -Message "Ensuring web folder exists: $projectWebFolderPath" -Severity Info
        if (-not(Test-Path $projectWebFolderPath)) {
            $parentPath = $projectWebFolderPath | Split-Path -Parent
            $folderName = $projectWebFolderPath | Split-Path -Leaf
            Write-Log -Message "Creating target webfolder: $folderName under $parentPath" -Severity Info
            New-Item -Path "$parentPath" -Name "$folderName" -ItemType "directory"
        }
        $script:Result = 0
    } catch {
        Write-Log -Message $_ -Severity Error
        $script:Result = 1
    }
}

Function Step-Deploy-DeployWebFolder {
<#!
    .SYNOPSIS
    Copy starter webfolder to destination from template
    .DESCRIPTION
    Copies starter webfolder from template to destination using StepSettings.
    .PARAMETER StepSettings
    Hashtable of settings. Must include 'WebFolderPath', 'TemplateWebFolderPath'.
    .EXAMPLE
    Step-Deploy-DeployWebFolder -StepSettings @{ WebFolderPath = '...'; TemplateWebFolderPath = '...' }
#>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [hashtable]$StepSettings
    )
    try {
        Assert-RequiredSetting -Settings $StepSettings -Key 'WebFolderPath'
        Assert-RequiredSetting -Settings $StepSettings -Key 'TemplateWebFolderPath'
        $templateWebfolderPath = Get-FullPath $StepSettings['TemplateWebFolderPath']
        $projectWebFolderPath = Get-FullPath $StepSettings['WebFolderPath']
        Write-Log -Message "Copying starter webfolder from $templateWebfolderPath to $projectWebFolderPath" -Severity Info
        if (-not(Test-Path $projectWebFolderPath)) {
            $parentPath = $projectWebFolderPath | Split-Path -Parent
            $folderName = $projectWebFolderPath | Split-Path -Leaf
            Write-Log -Message "Creating target webfolder: $folderName under $parentPath" -Severity Info
            New-Item -Path "$parentPath" -Name "$folderName" -ItemType "directory"
        }
        Copy-Item -Path "$templateWebfolderPath/*" -Destination "$projectWebFolderPath" -Recurse -Force
        $script:Result = 0
    } catch {
        Write-Log -Message $_ -Severity Error
        $script:Result = 1
    }
}

Function Step-Deploy-DeployWebFolderFromZip {
<#!
    .SYNOPSIS
    Copy starter webfolder to destination from zip
    .DESCRIPTION
    Copies starter webfolder from zip to destination using StepSettings.
    .PARAMETER StepSettings
    Hashtable of settings. Must include 'SnWebFolderFilePath', 'WebFolderPath'.
    .EXAMPLE
    Step-Deploy-DeployWebFolderFromZip -StepSettings @{ SnWebFolderFilePath = '...'; WebFolderPath = '...' }
#>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [hashtable]$StepSettings
    )
    try {
        Assert-RequiredSetting -Settings $StepSettings -Key 'SnWebFolderFilePath'
        Assert-RequiredSetting -Settings $StepSettings -Key 'WebFolderPath'
        $snWebfolderPackPath = Get-FullPath $StepSettings['SnWebFolderFilePath']
        $projectWebFolderPath = Get-FullPath $StepSettings['WebFolderPath']
        Write-Log -Message "Copying webfolder from zip: $snWebfolderPackPath to $projectWebFolderPath" -Severity Info
        & $ScriptBaseFolderPath\Tools\Unzip-File.ps1 -filename "$snWebfolderPackPath" -destname "$projectWebFolderPath"
        $script:Result = $LASTEXITCODE
    } catch {
        Write-Log -Message $_ -Severity Error
        $script:Result = 1
    }
}

Function Step-Deploy-SetHostPermissionOnDb {
<#!
    .SYNOPSIS
    Set host permission on DB
    .DESCRIPTION
    Grants host machine user permission to site database using StepSettings.
    .PARAMETER StepSettings
    Hashtable of settings. Must include 'DataSource', 'InitialCatalog', 'MachineName'.
    .EXAMPLE
    Step-Deploy-SetHostPermissionOnDb -StepSettings @{ DataSource = '...'; InitialCatalog = '...'; MachineName = '...' }
#>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [hashtable]$StepSettings
    )
    try {
        Assert-RequiredSetting -Settings $StepSettings -Key 'DataSource'
        Assert-RequiredSetting -Settings $StepSettings -Key 'InitialCatalog'
        Assert-RequiredSetting -Settings $StepSettings -Key 'MachineName'
        $dataSource = $StepSettings['DataSource']
        $initialCatalog = $StepSettings['InitialCatalog']
        $webServer = $StepSettings['MachineName']
        Write-Log -Message "Granting DB permission for SN\\$webServer$ on $dataSource/$initialCatalog" -Severity Info
        & $ScriptBaseFolderPath\Ops\Grant-Permission.ps1 -DataSource "$dataSource" -Catalog "$initialCatalog" -User "SN\$($webServer)$" -Verbose
        $script:Result = $LASTEXITCODE
    } catch {
        Write-Log -Message $_ -Severity Error
        $script:Result = 1
    }
}

