# System Operations Step Module
# Implements PowerShell standards for system-related steps

$ErrorActionPreference = 'Stop'

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
        if (-not $StepSettings.ContainsKey('WebAppName') -or [string]::IsNullOrWhiteSpace($StepSettings['WebAppName'])) {
            Write-Error 'StepSettings["WebAppName"] is required.'
            $script:Result = 1
            return
        }
        $webAppName = $StepSettings['WebAppName']
        & "$ScriptBaseFolderPath/Ops/Stop-IISSite.ps1" $webAppName
        $script:Result = $LASTEXITCODE
    } catch {
        Write-Error $_
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
        if (-not $StepSettings.ContainsKey('WebAppName') -or [string]::IsNullOrWhiteSpace($StepSettings['WebAppName'])) {
            Write-Error 'StepSettings["WebAppName"] is required.'
            $script:Result = 1
            return
        }
        $webAppName = $StepSettings['WebAppName']
        & "$ScriptBaseFolderPath/Ops/Start-IISSite.ps1" $webAppName
        $script:Result = $LASTEXITCODE
    } catch {
        Write-Error $_
        $script:Result = 1
    }
}

# Additional system operations (WebAppOff, WebAppOn, WarmApp, CreateSite, SetHost, etc.)
# should be refactored here following the same standards.
