@{
    Name = 'xml'
    Version = '1.0.0'
    RootModule = 'Plot.Xml.psm1'
    Steps = @{
        set = @{
            Command = 'Set-PlotXml'; Description='Update an XML attribute or leaf selected by XPath.'; Outputs=@{Path=@{Description='Path on the runner, relative to its work directory unless absolute.'; Type='string'};Updated=@{Description='Updated (int).'; Type='int'}}
            Parameters = @{
                Source = @{ Description='Source path on the runner.'; Type='string'; Required=$true }
                Destination = @{ Description='Destination path on the runner.'; Type='string'; Required=$true }
                XPath = @{ Description='XPath (string).'; Type='string'; Required=$true }
                Value = @{ Description='Value (string).'; Type='string'; Required=$true }
                Namespaces = @{ Description='Namespaces (object).'; Type='object'; Default=@{} }
                Overwrite = @{ Description='Explicitly allow replacement of an existing destination.'; Type='bool'; Default=$false }
            }
        }
    }
}
