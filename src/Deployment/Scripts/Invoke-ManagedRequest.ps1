#requires -Version 5.1
[CmdletBinding()]
param([Parameter(Mandatory)][string]$RequestPath,[Parameter(Mandatory)][string]$ResponsePath,[string]$EventPath,[string]$AutoPath)
$ErrorActionPreference='Stop'
if (-not $AutoPath) { $AutoPath=Join-Path $PSScriptRoot 'Auto' }
$VerbosePreference='SilentlyContinue'; $InformationPreference='SilentlyContinue'; $ProgressPreference='SilentlyContinue'
try {
    Import-Module (Join-Path $PSScriptRoot 'Core/PlotManager.psm1') -ErrorAction Stop
    $request=Copy-PlotValue (ConvertFrom-PlotJsonText ([IO.File]::ReadAllText([IO.Path]::GetFullPath($RequestPath))))
    if ($request -isnot [hashtable]) { throw 'Request must be a JSON object.' }
    Import-Module (Join-Path $PSScriptRoot 'Core/PlotManagement.psm1') -ErrorAction Stop
    $callback=$null
    if ($EventPath) {
        $eventFile=[IO.Path]::GetFullPath($EventPath)
        $callback={ param($event) [IO.File]::AppendAllText($eventFile,($event | ConvertTo-Json -Depth 12 -Compress)+[Environment]::NewLine,[Text.UTF8Encoding]::new($false)) }.GetNewClosure()
    }
    $result=Invoke-ManagedPlotRequest $request -AutoPath $AutoPath -OnEvent $callback
    [IO.File]::WriteAllText([IO.Path]::GetFullPath($ResponsePath),($result | ConvertTo-Json -Depth 90),[Text.UTF8Encoding]::new($false))
    if (($result -is [hashtable] -and $result.ContainsKey('Status') -and $result.Status -eq 'Failed') -or ($result -isnot [hashtable] -and $result.PSObject.Properties['Status'] -and $result.Status -eq 'Failed')) { exit 1 }
    exit 0
} catch {
    # Do not place uncontrolled exception text / child streams in a hosted response.
    $message=$_.Exception.Message
    if ($null -ne $request) {
        $secrets=[Collections.Generic.HashSet[string]]::new([StringComparer]::Ordinal)
        $module=Get-Module PlotManagement
        if ($module) {
            & $module { param($v,$s) Find-ManagedSecrets $v $s } $request $secrets
            foreach ($file in @($request.ConfigurationFiles)) {
                try { $data=Read-PlotConfiguration @($file); & $module { param($v,$s) Find-ManagedSecrets $v $s } $data $secrets } catch { }
            }
            foreach ($secret in $secrets) { $message=$message.Replace($secret,'[redacted]') }
        }
    }
    [IO.File]::WriteAllText([IO.Path]::GetFullPath($ResponsePath),(@{Status='Failed';Error=$message} | ConvertTo-Json -Depth 8),[Text.UTF8Encoding]::new($false))
    exit 1
}
