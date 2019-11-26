param (
   [Parameter(Mandatory=$false)]
   [string]$siteName,
   [Parameter(Mandatory=$false)]
   [string]$siteUrl = "https://$siteName"
)

[Net.ServicePointManager]::SecurityProtocol = "tls12, tls11, tls"
$response = Invoke-WebRequest -URI $siteUrl -UseBasicParsing -TimeoutSec 240
if ($response.StatusCode -eq 200)
{
	Write-Output "Site $siteUrl successfully started" 
	exit 0
}
else
{
	Write-Output "Site $siteUrl failed to start with http error: $response" 
	exit 1
}
