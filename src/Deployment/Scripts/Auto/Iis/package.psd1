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

        create = @{ Command='New-PlotIisSite'; Parameters=@{
            WebsiteName=@{Type='string';Required=$true}; AppPoolName=@{Type='string';Required=$true}
            PhysicalPath=@{Type='string';Required=$true}; Port=@{Type='int';Default=80;Minimum=1;Maximum=65535}
            IPAddress=@{Type='string';Default='*'}; HostHeader=@{Type='string';Default=''}
            RuntimeVersion=@{Type='string';Default='';ValidateSet=@('','v2.0','v4.0')}
            PipelineMode=@{Type='string';Default='Integrated';ValidateSet=@('Integrated','Classic')}
        }}
        status = @{ Command='Get-PlotIisStatus'; Parameters=@{WebsiteName=@{Type='string';Required=$true}}}
        recycle = @{ Command='Restart-PlotIisPool'; Parameters=@{
            AppPoolName=@{Type='string';Required=$true}; TimeoutSeconds=@{Type='int';Default=30;Minimum=1;Maximum=3600}
            PollMilliseconds=@{Type='int';Default=200;Minimum=1;Maximum=10000}
        }}
    }
}
