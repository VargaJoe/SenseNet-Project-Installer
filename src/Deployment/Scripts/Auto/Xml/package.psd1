@{
    Name = 'xml'
    Version = '1.0.0'
    RootModule = 'Plot.Xml.psm1'
    Steps = @{
        set = @{
            Command = 'Set-PlotXml'
            Parameters = @{
                Source = @{ Type='string'; Required=$true }
                Destination = @{ Type='string'; Required=$true }
                XPath = @{ Type='string'; Required=$true }
                Value = @{ Type='string'; Required=$true }
                Namespaces = @{ Type='object'; Default=@{} }
                Overwrite = @{ Type='bool'; Default=$false }
            }
        }
    }
}
