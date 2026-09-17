@{ Name='docker'; Version='1.0.0'; RootModule='Plot.Docker.psm1'; Dependencies=@('process'); Steps=@{
cli=@{Command='Invoke-PlotDocker';Parameters=@{Command=@{Type='string';Required=$true;ValidateSet=@('build','pull','push','tag','run','start','stop','rm','inspect','network-create','network-inspect','network-connect','network-disconnect','network-rm')}; Directory=@{Type='string';Default='.'}; Arguments=@{Type='array';Default=@();Secret=$true};TimeoutSeconds=@{Type='int';Default=300;Minimum=1;Maximum=86400}; Environment=@{Type='object';Default=@{};Secret=$true}}}
}}
