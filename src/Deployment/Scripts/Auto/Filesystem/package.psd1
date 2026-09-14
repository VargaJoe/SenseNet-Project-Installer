@{
    Name = 'filesystem'
    Version = '1.0.0'
    RootModule = 'Plot.Filesystem.psm1'
    Steps = @{
        write = @{
            Command = 'Write-PlotFile'
            Parameters = @{
                Path = @{ Type='string'; Required=$true }
                Content = @{ Type='string'; Default='' }
                Overwrite = @{ Type='bool'; Default=$false }
            }
        }
        copy = @{
            Command = 'Copy-PlotFile'
            Parameters = @{
                Source = @{ Type='string'; Required=$true }
                Destination = @{ Type='string'; Required=$true }
                Overwrite = @{ Type='bool'; Default=$false }
            }
        }
    }
}
