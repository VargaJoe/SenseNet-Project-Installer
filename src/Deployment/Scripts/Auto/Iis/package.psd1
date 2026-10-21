@{
    Name = 'iis'
    Version = '1.0.0'
    Platform = 'Windows'
    RootModule = 'Plot.Iis.psm1'
    Steps = @{
        start = @{
            Command = 'Start-PlotIisSite'; Description='Start an IIS pool and website.'; Outputs=@{WebsiteName=@{Description='WebsiteName (string).'; Type='string'};AppPoolName=@{Description='AppPoolName (string).'; Type='string'};State=@{Description='State (string).'; Type='string'}}
            Aliases = @('System-Start')
            Parameters = @{
                WebsiteName = @{ Description='WebsiteName (string).'; Type='string'; Required=$true }
                AppPoolName = @{ Description='AppPoolName (string).'; Type='string'; AllowNull=$true; Default=$null }
                TimeoutSeconds = @{ Description='Maximum operation duration in seconds.'; Type='int'; Default=30; Minimum=1; Maximum=3600 }
                PollMilliseconds = @{ Description='PollMilliseconds (int).'; Type='int'; Default=200; Minimum=1; Maximum=10000 }
            }
        }
        stop = @{
            Command = 'Stop-PlotIisSite'; Description='Stop an IIS website and pool.'; Outputs=@{WebsiteName=@{Description='WebsiteName (string).'; Type='string'};AppPoolName=@{Description='AppPoolName (string).'; Type='string'};State=@{Description='State (string).'; Type='string'}}
            Aliases = @('System-Stop')
            Parameters = @{
                WebsiteName = @{ Description='WebsiteName (string).'; Type='string'; Required=$true }
                AppPoolName = @{ Description='AppPoolName (string).'; Type='string'; AllowNull=$true; Default=$null }
                TimeoutSeconds = @{ Description='Maximum operation duration in seconds.'; Type='int'; Default=30; Minimum=1; Maximum=3600 }
                PollMilliseconds = @{ Description='PollMilliseconds (int).'; Type='int'; Default=200; Minimum=1; Maximum=10000 }
            }
        }

        create = @{ Command='New-PlotIisSite'; Description='Provision an IIS website with a dedicated pool.'; Outputs=@{WebsiteName=@{Description='WebsiteName (string).'; Type='string'};AppPoolName=@{Description='AppPoolName (string).'; Type='string'};PhysicalPath=@{Description='PhysicalPath (string).'; Type='string'};Binding=@{Description='Binding (string).'; Type='string'}}; Parameters=@{
            WebsiteName=@{Description='WebsiteName (string).'; Type='string';Required=$true}; AppPoolName=@{Description='AppPoolName (string).'; Type='string';Required=$true}
            PhysicalPath=@{Description='PhysicalPath (string).'; Type='string';Required=$true}; Port=@{Description='Port (int).'; Type='int';Default=80;Minimum=1;Maximum=65535}
            IPAddress=@{Description='IPAddress (string).'; Type='string';Default='*'}; HostHeader=@{Description='HostHeader (string).'; Type='string';Default=''}
            RuntimeVersion=@{Description='RuntimeVersion (string).'; Type='string';Default='';ValidateSet=@('','v2.0','v4.0')}
            PipelineMode=@{Description='PipelineMode (string).'; Type='string';Default='Integrated';ValidateSet=@('Integrated','Classic')}
        }}
        status = @{ Command='Get-PlotIisStatus'; Description='Read IIS site and pool state.'; Outputs=@{WebsiteName=@{Description='WebsiteName (string).'; Type='string'};State=@{Description='State (string).'; Type='string'};AppPoolName=@{Description='AppPoolName (string).'; Type='string'};AppPoolState=@{Description='AppPoolState (string).'; Type='string'};PhysicalPath=@{Description='PhysicalPath (string).'; Type='string'}}; Parameters=@{WebsiteName=@{Description='WebsiteName (string).'; Type='string';Required=$true}}}
        recycle = @{ Command='Restart-PlotIisPool'; Description='Recycle the selected IIS pool.'; Outputs=@{AppPoolName=@{Description='AppPoolName (string).'; Type='string'};State=@{Description='State (string).'; Type='string'}}; Parameters=@{
            AppPoolName=@{Description='AppPoolName (string).'; Type='string';Required=$true}; TimeoutSeconds=@{Description='Maximum operation duration in seconds.'; Type='int';Default=30;Minimum=1;Maximum=3600}
            PollMilliseconds=@{Description='PollMilliseconds (int).'; Type='int';Default=200;Minimum=1;Maximum=10000}
        }}
    }
}
