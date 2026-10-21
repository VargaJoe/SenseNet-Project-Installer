@{
    Name = 'filesystem'
    Version = '1.1.0'
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
        read = @{
            Command = 'Read-PlotFile'
            Parameters = @{ Path = @{ Type='string'; Required=$true } }
        }
        mkdir = @{
            Command = 'New-PlotDirectory'
            Parameters = @{ Path = @{ Type='string'; Required=$true } }
        }
        'copy-tree' = @{
            Command = 'Copy-PlotDirectory'
            Parameters = @{
                Source = @{ Type='string'; Required=$true }
                Destination = @{ Type='string'; Required=$true }
                Overwrite = @{ Type='bool'; Default=$false }
            }
        }
        remove = @{
            Command = 'Remove-PlotPath'
            Parameters = @{
                Path = @{ Type='string'; Required=$true }
                Root = @{ Type='string'; Required=$true }
                Recurse = @{ Type='bool'; Default=$false }
                MissingOk = @{ Type='bool'; Default=$false }
            }
        }
        hash = @{
            Command = 'Get-PlotFileHash'
            Parameters = @{ Path = @{ Type='string'; Required=$true } }
        }
    }
}
