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
    Assert-IisName $site
    $pool = if ($Settings.ContainsKey('AppPoolName') -and -not [string]::IsNullOrWhiteSpace($Settings.AppPoolName)) { $Settings.AppPoolName } else { $site }
    Assert-IisName $pool
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

function Assert-IisName([string]$Name) {
    if ([string]::IsNullOrWhiteSpace($Name) -or $Name -match '[\\/\[\]*?:\x00]') { throw 'IIS names must be nonempty literal names without path or wildcard characters.' }
}
function New-PlotIisSite {
    [CmdletBinding(SupportsShouldProcess)] param([hashtable]$Settings,$Context)
    Assert-IisName $Settings.WebsiteName; Assert-IisName $Settings.AppPoolName
    $path=$Settings.PhysicalPath
    if (-not [IO.Path]::IsPathRooted($path)) { $path=Join-Path $Context.WorkDirectory $path }
    $path=[IO.Path]::GetFullPath($path)
    if (-not [IO.Directory]::Exists($path)) { throw 'IIS physical directory must already exist.' }
    if ($Settings.HostHeader -match '[:/\\\s]' -or $Settings.IPAddress -notmatch '^(\*|[0-9.]+)$') { throw 'Supply an HTTP host name and IPv4 address or *.' }
    if (-not $PSCmdlet.ShouldProcess($Settings.WebsiteName,'Create IIS HTTP site and application pool')) { return }
    Import-Module WebAdministration -ErrorAction Stop
    if ($null -ne (Get-Website -Name $Settings.WebsiteName -ErrorAction Stop)) { throw 'IIS website already exists; creation does not overwrite sites.' }
    $binding=$Settings.IPAddress+':'+$Settings.Port+':'+$Settings.HostHeader
    if (@(Get-WebBinding -Protocol http -ErrorAction Stop | Where-Object { $_.bindingInformation -eq $binding }).Count) { throw 'IIS HTTP binding is already assigned.' }
    $poolPath='IIS:\AppPools\'+$Settings.AppPoolName
    if (Test-Path -LiteralPath $poolPath) { throw 'Application pool already exists; use a new dedicated pool name.' }
    $null=New-WebAppPool -Name $Settings.AppPoolName -ErrorAction Stop
    Set-ItemProperty -LiteralPath $poolPath -Name managedRuntimeVersion -Value $Settings.RuntimeVersion -ErrorAction Stop
    Set-ItemProperty -LiteralPath $poolPath -Name managedPipelineMode -Value $Settings.PipelineMode -ErrorAction Stop
    $null=New-Website -Name $Settings.WebsiteName -PhysicalPath $path -ApplicationPool $Settings.AppPoolName -IPAddress $Settings.IPAddress -Port $Settings.Port -HostHeader $Settings.HostHeader -ErrorAction Stop
    [pscustomobject]@{WebsiteName=$Settings.WebsiteName;AppPoolName=$Settings.AppPoolName;PhysicalPath=$path;Binding=$binding}
}
function Get-PlotIisStatus {
    [CmdletBinding(SupportsShouldProcess)] param([hashtable]$Settings,$Context)
    Assert-IisName $Settings.WebsiteName
    if ($PSCmdlet.ShouldProcess($Settings.WebsiteName,'Read IIS site status')) {
        Import-Module WebAdministration -ErrorAction Stop
        $site=Get-Website -Name $Settings.WebsiteName -ErrorAction Stop
        if ($null -eq $site) { throw 'IIS website does not exist.' }
        $pool=Get-WebAppPoolState -Name $site.applicationPool -ErrorAction Stop
        [pscustomobject]@{WebsiteName=$site.Name;State=[string]$site.State;AppPoolName=$site.applicationPool;AppPoolState=[string]$pool.Value;PhysicalPath=$site.physicalPath}
    }
}
function Restart-PlotIisPool {
    [CmdletBinding(SupportsShouldProcess)] param([hashtable]$Settings,$Context)
    Assert-IisName $Settings.AppPoolName
    if ($PSCmdlet.ShouldProcess($Settings.AppPoolName,'Recycle IIS application pool')) {
        Import-Module WebAdministration -ErrorAction Stop
        Restart-WebAppPool -Name $Settings.AppPoolName -ErrorAction Stop
        Wait-IisState { (Get-WebAppPoolState -Name $Settings.AppPoolName -ErrorAction Stop).Value } Started $Settings.TimeoutSeconds $Settings.PollMilliseconds "pool '$($Settings.AppPoolName)'"
        [pscustomobject]@{AppPoolName=$Settings.AppPoolName;State='Started'}
    }
}
Export-ModuleMember -Function Start-PlotIisSite,Stop-PlotIisSite,New-PlotIisSite,Get-PlotIisStatus,Restart-PlotIisPool
