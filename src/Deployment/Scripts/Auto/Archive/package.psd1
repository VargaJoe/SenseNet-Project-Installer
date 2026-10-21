@{
    Name = 'archive'
    Version = '1.0.0'
    RootModule = 'Plot.Archive.psm1'
    Steps = @{
        pack = @{
            Command = 'New-PlotArchive'
            Parameters = @{
                Source = @{ Type='string'; Required=$true }
                Destination = @{ Type='string'; Required=$true }
                Overwrite = @{ Type='bool'; Default=$false }
            }
        }
        unpack = @{
            Command = 'Expand-PlotArchive'
            Parameters = @{
                Source = @{ Type='string'; Required=$true }
                Destination = @{ Type='string'; Required=$true }
                Overwrite = @{ Type='bool'; Default=$false }
            }
        }
    }
}
