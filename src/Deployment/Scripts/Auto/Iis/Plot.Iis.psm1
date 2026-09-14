#requires -Version 5.1
Set-StrictMode -Version Latest
function Wait-IisState {
    param([scriptblock]$ReadState, [string]$Desired, [int]$TimeoutSeconds, [int]$PollMilliseconds, [string]$Target)
    $timer = [Diagnostics.Stopwatch]::StartNew()
    do {
        if ((& $ReadState) -eq $Desired) { return }
        if ($timer.Elapsed.TotalSeconds -ge $TimeoutSeconds) { throw "Timeout waiting for $Target to be $Desired." }
        Start-Sleep -Milliseconds $PollMilliseconds
    } while ($true)
}
function Set-PlotIisState {
    [CmdletBinding(SupportsShouldProcess)]
    param([hashtable]$Settings, [ValidateSet('Started','Stopped')][string]$Desired)
    $site = [string]$Settings.WebsiteName
    if ([string]::IsNullOrWhiteSpace($site)) { throw 'WebsiteName is required.' }
    $pool = if ($Settings.ContainsKey('AppPoolName') -and -not [string]::IsNullOrWhiteSpace($Settings.AppPoolName)) { $Settings.AppPoolName } else { $site }
    $timeout = if ($Settings.ContainsKey('TimeoutSeconds')) { [int]$Settings.TimeoutSeconds } else { 30 }
    $poll = if ($Settings.ContainsKey('PollMilliseconds')) { [int]$Settings.PollMilliseconds } else { 200 }
    if ($timeout -lt 1 -or $poll -lt 1) { throw 'TimeoutSeconds and PollMilliseconds must be positive.' }
    if (-not $PSCmdlet.ShouldProcess("$site / $pool", "Set IIS state to $Desired")) { return }
    Import-Module WebAdministration -ErrorAction Stop
    $website = Get-Website -Name $site -ErrorAction Stop
    if ($null -eq $website) { throw "IIS website '$site' does not exist." }
    $null = Get-WebAppPoolState -Name $pool -ErrorAction Stop
    if ($Desired -eq 'Started') {
        if ((Get-WebAppPoolState -Name $pool -ErrorAction Stop).Value -ne $Desired) { Start-WebAppPool -Name $pool -ErrorAction Stop }
        Wait-IisState { (Get-WebAppPoolState -Name $pool -ErrorAction Stop).Value } $Desired $timeout $poll "pool '$pool'"
        if ((Get-Website -Name $site -ErrorAction Stop).State -ne $Desired) { Start-Website -Name $site -ErrorAction Stop }
        Wait-IisState { (Get-Website -Name $site -ErrorAction Stop).State } $Desired $timeout $poll "site '$site'"
    } else {
        if ($website.State -ne $Desired) { Stop-Website -Name $site -ErrorAction Stop }
        Wait-IisState { (Get-Website -Name $site -ErrorAction Stop).State } $Desired $timeout $poll "site '$site'"
        if ((Get-WebAppPoolState -Name $pool -ErrorAction Stop).Value -ne $Desired) { Stop-WebAppPool -Name $pool -ErrorAction Stop }
        Wait-IisState { (Get-WebAppPoolState -Name $pool -ErrorAction Stop).Value } $Desired $timeout $poll "pool '$pool'"
    }
    [pscustomobject]@{ WebsiteName=$site; AppPoolName=$pool; State=$Desired }
}
function Start-PlotIisSite {
    [CmdletBinding(SupportsShouldProcess)]
    param([Parameter(Mandatory)][hashtable]$Settings, [Parameter(Mandatory)]$Context)
    Set-PlotIisState -Settings $Settings -Desired Started
}
function Stop-PlotIisSite {
    [CmdletBinding(SupportsShouldProcess)]
    param([Parameter(Mandatory)][hashtable]$Settings, [Parameter(Mandatory)]$Context)
    Set-PlotIisState -Settings $Settings -Desired Stopped
}
Export-ModuleMember -Function Start-PlotIisSite, Stop-PlotIisSite
