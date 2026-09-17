@{ Name='web'; Version='1.0.0'; RootModule='Plot.Web.psm1';  Steps=@{
'offline'=@{Command='Set-PlotWebOffline';Parameters=@{Directory=@{Type='string';Required=$true}; Content=@{Type='string';Default='Maintenance in progress.'}}}
'online'=@{Command='Set-PlotWebOnline';Parameters=@{Directory=@{Type='string';Required=$true}}}
}}
