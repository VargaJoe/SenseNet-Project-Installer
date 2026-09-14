#requires -Version 5.1
function Join-PlotText {
    [CmdletBinding()]
    param([Parameter(Mandatory)][hashtable]$Settings, [Parameter(Mandatory)]$Context)
    [pscustomobject]@{ Text=($Settings.Items -join $Settings.Separator) }
}
Export-ModuleMember -Function Join-PlotText
