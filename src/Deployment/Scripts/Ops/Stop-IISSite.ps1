#requires -Version 5.1
[CmdletBinding(SupportsShouldProcess)]
param([Parameter(Mandatory)][string]$WebsiteName, [string]$AppPoolName=$WebsiteName)
try {
    Import-Module (Join-Path $PSScriptRoot '../Auto/Iis/Plot.Iis.psm1') -ErrorAction Stop
    Stop-PlotIisSite -Settings @{ WebsiteName=$WebsiteName; AppPoolName=$AppPoolName } -Context @{} -WhatIf:$WhatIfPreference -ErrorAction Stop
    exit 0
} catch {
    Write-Error $_ -ErrorAction Continue
    exit 1
}
