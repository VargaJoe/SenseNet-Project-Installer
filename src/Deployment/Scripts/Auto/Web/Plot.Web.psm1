#requires -Version 5.1
Set-StrictMode -Version Latest
function Get-MaintenancePath($Settings,$Context) {
    $directory=$Settings.Directory
    if (-not [IO.Path]::IsPathRooted($directory)) { $directory=Join-Path $Context.WorkDirectory $directory }
    $directory=[IO.Path]::GetFullPath($directory)
    if (-not [IO.Directory]::Exists($directory)) { throw 'Web directory does not exist.' }
    Join-Path $directory 'app_offline.htm'
}
function Set-PlotWebOffline {
    [CmdletBinding(SupportsShouldProcess)] param([hashtable]$Settings,$Context)
    $path=Get-MaintenancePath $Settings $Context
    if ($PSCmdlet.ShouldProcess($path,'Create maintenance page without overwriting an existing page')) {
        $bytes=[Text.Encoding]::UTF8.GetBytes($Settings.Content)
        $stream=[IO.File]::Open($path,[IO.FileMode]::CreateNew,[IO.FileAccess]::Write,[IO.FileShare]::None)
        try { $stream.Write($bytes,0,$bytes.Length) } finally { $stream.Dispose() }
        [pscustomobject]@{Path=$path;Offline=$true}
    }
}
function Set-PlotWebOnline {
    [CmdletBinding(SupportsShouldProcess)] param([hashtable]$Settings,$Context)
    $path=Get-MaintenancePath $Settings $Context
    if ($PSCmdlet.ShouldProcess($path,'Remove maintenance page')) { [IO.File]::Delete($path); [pscustomobject]@{Path=$path;Offline=$false} }
}
Export-ModuleMember -Function Set-PlotWebOffline,Set-PlotWebOnline
