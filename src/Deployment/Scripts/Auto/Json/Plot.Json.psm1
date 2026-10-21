#requires -Version 5.1
Set-StrictMode -Version Latest
. (Join-Path $PSScriptRoot 'JsonText.ps1')
function Resolve-JsonPath {
    param([string]$Path,$Context)
    if ([string]::IsNullOrWhiteSpace($Path)) { throw 'Path must not be empty.' }
    if ([IO.Path]::IsPathRooted($Path)) { return [IO.Path]::GetFullPath($Path) }
    return [IO.Path]::GetFullPath((Join-Path $Context.WorkDirectory $Path))
}
function Copy-JsonValue {
    param([AllowNull()]$Value)
    if ($null -eq $Value) { return $null }
    if ($Value -is [System.Collections.IDictionary]) {
        $copy=@{}
        foreach ($key in $Value.Keys) { $copy[[string]$key]=Copy-JsonValue $Value[$key] }
        return $copy
    }
    if ($Value -is [pscustomobject]) {
        $copy=@{}
        foreach ($property in $Value.PSObject.Properties) { $copy[$property.Name]=Copy-JsonValue $property.Value }
        return $copy
    }
    if ($Value -is [array]) {
        $copy=[Collections.Generic.List[object]]::new()
        foreach ($item in $Value) { $copy.Add((Copy-JsonValue $item)) }
        return ,$copy.ToArray()
    }
    return $Value
}
function Read-JsonObject {
    param([string]$Path)
    $json=[IO.File]::ReadAllText($Path,[Text.Encoding]::UTF8)
    if ([string]::IsNullOrWhiteSpace($json) -or -not $json.TrimStart().StartsWith('{')) { throw "JSON root must be an object: $Path" }
    $value=Copy-JsonValue (ConvertFrom-PlotJsonText $json)
    if ($value -isnot [hashtable]) { throw "JSON root must be an object: $Path" }
    return $value
}
function Merge-JsonObject {
    param([hashtable]$Base,[hashtable]$Override)
    $merged=Copy-JsonValue $Base
    foreach ($key in $Override.Keys) {
        if ($merged.ContainsKey($key) -and $merged[$key] -is [hashtable] -and $Override[$key] -is [hashtable]) {
            $merged[$key]=Merge-JsonObject $merged[$key] $Override[$key]
        } else { $merged[$key]=Copy-JsonValue $Override[$key] }
    }
    return $merged
}
function Read-PlotJson {
    [CmdletBinding()]
    param([Parameter(Mandatory)][hashtable]$Settings,[Parameter(Mandatory)]$Context)
    $path=Resolve-JsonPath $Settings.Path $Context
    [pscustomobject]@{Path=$path;Value=(Read-JsonObject $path)}
}
function Write-PlotJson {
    [CmdletBinding(SupportsShouldProcess)]
    param([Parameter(Mandatory)][hashtable]$Settings,[Parameter(Mandatory)]$Context)
    $path=Resolve-JsonPath $Settings.Path $Context
    if ([IO.Directory]::Exists($path) -or ([IO.File]::Exists($path) -and -not $Settings.Overwrite)) { throw "Destination already exists: $path" }
    # Serialization completes before touching the destination. Treat truncation warnings as failures.
    $json=ConvertTo-Json -InputObject $Settings.Value -Depth 100 -ErrorAction Stop -WarningAction Stop
    if ($PSCmdlet.ShouldProcess($path,'Write UTF-8 JSON object')) {
        $temp=Join-Path ([IO.Path]::GetDirectoryName($path)) ('.plot-json-' + [guid]::NewGuid().ToString('N'))
        try {
            [IO.File]::WriteAllText($temp,$json,[Text.UTF8Encoding]::new($false))
            if ($Settings.Overwrite -and [IO.File]::Exists($path)) { [IO.File]::Replace($temp,$path,[NullString]::Value) }
            else { [IO.File]::Move($temp,$path) }
        } finally { if ([IO.File]::Exists($temp)) { [IO.File]::Delete($temp) } }
        [pscustomobject]@{Path=$path;Bytes=(Get-Item -LiteralPath $path).Length}
    }
}
function Merge-PlotJson {
    [CmdletBinding()]
    param([Parameter(Mandatory)][hashtable]$Settings,[Parameter(Mandatory)]$Context)
    if (-not $Settings.Paths.Count) { throw 'Paths must contain at least one JSON file.' }
    $paths=[Collections.Generic.List[string]]::new()
    $merged=@{}
    foreach ($file in $Settings.Paths) {
        if ($file -isnot [string]) { throw 'Each Paths entry must be a string.' }
        $path=Resolve-JsonPath $file $Context
        $paths.Add($path)
        $merged=Merge-JsonObject $merged (Read-JsonObject $path)
    }
    [pscustomobject]@{Paths=$paths.ToArray();Value=$merged}
}
Export-ModuleMember -Function Read-PlotJson, Write-PlotJson, Merge-PlotJson
