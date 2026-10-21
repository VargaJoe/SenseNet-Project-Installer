function ConvertFrom-PlotJsonText {
    param([Parameter(Mandatory)][string]$Text)
    # Windows PowerShell preserves JSON strings. New PowerShell exposes an explicit policy.
    if ($PSVersionTable.PSVersion.Major -le 5) { return ($Text | ConvertFrom-Json -ErrorAction Stop) }
    if ((Get-Command ConvertFrom-Json).Parameters.ContainsKey('DateKind')) {
        return ($Text | ConvertFrom-Json -DateKind String -ErrorAction Stop)
    }
    # PS6 / PS7 before 7.5: use the JSON library bundled with that PowerShell host.
    Add-Type -Path (Join-Path $PSHOME 'Newtonsoft.Json.dll') -ErrorAction Stop
    function Convert-JsonToken($Token) {
        switch ([string]$Token.get_Type()) {
            Object {
                $object=@{}
                foreach ($property in $Token.Properties()) { $object[$property.Name]=Convert-JsonToken $property.Value }
                return $object
            }
            Array {
                $items=[Collections.Generic.List[object]]::new()
                foreach ($item in $Token.Children()) { $items.Add((Convert-JsonToken $item)) }
                return ,$items.ToArray()
            }
            default { return $Token.Value }
        }
    }
    $inputReader=[IO.StringReader]::new($Text)
    $reader=[Newtonsoft.Json.JsonTextReader]::new($inputReader)
    try {
        $reader.DateParseHandling=[Newtonsoft.Json.DateParseHandling]::None
        $token=[Newtonsoft.Json.Linq.JToken]::ReadFrom($reader)
        if ($reader.Read()) { throw 'Unexpected content after JSON document.' }
        return (Convert-JsonToken $token)
    } finally { $reader.Close(); $inputReader.Dispose() }
}
