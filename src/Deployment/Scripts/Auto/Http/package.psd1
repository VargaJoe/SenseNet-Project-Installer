@{
 Name='http'; Version='1.0.0'; RootModule='Plot.Http.psm1'
 Steps=@{
  download=@{Command='Save-PlotDownload';Parameters=@{
   Url=@{Type='string';Required=$true;Secret=$true}; Headers=@{Type='object';Default=@{};Secret=$true}
   Destination=@{Type='string';Required=$true}; Sha256=@{Type='string';Default=''}; Overwrite=@{Type='bool';Default=$false}
   MaxBytes=@{Type='int';Default=1073741824;Minimum=1}; TimeoutSeconds=@{Type='int';Default=300;Minimum=1;Maximum=86400}
  }}
  wait=@{Command='Wait-PlotHttp';Parameters=@{
   Url=@{Type='string';Required=$true;Secret=$true}; Headers=@{Type='object';Default=@{};Secret=$true}
   StatusCodes=@{Type='array';Default=@(200)}; TimeoutSeconds=@{Type='int';Default=60;Minimum=1;Maximum=86400}
   RequestTimeoutSeconds=@{Type='int';Default=5;Minimum=1;Maximum=86400}; IntervalMilliseconds=@{Type='int';Default=500;Minimum=1;Maximum=60000}
  }}
  'wait-tcp'=@{Command='Wait-PlotTcp';Parameters=@{
   HostName=@{Type='string';Required=$true}; Port=@{Type='int';Required=$true;Minimum=1;Maximum=65535}
   TimeoutSeconds=@{Type='int';Default=60;Minimum=1;Maximum=86400}; IntervalMilliseconds=@{Type='int';Default=500;Minimum=1;Maximum=60000}
  }}
 }
}
