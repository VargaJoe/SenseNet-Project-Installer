@{ Name='git'; Version='1.0.0'; RootModule='Plot.Git.psm1'; Dependencies=@('process'); Steps=@{
clone=@{Command='Invoke-PlotGitClone';Parameters=@{Repository=@{Type='string';Required=$true;Secret=$true}; Destination=@{Type='string';Required=$true}; Branch=@{Type='string';Default=''};TimeoutSeconds=@{Type='int';Default=300;Minimum=1;Maximum=86400}; Environment=@{Type='object';Default=@{};Secret=$true}}}
fetch=@{Command='Invoke-PlotGitFetch';Parameters=@{Directory=@{Type='string';Required=$true}; Remote=@{Type='string';Default='origin';Secret=$true};TimeoutSeconds=@{Type='int';Default=300;Minimum=1;Maximum=86400}; Environment=@{Type='object';Default=@{};Secret=$true}}}
checkout=@{Command='Invoke-PlotGitCheckout';Parameters=@{Directory=@{Type='string';Required=$true}; Ref=@{Type='string';Required=$true};TimeoutSeconds=@{Type='int';Default=300;Minimum=1;Maximum=86400}; Environment=@{Type='object';Default=@{};Secret=$true}}}
}}
