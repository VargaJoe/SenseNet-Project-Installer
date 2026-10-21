#requires -Version 5.1
Set-StrictMode -Version Latest
Import-Module (Join-Path $PSScriptRoot 'PlotManager.psm1') -ErrorAction Stop
function Invoke-PlotRequest {
    [CmdletBinding(SupportsShouldProcess)] param([Parameter(Mandatory)][hashtable]$Request,[string]$AutoPath=(Join-Path $PSScriptRoot '../Auto'))
    $allowed=@('Operation','ConfigurationFiles','Plot','Step','Overrides','WorkDirectory','WhatIf')
    foreach ($key in $Request.Keys) { if ($key -notin $allowed) { throw "Unknown request field: $key" } }
    if (-not $Request.ContainsKey('Operation') -or $Request.Operation -notin @('catalog','plan','run')) { throw 'Operation must be catalog, plan or run.' }
    foreach ($key in @('Operation','Plot','Step','WorkDirectory')) {
        if ($Request.ContainsKey($key) -and ($Request[$key] -isnot [string] -or [string]::IsNullOrWhiteSpace($Request[$key]))) { throw "$key must be a nonempty string." }
    }
    if ($Request.ContainsKey('WhatIf') -and $Request.WhatIf -isnot [bool]) { throw 'WhatIf must be a JSON boolean.' }
    if ($Request.ContainsKey('Overrides') -and $Request.Overrides -isnot [hashtable]) { throw 'Overrides must be an object keyed by invocation ID.' }
    $files=@()
    if ($Request.ContainsKey('ConfigurationFiles')) {
        if ($Request.ConfigurationFiles -isnot [array]) { throw 'ConfigurationFiles must be an ordered array.' }
        foreach ($file in $Request.ConfigurationFiles) { if ($file -isnot [string] -or [string]::IsNullOrWhiteSpace($file)) { throw 'Configuration paths must be nonempty strings.' }; $files+=$file }
    }
    $registry=$null
    try {
        $registry=New-PlotRegistry $AutoPath
        $configuration=if ($files.Count) { Read-PlotConfiguration $files } else { @{} }
        if ($Request.Operation -eq 'catalog') {
            $steps=@(foreach ($step in ($registry.Steps.Values | Sort-Object Id)) {
                $parameters=Copy-PlotValue $step.Definition.Parameters
                foreach ($schema in $parameters.Values) { if ($schema.ContainsKey('Secret') -and $schema.Secret) { $null=$schema.Remove('Default') } }
                [pscustomobject]@{Id=$step.Id;Package=$step.Package.Name;Version=$step.Package.Version;Parameters=$parameters}
            })
            $plots=@(); if ($configuration.ContainsKey('Plots')) { $plots=@($configuration.Plots.Keys | Sort-Object) }
            return [pscustomobject]@{ProtocolVersion=1;Steps=$steps;Plots=$plots}
        }
        $plot=$Request['Plot']; $step=$Request['Step']
        if ([bool]$plot -eq [bool]$step) { throw 'Supply exactly one of Plot or Step.' }
        if ($step) { $plot='single'; $configuration.Plots=@{single=@(@{Id='single';Step=$step})} }
        $overrides=@{}; if ($Request.ContainsKey('Overrides')) { $overrides=$Request.Overrides }
        if ($Request.Operation -eq 'plan') {
            $plan=Get-PlotPlan $registry $configuration $plot -Overrides $overrides
            return [pscustomobject]@{ProtocolVersion=1;Steps=@($plan | ForEach-Object { [pscustomobject]@{Id=$_.Id;Step=$_.Step.Id;Sources=$_.Sources} })}
        }
        $directory=(Get-Location).Path; if ($Request.ContainsKey('WorkDirectory')) { $directory=$Request.WorkDirectory }
        $preview=$WhatIfPreference -or ($Request.ContainsKey('WhatIf') -and $Request.WhatIf)
        # The engine applies preview at every step and returns a normal Skipped result.
        Invoke-Plot $registry $configuration $plot -Overrides $overrides -WorkDirectory $directory -WhatIf:$preview
    } finally { if ($null -ne $registry) { Remove-PlotRegistry $registry } }
}
Export-ModuleMember -Function Invoke-PlotRequest
