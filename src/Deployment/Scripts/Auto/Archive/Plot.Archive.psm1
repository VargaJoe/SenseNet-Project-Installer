#requires -Version 5.1
Set-StrictMode -Version Latest
function Resolve-ArchivePath {
    param([string]$Path,$Context)
    if ([string]::IsNullOrWhiteSpace($Path)) { throw 'Path must not be empty.' }
    if ([IO.Path]::IsPathRooted($Path)) { return [IO.Path]::GetFullPath($Path) }
    return [IO.Path]::GetFullPath((Join-Path $Context.WorkDirectory $Path))
}
function Assert-ArchivePlainPath {
    param([string]$Path)
    $current=$Path
    while ($current) {
        $item=Get-Item -LiteralPath $current -Force -ErrorAction SilentlyContinue
        if ($null -ne $item -and ($item.Attributes -band [IO.FileAttributes]::ReparsePoint)) { throw "Links are not supported: $current" }
        $current=[IO.Path]::GetDirectoryName($current)
    }
}
function Initialize-Zip {
    Add-Type -AssemblyName System.IO.Compression -ErrorAction Stop
    Add-Type -AssemblyName System.IO.Compression.FileSystem -ErrorAction Stop
}
function New-PlotArchive {
    [CmdletBinding(SupportsShouldProcess)]
    param([Parameter(Mandatory)][hashtable]$Settings,[Parameter(Mandatory)]$Context)
    $source=(Resolve-ArchivePath $Settings.Source $Context).TrimEnd('\','/') + [IO.Path]::DirectorySeparatorChar
    $destination=Resolve-ArchivePath $Settings.Destination $Context
    $comparison=if ([Environment]::OSVersion.Platform -eq [PlatformID]::Win32NT) { [StringComparison]::OrdinalIgnoreCase } else { [StringComparison]::Ordinal }
    Assert-ArchivePlainPath $source
    Assert-ArchivePlainPath $destination
    if (-not [IO.Directory]::Exists($source)) { throw "Source directory not found: $source" }
    if ($destination.StartsWith($source,$comparison)) { throw 'Archive destination must be outside the source directory.' }
    if ([IO.Directory]::Exists($destination) -or ([IO.File]::Exists($destination) -and -not $Settings.Overwrite)) { throw "Destination already exists: $destination" }
    $pending=[Collections.Generic.Queue[string]]::new()
    $items=[Collections.Generic.List[object]]::new()
    $pending.Enqueue($source)
    while ($pending.Count) {
        foreach ($item in Get-ChildItem -LiteralPath $pending.Dequeue() -Force -ErrorAction Stop) {
            if ($item.Attributes -band [IO.FileAttributes]::ReparsePoint) { throw "Links are not supported: $($item.FullName)" }
            $items.Add($item)
            if ($item.PSIsContainer) { $pending.Enqueue($item.FullName) }
        }
    }
    if ($PSCmdlet.ShouldProcess($destination,"Create ZIP from $source")) {
        Initialize-Zip
        $temp=Join-Path ([IO.Path]::GetDirectoryName($destination)) ('.plot-zip-' + [guid]::NewGuid().ToString('N'))
        $stream=$null; $zip=$null; $count=0
        try {
            $stream=[IO.File]::Open($temp,[IO.FileMode]::CreateNew)
            $zip=[IO.Compression.ZipArchive]::new($stream,[IO.Compression.ZipArchiveMode]::Create,$true)
            foreach ($item in $items) {
                $name=$item.FullName.Substring($source.Length).Replace('\','/')
                if ($item.PSIsContainer) { $null=$zip.CreateEntry($name+'/') }
                else { $null=[IO.Compression.ZipFileExtensions]::CreateEntryFromFile($zip,$item.FullName,$name,[IO.Compression.CompressionLevel]::Optimal); $count++ }
            }
            $zip.Dispose(); $zip=$null
            $stream.Dispose(); $stream=$null
            if ($Settings.Overwrite -and [IO.File]::Exists($destination)) { [IO.File]::Replace($temp,$destination,[NullString]::Value) }
            else { [IO.File]::Move($temp,$destination) }
        } finally {
            if ($null -ne $zip) { $zip.Dispose() }
            if ($null -ne $stream) { $stream.Dispose() }
            if ([IO.File]::Exists($temp)) { [IO.File]::Delete($temp) }
        }
        [pscustomobject]@{Path=$destination;Files=$count;Bytes=(Get-Item -LiteralPath $destination).Length}
    }
}
function Expand-PlotArchive {
    [CmdletBinding(SupportsShouldProcess)]
    param([Parameter(Mandatory)][hashtable]$Settings,[Parameter(Mandatory)]$Context)
    $source=Resolve-ArchivePath $Settings.Source $Context
    $destination=Resolve-ArchivePath $Settings.Destination $Context
    Assert-ArchivePlainPath $destination
    if ([IO.File]::Exists($destination)) { throw "Destination is a file: $destination" }
    $root=$destination.TrimEnd('\','/') + [IO.Path]::DirectorySeparatorChar
    $windows=[Environment]::OSVersion.Platform -eq [PlatformID]::Win32NT
    $comparison=if ($windows) { [StringComparison]::OrdinalIgnoreCase } else { [StringComparison]::Ordinal }
    $comparer=if ($windows) { [StringComparer]::OrdinalIgnoreCase } else { [StringComparer]::Ordinal }
    Initialize-Zip
    $stream=[IO.File]::OpenRead($source)
    $zip=$null
    try {
        $zip=[IO.Compression.ZipArchive]::new($stream,[IO.Compression.ZipArchiveMode]::Read,$true)
        $entries=[Collections.Generic.List[object]]::new()
        $targets=[Collections.Generic.HashSet[string]]::new($comparer)
        $files=[Collections.Generic.HashSet[string]]::new($comparer)
        # Validate every entry and destination conflict before writing any output.
        foreach ($entry in $zip.Entries) {
            $name=$entry.FullName.Replace('\','/')
            if ([string]::IsNullOrWhiteSpace($name) -or $name.StartsWith('/') -or $name.Contains(':') -or
                @($name.Split('/') | Where-Object { $_ -eq '..' -or $_ -eq '.' }).Count) { throw "Unsafe archive entry: $name" }
            if ((($entry.ExternalAttributes -shr 16) -band 0xF000) -eq 0xA000) { throw "Archive links are not supported: $name" }
            $path=[IO.Path]::GetFullPath((Join-Path $root $name))
            if (-not $path.StartsWith($root,$comparison) -or $path.TrimEnd('\','/').Equals($root.TrimEnd('\','/'),$comparison)) { throw "Unsafe archive entry: $name" }
            $path=$path.TrimEnd('\','/')
            if (-not $targets.Add($path)) { throw "Duplicate archive target: $name" }
            $directory=$name.EndsWith('/')
            Assert-ArchivePlainPath $path
            if ($directory -and [IO.File]::Exists($path)) { throw "Destination is a file: $path" }
            if (-not $directory) {
                $null=$files.Add($path)
                if ([IO.Directory]::Exists($path) -or ([IO.File]::Exists($path) -and -not $Settings.Overwrite)) { throw "Destination already exists: $path" }
            }
            $entries.Add([pscustomobject]@{Entry=$entry;Path=$path;Directory=$directory})
        }
        foreach ($target in $entries) {
            $parent=[IO.Path]::GetDirectoryName($target.Path)
            while ($parent -and $parent.StartsWith($root,$comparison)) {
                if ($files.Contains($parent) -or [IO.File]::Exists($parent)) { throw "Archive parent is a file: $parent" }
                $parent=[IO.Path]::GetDirectoryName($parent)
            }
        }
        if ($PSCmdlet.ShouldProcess($destination,"Extract ZIP $source")) {
            $null=[IO.Directory]::CreateDirectory($destination)
            $count=0
            foreach ($target in $entries) {
                if ($target.Directory) { $null=[IO.Directory]::CreateDirectory($target.Path); continue }
                $null=[IO.Directory]::CreateDirectory([IO.Path]::GetDirectoryName($target.Path))
                $mode=if ($Settings.Overwrite) { [IO.FileMode]::Create } else { [IO.FileMode]::CreateNew }
                $inputStream=$target.Entry.Open()
                $outputStream=$null
                try {
                    $outputStream=[IO.File]::Open($target.Path,$mode,[IO.FileAccess]::Write,[IO.FileShare]::None)
                    $inputStream.CopyTo($outputStream)
                } finally {
                    if ($null -ne $outputStream) { $outputStream.Dispose() }
                    $inputStream.Dispose()
                }
                $count++
            }
            [pscustomobject]@{Path=$destination;Files=$count}
        }
    } finally { if ($null -ne $zip) { $zip.Dispose() }; $stream.Dispose() }
}
Export-ModuleMember -Function New-PlotArchive, Expand-PlotArchive
