@{
    Name = 'iis'
    Version = '1.0.0'
    Platform = 'Windows'
    RootModule = 'Plot.Iis.psm1'
    Steps = @{
        start = @{
            Command = 'Start-PlotIisSite'
            Aliases = @('System-Start')
            Parameters = @{
                WebsiteName = @{ Type='string'; Required=$true }
                AppPoolName = @{ Type='string'; AllowNull=$true; Default=$null }
                TimeoutSeconds = @{ Type='int'; Default=30; Minimum=1; Maximum=3600 }
                PollMilliseconds = @{ Type='int'; Default=200; Minimum=1; Maximum=10000 }
            }
        }
        stop = @{
            Command = 'Stop-PlotIisSite'
            Aliases = @('System-Stop')
            Parameters = @{
                WebsiteName = @{ Type='string'; Required=$true }
                AppPoolName = @{ Type='string'; AllowNull=$true; Default=$null }
                TimeoutSeconds = @{ Type='int'; Default=30; Minimum=1; Maximum=3600 }
                PollMilliseconds = @{ Type='int'; Default=200; Minimum=1; Maximum=10000 }
            }
        }
    }
}
