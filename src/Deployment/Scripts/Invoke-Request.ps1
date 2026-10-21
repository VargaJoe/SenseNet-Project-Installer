#requires -Version 5.1
[CmdletBinding()] param([Parameter(Mandatory)][string]$RequestPath)
$ErrorActionPreference='Stop'
[Console]::OutputEncoding=New-Object Text.UTF8Encoding($false)
try {
    Import-Module (Join-Path $PSScriptRoot 'Core/PlotManager.psm1') -ErrorAction Stop
    $request=Copy-PlotValue (ConvertFrom-PlotJsonText ([IO.File]::ReadAllText((Resolve-Path -LiteralPath $RequestPath))))
    if ($request -isnot [hashtable]) { throw 'Request must be a JSON object.' }
    Import-Module (Join-Path $PSScriptRoot 'Core/PlotIntegration.psm1') -ErrorAction Stop
    $result=Invoke-PlotRequest $request
    $result | ConvertTo-Json -Depth 40
    if ($result.PSObject.Properties['Status'] -and $result.Status -eq 'Failed') { exit 1 }
    exit 0
} catch { [Console]::Error.WriteLine($_.Exception.Message); exit 1 }
