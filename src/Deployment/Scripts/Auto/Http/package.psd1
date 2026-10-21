@{
 Name='http'; Version='1.0.0'; RootModule='Plot.Http.psm1'
 Steps=@{
  download=@{Command='Save-PlotDownload'; Description='Download to a file with an optional SHA-256 verification.'; Outputs=@{Path=@{Description='Path on the runner, relative to its work directory unless absolute.'; Type='string'};Bytes=@{Description='Bytes (int).'; Type='int'};Sha256=@{Description='Sha256 (string).'; Type='string'};StatusCode=@{Description='StatusCode (int).'; Type='int'}};Parameters=@{
   Url=@{Description='Url (string).'; Type='string';Required=$true;Secret=$true}; Headers=@{Description='Headers (object).'; Type='object';Default=@{};Secret=$true}
   Destination=@{Description='Destination path on the runner.'; Type='string';Required=$true}; Sha256=@{Description='Sha256 (string).'; Type='string';Default=''}; Overwrite=@{Description='Explicitly allow replacement of an existing destination.'; Type='bool';Default=$false}
   MaxBytes=@{Description='MaxBytes (int).'; Type='int';Default=1073741824;Minimum=1}; TimeoutSeconds=@{Description='Maximum operation duration in seconds.'; Type='int';Default=300;Minimum=1;Maximum=86400}
  }}
  wait=@{Command='Wait-PlotHttp'; Description='Actively wait for an accepted HTTP status.'; Outputs=@{StatusCode=@{Description='StatusCode (int).'; Type='int'};Attempts=@{Description='Attempts (int).'; Type='int'};DurationMilliseconds=@{Description='DurationMilliseconds (int).'; Type='int'}};Parameters=@{
   Url=@{Description='Url (string).'; Type='string';Required=$true;Secret=$true}; Headers=@{Description='Headers (object).'; Type='object';Default=@{};Secret=$true}
   StatusCodes=@{Description='StatusCodes (array).'; Type='array';Default=@(200)}; TimeoutSeconds=@{Description='Maximum operation duration in seconds.'; Type='int';Default=60;Minimum=1;Maximum=86400}
   RequestTimeoutSeconds=@{Description='RequestTimeoutSeconds (int).'; Type='int';Default=5;Minimum=1;Maximum=86400}; IntervalMilliseconds=@{Description='IntervalMilliseconds (int).'; Type='int';Default=500;Minimum=1;Maximum=60000}
  }}
  'wait-tcp'=@{Command='Wait-PlotTcp'; Description='Actively wait for a TCP connection.'; Outputs=@{HostName=@{Description='HostName (string).'; Type='string'};Port=@{Description='Port (int).'; Type='int'};Attempts=@{Description='Attempts (int).'; Type='int'};DurationMilliseconds=@{Description='DurationMilliseconds (int).'; Type='int'}};Parameters=@{
   HostName=@{Description='HostName (string).'; Type='string';Required=$true}; Port=@{Description='Port (int).'; Type='int';Required=$true;Minimum=1;Maximum=65535}
   TimeoutSeconds=@{Description='Maximum operation duration in seconds.'; Type='int';Default=60;Minimum=1;Maximum=86400}; IntervalMilliseconds=@{Description='IntervalMilliseconds (int).'; Type='int';Default=500;Minimum=1;Maximum=60000}
  }}
 }
}
