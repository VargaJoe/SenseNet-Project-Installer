#requires -Version 5.1
[CmdletBinding(SupportsShouldProcess)]
param(
    [Parameter(Position=0)][string]$Plot,
    [string]$Step,
    [string]$ConfigPath,
    [string]$Settings,
    [string]$Params = '{}',
    [string]$AutoPath,
    [string]$WorkDirectory = (Get-Location).Path,
    [ValidateSet('steps','plots')][string]$Help,
    [switch]$Explain,
    [switch]$Legacy
)
$ErrorActionPreference = 'Stop'
$registry = $null
try {
    if ($Legacy) {
        if ($WhatIfPreference -or $Explain) { throw 'Legacy scripts do not provide a reliable preview. Use native packages for WhatIf/Explain.' }
        if ($ConfigPath -or $PSBoundParameters.ContainsKey('AutoPath') -or $PSBoundParameters.ContainsKey('WorkDirectory')) {
            throw 'Legacy mode accepts Plot, Step, Settings, Params and Help only.'
        }
        # Run historical global-variable scripts in another PowerShell process.
        $hostPath = (Get-Process -Id $PID).Path
        $arguments = @('-NoProfile','-NonInteractive','-File',(Join-Path $PSScriptRoot 'Run-Legacy.ps1'))
        foreach ($pair in @{ Plot=$Plot; Step=$Step; Settings=$Settings; Params=$Params; Help=$Help }.GetEnumerator()) {
            if (-not [string]::IsNullOrEmpty($pair.Value)) { $arguments += "-$($pair.Key)"; $arguments += $pair.Value }
        }
        if ($VerbosePreference -eq 'Continue') { $arguments += '-Verbose' }
        & $hostPath @arguments
        exit $LASTEXITCODE
    }
    if (-not $AutoPath) { $AutoPath = Join-Path $PSScriptRoot 'Auto' }
    Import-Module (Join-Path $PSScriptRoot 'Core/PlotManager.psm1') -ErrorAction Stop
    $registry = New-PlotRegistry -AutoPath $AutoPath
    if ($Help -eq 'steps' -or (-not $Plot -and -not $Step -and -not $Help)) {
        $registry.Steps.Values | Sort-Object Id | ForEach-Object {
            [pscustomobject]@{ Step=$_.Id; Package=$_.Package.Name; Version=$_.Package.Version; Parameters=($_.Definition.Parameters.Keys | Sort-Object) }
        } | ConvertTo-Json -Depth 6
        exit 0
    }
    if ($ConfigPath -and $Settings) { throw 'Use either ConfigPath or Settings, not both.' }
    if ($Settings) {
        if ($Settings -notmatch '^[a-zA-Z0-9_-]+$') { throw 'Settings must be a preset name. Use ConfigPath for a path.' }
        $ConfigPath = Join-Path $PSScriptRoot "Settings/project-$Settings.json"
    }
    $configuration = if ($ConfigPath) { Read-PlotConfiguration -Path $ConfigPath } else { @{} }
    if ($Help -eq 'plots') {
        if ($configuration.ContainsKey('Plots')) { @($configuration.Plots.Keys | Sort-Object) | ConvertTo-Json }
        else { '[]' }
        exit 0
    }
    if ($Plot -and $Step) { throw 'Use either Plot or Step, not both.' }
    if ($Step) { $Plot = 'single'; $configuration.Plots = @{ single=@(@{ Id='single'; Step=$Step }) } }
    if (-not $Plot) { throw 'Specify Plot or Step.' }
    $overrides = Copy-PlotValue ($Params | ConvertFrom-Json -ErrorAction Stop)
    if ($overrides -isnot [hashtable]) { throw 'Params must be a JSON object keyed by invocation id.' }
    if ($Explain) {
        $plan = Get-PlotPlan -Registry $registry -Configuration $configuration -Plot $Plot -Overrides $overrides
        @($plan | ForEach-Object { [pscustomobject]@{ Id=$_.Id; Step=$_.Step.Id; Sources=$_.Sources } }) | ConvertTo-Json -Depth 8
        exit 0
    }
    $result = Invoke-Plot -Registry $registry -Configuration $configuration -Plot $Plot -Overrides $overrides -WorkDirectory $WorkDirectory -WhatIf:$WhatIfPreference
    $result | ConvertTo-Json -Depth 30
    if ($result.Status -eq 'Failed') { exit 1 }
    exit 0
} catch {
    Write-Error $_ -ErrorAction Continue
    exit 1
} finally {
    if ($null -ne $registry) { Remove-PlotRegistry -Registry $registry }
}
