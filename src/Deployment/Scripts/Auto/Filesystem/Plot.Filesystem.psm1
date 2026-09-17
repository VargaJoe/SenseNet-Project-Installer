#requires -Version 5.1
Set-StrictMode -Version Latest
function Resolve-FilePath {
    param([string]$Path, $Context)
    if ([string]::IsNullOrWhiteSpace($Path)) { throw 'Path must not be empty.' }
    if ([IO.Path]::IsPathRooted($Path)) { return [IO.Path]::GetFullPath($Path) }
    return [IO.Path]::GetFullPath((Join-Path $Context.WorkDirectory $Path))
}
function Assert-PlainPath {
    param([string]$Path)
    $current = $Path
    while ($current) {
        $item = Get-Item -LiteralPath $current -Force -ErrorAction SilentlyContinue
        if ($null -ne $item -and ($item.Attributes -band [IO.FileAttributes]::ReparsePoint)) { throw "Links are not supported: $current" }
        $current = [IO.Path]::GetDirectoryName($current)
    }
}
function Get-DirectoryInventory {
    param([string]$Root)
    Assert-PlainPath $Root
    if (-not [IO.Directory]::Exists($Root)) { throw "Directory not found: $Root" }
    $pending = [Collections.Generic.Queue[string]]::new()
    $items = [Collections.Generic.List[object]]::new()
    $pending.Enqueue($Root)
    while ($pending.Count) {
        foreach ($item in Get-ChildItem -LiteralPath $pending.Dequeue() -Force -ErrorAction Stop) {
            if ($item.Attributes -band [IO.FileAttributes]::ReparsePoint) { throw "Links are not supported: $($item.FullName)" }
            $items.Add($item)
            if ($item.PSIsContainer) { $pending.Enqueue($item.FullName) }
        }
    }
    return ,$items.ToArray()
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
function Read-PlotFile {
    [CmdletBinding()]
    param([Parameter(Mandatory)][hashtable]$Settings, [Parameter(Mandatory)]$Context)
    $path = Resolve-FilePath $Settings.Path $Context
    [pscustomobject]@{ Path=$path; Content=[IO.File]::ReadAllText($path,[Text.Encoding]::UTF8) }
}
function New-PlotDirectory {
    [CmdletBinding(SupportsShouldProcess)]
    param([Parameter(Mandatory)][hashtable]$Settings, [Parameter(Mandatory)]$Context)
    $path = Resolve-FilePath $Settings.Path $Context
    Assert-PlainPath $path
    $existed = [IO.Directory]::Exists($path)
    if ($PSCmdlet.ShouldProcess($path, 'Create directory')) {
        $null = [IO.Directory]::CreateDirectory($path)
        [pscustomobject]@{ Path=$path; Created=(-not $existed) }
    }
}
function Copy-PlotDirectory {
    [CmdletBinding(SupportsShouldProcess)]
    param([Parameter(Mandatory)][hashtable]$Settings, [Parameter(Mandatory)]$Context)
    $source = (Resolve-FilePath $Settings.Source $Context).TrimEnd('\','/')
    $destination = (Resolve-FilePath $Settings.Destination $Context).TrimEnd('\','/')
    $comparison = if ([Environment]::OSVersion.Platform -eq [PlatformID]::Win32NT) { [StringComparison]::OrdinalIgnoreCase } else { [StringComparison]::Ordinal }
    if ($source -eq [IO.Path]::GetPathRoot($source).TrimEnd('\','/') -or $destination -eq [IO.Path]::GetPathRoot($destination).TrimEnd('\','/')) {
        throw 'Directory copy requires paths below the filesystem root.'
    }
    $separator = [IO.Path]::DirectorySeparatorChar
    if ($source.Equals($destination,$comparison) -or $destination.StartsWith($source+$separator,$comparison) -or $source.StartsWith($destination+$separator,$comparison)) {
        throw 'Source and destination directories must not overlap.'
    }
    Assert-PlainPath $destination
    if ([IO.File]::Exists($destination)) { throw "Destination is a file: $destination" }
    $items = Get-DirectoryInventory $source
    # Check all destination conflicts before copying the first file.
    foreach ($item in $items) {
        $target = Join-Path $destination $item.FullName.Substring($source.Length+1)
        Assert-PlainPath $target
        if ($item.PSIsContainer -and [IO.File]::Exists($target)) { throw "Destination is a file: $target" }
        if (-not $item.PSIsContainer -and ([IO.Directory]::Exists($target) -or ([IO.File]::Exists($target) -and -not $Settings.Overwrite))) {
            throw "Destination already exists: $target"
        }
    }
    if ($PSCmdlet.ShouldProcess($destination, "Copy directory tree from $source")) {
        $null = [IO.Directory]::CreateDirectory($destination)
        $count = 0
        foreach ($item in $items) {
            $target = Join-Path $destination $item.FullName.Substring($source.Length+1)
            if ($item.PSIsContainer) { $null = [IO.Directory]::CreateDirectory($target) }
            else {
                $null = [IO.Directory]::CreateDirectory([IO.Path]::GetDirectoryName($target))
                [IO.File]::Copy($item.FullName,$target,$Settings.Overwrite)
                $count++
            }
        }
        [pscustomobject]@{ Path=$destination; Files=$count }
    }
}
function Remove-PlotPath {
    [CmdletBinding(SupportsShouldProcess)]
    param([Parameter(Mandatory)][hashtable]$Settings, [Parameter(Mandatory)]$Context)
    $path = Resolve-FilePath $Settings.Path $Context
    $root = (Resolve-FilePath $Settings.Root $Context).TrimEnd('\','/') + [IO.Path]::DirectorySeparatorChar
    $comparison = if ([Environment]::OSVersion.Platform -eq [PlatformID]::Win32NT) { [StringComparison]::OrdinalIgnoreCase } else { [StringComparison]::Ordinal }
    if (-not $path.StartsWith($root,$comparison) -or $path.TrimEnd('\','/').Equals($root.TrimEnd('\','/'),$comparison)) {
        throw 'Removal target must be strictly inside Root; removing Root itself is not allowed.'
    }
    Assert-PlainPath $path
    $item = Get-Item -LiteralPath $path -Force -ErrorAction SilentlyContinue
    if ($null -eq $item) {
        if (-not $Settings.MissingOk) { throw "Path not found: $path" }
        return [pscustomobject]@{ Path=$path; Removed=$false }
    }
    if ($item.PSIsContainer) {
        $items = Get-DirectoryInventory $path
        if ($items.Count -and -not $Settings.Recurse) { throw 'Nonempty directory requires Recurse.' }
    }
    if ($PSCmdlet.ShouldProcess($path, 'Remove path within the explicit root')) {
        if ($item.PSIsContainer) { [IO.Directory]::Delete($path,$Settings.Recurse) }
        else { [IO.File]::Delete($path) }
        [pscustomobject]@{ Path=$path; Removed=$true }
    }
}
function Get-PlotFileHash {
    [CmdletBinding()]
    param([Parameter(Mandatory)][hashtable]$Settings, [Parameter(Mandatory)]$Context)
    $path = Resolve-FilePath $Settings.Path $Context
    $stream = [IO.File]::OpenRead($path)
    $algorithm = [Security.Cryptography.SHA256]::Create()
    try { $hash = [BitConverter]::ToString($algorithm.ComputeHash($stream)).Replace('-','').ToLowerInvariant() }
    finally { $algorithm.Dispose(); $stream.Dispose() }
    [pscustomobject]@{ Path=$path; Algorithm='SHA256'; Hash=$hash }
}
Export-ModuleMember -Function Write-PlotFile, Copy-PlotFile, Read-PlotFile, New-PlotDirectory, Copy-PlotDirectory, Remove-PlotPath, Get-PlotFileHash
