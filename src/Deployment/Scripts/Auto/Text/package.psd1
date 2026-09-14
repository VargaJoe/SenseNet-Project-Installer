@{
    Name = 'text'
    Version = '1.0.0'
    RootModule = 'Plot.Text.psm1'
    Steps = @{
        join = @{
            Command = 'Join-PlotText'
            Parameters = @{
                Items = @{ Type='array'; Required=$true }
                Separator = @{ Type='string'; Default=' ' }
            }
        }
    }
}
