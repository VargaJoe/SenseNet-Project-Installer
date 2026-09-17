@{
    Name = 'json'
    Version = '1.0.0'
    RootModule = 'Plot.Json.psm1'
    Steps = @{
        read = @{
            Command = 'Read-PlotJson'
            Parameters = @{ Path = @{ Type='string'; Required=$true } }
        }
        write = @{
            Command = 'Write-PlotJson'
            Parameters = @{
                Path = @{ Type='string'; Required=$true }
                Value = @{ Type='object'; Required=$true }
                Overwrite = @{ Type='bool'; Default=$false }
            }
        }
        merge = @{
            Command = 'Merge-PlotJson'
            Parameters = @{ Paths = @{ Type='array'; Required=$true } }
        }
    }
}
