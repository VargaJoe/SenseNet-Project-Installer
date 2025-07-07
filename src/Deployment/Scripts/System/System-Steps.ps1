# System Operations Step Module
# Implements PowerShell standards for system-related steps

$ErrorActionPreference = 'Stop'
. "$ScriptBaseFolderPath/Core/Core-Helpers.ps1"

function Step-System-Stop {
<##
.SYNOPSIS
Stop IIS site and application pool
.DESCRIPTION
Stops the specified IIS site and its application pool using project settings.
.PARAMETER StepSettings
Hashtable of settings. Must include 'WebAppName'.
.EXAMPLE
Step-System-Stop -StepSettings @{ WebAppName = 'MySite' }
##>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [hashtable]$StepSettings
    )
    try {
        Assert-RequiredSetting -Settings $StepSettings -Key 'WebAppName'
        $webAppName = $StepSettings['WebAppName']
        Write-Log -Message "Stopping IIS site: $webAppName" -Severity Info
        & "$ScriptBaseFolderPath/Ops/Stop-IISSite.ps1" $webAppName
        $script:Result = $LASTEXITCODE
    } catch {
        Write-Log -Message $_ -Severity Error
        $script:Result = 1
    }
}

function Step-System-Start {
<##
.SYNOPSIS
Start IIS site and application pool
.DESCRIPTION
Starts the specified IIS site and its application pool using project settings.
.PARAMETER StepSettings
Hashtable of settings. Must include 'WebAppName'.
.EXAMPLE
Step-System-Start -StepSettings @{ WebAppName = 'MySite' }
##>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [hashtable]$StepSettings
    )
    try {
        Assert-RequiredSetting -Settings $StepSettings -Key 'WebAppName'
        $webAppName = $StepSettings['WebAppName']
        Write-Log -Message "Starting IIS site: $webAppName" -Severity Info
        & "$ScriptBaseFolderPath/Ops/Start-IISSite.ps1" $webAppName
        $script:Result = $LASTEXITCODE
    } catch {
        Write-Log -Message $_ -Severity Error
        $script:Result = 1
    }
}

# Additional system operations (WebAppOff, WebAppOn, WarmApp, CreateSite, SetHost, etc.)
# should be refactored here following the same standards.
