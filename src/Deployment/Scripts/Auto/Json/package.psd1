@{
    Name = 'json'
    Version = '1.0.0'
    RootModule = 'Plot.Json.psm1'
    Steps = @{
        read = @{
            Command = 'Read-PlotJson'; Description='Read a JSON object without changing string types.'; Outputs=@{Path=@{Description='Path on the runner, relative to its work directory unless absolute.'; Type='string'};Value=@{Description='Value (object).'; Type='object'}}
            Parameters = @{ Path = @{ Description='Path on the runner, relative to its work directory unless absolute.'; Type='string'; Required=$true } }
        }
        write = @{
            Command = 'Write-PlotJson'; Description='Write a JSON object.'; Outputs=@{Path=@{Description='Path on the runner, relative to its work directory unless absolute.'; Type='string'};Bytes=@{Description='Bytes (int).'; Type='int'}}
            Parameters = @{
                Path = @{ Description='Path on the runner, relative to its work directory unless absolute.'; Type='string'; Required=$true }
                Value = @{ Description='Value (object).'; Type='object'; Required=$true }
                Overwrite = @{ Description='Explicitly allow replacement of an existing destination.'; Type='bool'; Default=$false }
            }
        }
        merge = @{
            Command = 'Merge-PlotJson'; Description='Merge JSON objects with full array replacement.'; Outputs=@{Paths=@{Description='Paths (array).'; Type='array'};Value=@{Description='Value (object).'; Type='object'}}
            Parameters = @{ Paths = @{ Description='Paths (array).'; Type='array'; Required=$true } }
        }
    }
}
