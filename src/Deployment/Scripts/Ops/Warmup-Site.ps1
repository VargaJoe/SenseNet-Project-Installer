param (
   [Parameter(Mandatory=$True)]
   [string]$siteName
)

$url = "https://$siteName"

[Net.ServicePointManager]::SecurityProtocol = "tls12, tls11, tls"
$response = Invoke-WebRequest -URI $url -UseBasicParsing -TimeoutSec 240
if ($response.StatusCode -eq 200)
{
	Write-Output "Site $url successfully started" 
	exit 0
}
else
{
	Write-Output "Site $url failed to start with http error: $response" 
	exit 1
}
