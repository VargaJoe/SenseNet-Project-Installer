#requires -Version 5.1
Set-StrictMode -Version Latest
function Resolve-XmlPath {
    param([string]$Path,$Context)
    if ([string]::IsNullOrWhiteSpace($Path)) { throw 'Path must not be empty.' }
    if ([IO.Path]::IsPathRooted($Path)) { return [IO.Path]::GetFullPath($Path) }
    return [IO.Path]::GetFullPath((Join-Path $Context.WorkDirectory $Path))
}
function Set-PlotXml {
    [CmdletBinding(SupportsShouldProcess)]
    param([Parameter(Mandatory)][hashtable]$Settings,[Parameter(Mandatory)]$Context)
    $source=Resolve-XmlPath $Settings.Source $Context
    $destination=Resolve-XmlPath $Settings.Destination $Context
    if ([IO.Directory]::Exists($destination) -or ([IO.File]::Exists($destination) -and -not $Settings.Overwrite)) { throw "Destination already exists: $destination" }
    $readerSettings=[Xml.XmlReaderSettings]::new()
    $readerSettings.DtdProcessing=[Xml.DtdProcessing]::Prohibit
    $readerSettings.XmlResolver=$null
    $document=[Xml.XmlDocument]::new()
    $document.PreserveWhitespace=$true
    $document.XmlResolver=$null
    $reader=[Xml.XmlReader]::Create($source,$readerSettings)
    try { $document.Load($reader) } finally { $reader.Dispose() }
    $namespaces=[Xml.XmlNamespaceManager]::new($document.NameTable)
    foreach ($prefix in $Settings.Namespaces.Keys) {
        if ([string]::IsNullOrWhiteSpace($prefix) -or $Settings.Namespaces[$prefix] -isnot [string] -or [string]::IsNullOrWhiteSpace($Settings.Namespaces[$prefix])) { throw 'Namespaces must map nonempty prefixes to URI strings.' }
        $namespaces.AddNamespace($prefix,$Settings.Namespaces[$prefix])
    }
    $nodes=$document.SelectNodes($Settings.XPath,$namespaces)
    if ($nodes.Count -ne 1) { throw "XPath must select exactly one node; matched $($nodes.Count)." }
    $node=$nodes[0]
    if ($node -is [Xml.XmlAttribute]) { $node.Value=$Settings.Value }
    elseif ($node -is [Xml.XmlElement]) {
        if (@($node.ChildNodes | Where-Object { $_ -is [Xml.XmlElement] }).Count) { throw 'XPath must select an attribute or a leaf element.' }
        $node.InnerText=$Settings.Value
    } else { throw 'XPath must select an attribute or a leaf element.' }
    if ($PSCmdlet.ShouldProcess($destination,'Write updated XML')) {
        $temp=Join-Path ([IO.Path]::GetDirectoryName($destination)) ('.plot-xml-' + [guid]::NewGuid().ToString('N'))
        $writer=$null
        try {
            $writerSettings=[Xml.XmlWriterSettings]::new()
            $writerSettings.Encoding=[Text.UTF8Encoding]::new($false)
            $writer=[Xml.XmlWriter]::Create($temp,$writerSettings)
            $document.Save($writer)
            $writer.Dispose(); $writer=$null
            if ($Settings.Overwrite -and [IO.File]::Exists($destination)) { [IO.File]::Replace($temp,$destination,[NullString]::Value) }
            else { [IO.File]::Move($temp,$destination) }
        } finally {
            if ($null -ne $writer) { $writer.Dispose() }
            if ([IO.File]::Exists($temp)) { [IO.File]::Delete($temp) }
        }
        [pscustomobject]@{Path=$destination;Updated=1}
    }
}
Export-ModuleMember -Function Set-PlotXml
