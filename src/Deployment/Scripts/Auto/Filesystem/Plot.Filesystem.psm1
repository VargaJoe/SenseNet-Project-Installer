#requires -Version 5.1
Set-StrictMode -Version Latest
function Resolve-FilePath {
    param([string]$Path, $Context)
    if ([IO.Path]::IsPathRooted($Path)) { return [IO.Path]::GetFullPath($Path) }
    return [IO.Path]::GetFullPath((Join-Path $Context.WorkDirectory $Path))
}
function Write-PlotFile {
    [CmdletBinding(SupportsShouldProcess)]
    param([Parameter(Mandatory)][hashtable]$Settings, [Parameter(Mandatory)]$Context)
    $path = Resolve-FilePath $Settings.Path $Context
    if ($PSCmdlet.ShouldProcess($path, 'Write UTF-8 file')) {
        $mode = if ($Settings.Overwrite) { [IO.FileMode]::Create } else { [IO.FileMode]::CreateNew }
        $stream = [IO.File]::Open($path, $mode, [IO.FileAccess]::Write, [IO.FileShare]::None)
        try {
            $bytes = [Text.UTF8Encoding]::new($false).GetBytes($Settings.Content)
            $stream.Write($bytes, 0, $bytes.Length)
        } finally { $stream.Dispose() }
        [pscustomobject]@{ Path=$path; Bytes=$bytes.Length }
    }
}
function Copy-PlotFile {
    [CmdletBinding(SupportsShouldProcess)]
    param([Parameter(Mandatory)][hashtable]$Settings, [Parameter(Mandatory)]$Context)
    $source = Resolve-FilePath $Settings.Source $Context
    $destination = Resolve-FilePath $Settings.Destination $Context
    if ($PSCmdlet.ShouldProcess($destination, "Copy file from $source")) {
        [IO.File]::Copy($source, $destination, $Settings.Overwrite)
        [pscustomobject]@{ Path=$destination; Bytes=(Get-Item -LiteralPath $destination -ErrorAction Stop).Length }
    }
}
Export-ModuleMember -Function Write-PlotFile, Copy-PlotFile
