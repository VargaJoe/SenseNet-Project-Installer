@{
    Name = 'text'
    Version = '1.0.0'
    RootModule = 'Plot.Text.psm1'
    Steps = @{
        join = @{
            Command = 'Join-PlotText'; Description='Join ordered text items with a separator.'; Outputs=@{Text=@{Description='Text (string).'; Type='string'}}
            Parameters = @{
                Items = @{ Description='Ordered items; arrays replace inherited arrays in full.'; Type='array'; Required=$true }
                Separator = @{ Description='Text inserted between items.'; Type='string'; Default=' ' }
            }
        }
    }
}
