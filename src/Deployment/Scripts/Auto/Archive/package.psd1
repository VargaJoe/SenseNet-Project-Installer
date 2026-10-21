@{
    Name = 'archive'
    Version = '1.0.0'
    RootModule = 'Plot.Archive.psm1'
    Steps = @{
        pack = @{
            Command = 'New-PlotArchive'; Description='Create a ZIP archive from a directory.'; Outputs=@{Path=@{Description='Path on the runner, relative to its work directory unless absolute.'; Type='string'};Files=@{Description='Files (int).'; Type='int'};Bytes=@{Description='Bytes (int).'; Type='int'}}
            Parameters = @{
                Source = @{ Description='Source path on the runner.'; Type='string'; Required=$true }
                Destination = @{ Description='Destination path on the runner.'; Type='string'; Required=$true }
                Overwrite = @{ Description='Explicitly allow replacement of an existing destination.'; Type='bool'; Default=$false }
            }
        }
        unpack = @{
            Command = 'Expand-PlotArchive'; Description='Safely extract a ZIP after validating all entries.'; Outputs=@{Path=@{Description='Path on the runner, relative to its work directory unless absolute.'; Type='string'};Files=@{Description='Files (int).'; Type='int'}}
            Parameters = @{
                Source = @{ Description='Source path on the runner.'; Type='string'; Required=$true }
                Destination = @{ Description='Destination path on the runner.'; Type='string'; Required=$true }
                Overwrite = @{ Description='Explicitly allow replacement of an existing destination.'; Type='bool'; Default=$false }
            }
        }
    }
}
