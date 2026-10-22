@{
    Name = 'filesystem'
    Version = '1.1.0'
    RootModule = 'Plot.Filesystem.psm1'
    Steps = @{
        write = @{
            Command = 'Write-PlotFile'; Description='Write a UTF-8 file; replacement is explicit.'; Outputs=@{Path=@{Description='Path on the runner, relative to its work directory unless absolute.'; Type='string'};Bytes=@{Description='Bytes (int).'; Type='int'}}
            Parameters = @{
                Path = @{ Description='Path on the runner, relative to its work directory unless absolute.'; Type='string'; Required=$true }
                Content = @{ Description='Content to write; accepts a settings or earlier-output reference.'; Type='string'; Default='' }
                Overwrite = @{ Description='Explicitly allow replacement of an existing destination.'; Type='bool'; Default=$false }
            }
        }
        copy = @{
            Command = 'Copy-PlotFile'; Description='Copy one file.'; Outputs=@{Path=@{Description='Path on the runner, relative to its work directory unless absolute.'; Type='string'};Bytes=@{Description='Bytes (int).'; Type='int'}}
            Parameters = @{
                Source = @{ Description='Source path on the runner.'; Type='string'; Required=$true }
                Destination = @{ Description='Destination path on the runner.'; Type='string'; Required=$true }
                Overwrite = @{ Description='Explicitly allow replacement of an existing destination.'; Type='bool'; Default=$false }
            }
        }
        read = @{
            Command = 'Read-PlotFile'; Description='Read a UTF-8 file.'; Outputs=@{Path=@{Description='Path on the runner, relative to its work directory unless absolute.'; Type='string'};Content=@{Description='Content to write; accepts a settings or earlier-output reference.'; Type='string'}}
            Parameters = @{ Path = @{ Description='Path on the runner, relative to its work directory unless absolute.'; Type='string'; Required=$true } }
        }
        mkdir = @{
            Command = 'New-PlotDirectory'; Description='Create a directory and its missing parents.'; Outputs=@{Path=@{Description='Path on the runner, relative to its work directory unless absolute.'; Type='string'};Created=@{Description='Created (bool).'; Type='bool'}}
            Parameters = @{ Path = @{ Description='Path on the runner, relative to its work directory unless absolute.'; Type='string'; Required=$true } }
        }
        'copy-tree' = @{
            Command = 'Copy-PlotDirectory'; Description='Copy a directory tree without following links.'; Outputs=@{Path=@{Description='Path on the runner, relative to its work directory unless absolute.'; Type='string'};Files=@{Description='Files (int).'; Type='int'}}
            Parameters = @{
                Source = @{ Description='Source path on the runner.'; Type='string'; Required=$true }
                Destination = @{ Description='Destination path on the runner.'; Type='string'; Required=$true }
                Overwrite = @{ Description='Explicitly allow replacement of an existing destination.'; Type='bool'; Default=$false }
            }
        }
        remove = @{
            Command = 'Remove-PlotPath'; Description='Remove a path strictly inside the explicit safety root.'; Outputs=@{Path=@{Description='Path on the runner, relative to its work directory unless absolute.'; Type='string'};Removed=@{Description='Removed (bool).'; Type='bool'}}
            Parameters = @{
                Path = @{ Description='Path on the runner, relative to its work directory unless absolute.'; Type='string'; Required=$true }
                Root = @{ Description='Explicit safety boundary on the runner filesystem.'; Type='string'; Required=$true }
                Recurse = @{ Description='Recurse (bool).'; Type='bool'; Default=$false }
                MissingOk = @{ Description='MissingOk (bool).'; Type='bool'; Default=$false }
            }
        }
        hash = @{
            Command = 'Get-PlotFileHash'; Description='Compute a SHA-256 file checksum.'; Outputs=@{Path=@{Description='Path on the runner, relative to its work directory unless absolute.'; Type='string'};Algorithm=@{Description='Algorithm (string).'; Type='string'};Hash=@{Description='Hash (string).'; Type='string'}}
            Parameters = @{ Path = @{ Description='Path on the runner, relative to its work directory unless absolute.'; Type='string'; Required=$true } }
        }
    }
}
