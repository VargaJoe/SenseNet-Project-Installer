# Core Helper Functions for Plot Manager
# Implements logging, settings merging, and parameter validation to PowerShell standards

$ErrorActionPreference = 'Stop'

function Write-Log {
<##
.SYNOPSIS
Write a log message with severity
.DESCRIPTION
Logs a message with a specified severity (Info, Warning, Error, Debug)
.PARAMETER Message
The message to log
.PARAMETER Severity
The severity level (Info, Warning, Error, Debug)
.EXAMPLE
Write-Log -Message 'Starting deployment' -Severity 'Info'
##>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]$Message,
        [Parameter(Mandatory=$false)]
        [ValidateSet('Info','Warning','Error','Debug')]
        [string]$Severity = 'Info'
    )
    $timestamp = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
    $output = "[$timestamp][$Severity] $Message"
    switch ($Severity) {
        'Info'    { Write-Host $output -ForegroundColor Green }
        'Warning' { Write-Warning $output }
        'Error'   { Write-Error $output }
        'Debug'   { Write-Host $output -ForegroundColor Yellow }
        default   { Write-Host $output }
    }
}

function Merge-StepSettings {
<##
.SYNOPSIS
Merge global, plot, and step-specific settings
.DESCRIPTION
Returns a merged hashtable of settings, with precedence: step > plot > global
.PARAMETER GlobalSettings
Global settings hashtable
.PARAMETER PlotSettings
Plot-level settings hashtable
.PARAMETER StepSettings
Step-level settings hashtable
.EXAMPLE
$merged = Merge-StepSettings -GlobalSettings $g -PlotSettings $p -StepSettings $s
##>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$false)]
        [hashtable]$GlobalSettings,
        [Parameter(Mandatory=$false)]
        [hashtable]$PlotSettings,
        [Parameter(Mandatory=$false)]
        [hashtable]$StepSettings
    )
    $merged = @{}
    foreach ($src in @($GlobalSettings, $PlotSettings, $StepSettings)) {
        if ($src) {
            foreach ($key in $src.Keys) { $merged[$key] = $src[$key] }
        }
    }
    return $merged
}

function Assert-RequiredSetting {
<##
.SYNOPSIS
Validate that a required setting exists and is not empty
.DESCRIPTION
Throws or logs an error if the required key is missing or empty
.PARAMETER Settings
The hashtable to check
.PARAMETER Key
The required key
.EXAMPLE
Assert-RequiredSetting -Settings $StepSettings -Key 'WebAppName'
##>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [hashtable]$Settings,
        [Parameter(Mandatory=$true)]
        [string]$Key
    )
    if (-not $Settings.ContainsKey($Key) -or [string]::IsNullOrWhiteSpace($Settings[$Key])) {
        Write-Error "Required setting '$Key' is missing or empty."
        throw "Required setting '$Key' is missing or empty."
    }
}
