[CmdletBinding(SupportsShouldProcess=$True)]
Param (
	[Parameter(Mandatory=$false)]
	[string]$nugetVersion = "4.1.0"
)



try {
	$WebClient = New-Object System.Net.WebClient
	$WebClient.DownloadFile("https://www.nuget.org/api/v2/package/SenseNet.Services.Install/7.0.0-beta4",".\download1.zip")	
	$WebClient.DownloadFile("https://www.nuget.org/api/v2/package/SenseNet.Services/7.0.0-beta4",".\download2.zip")	
	$WebClient.DownloadFile("https://www.nuget.org/api/v2/package/Newtonsoft.Json/9.0.1",".\download3.zip")	
	$WebClient.DownloadFile("https://www.nuget.org/api/v2/package/Microsoft.IdentityModel.Tokens/5.1.3",".\download4.zip")	
	$WebClient.DownloadFile("https://www.nuget.org/api/v2/package/System.IdentityModel.Tokens.Jwt/5.1.3",".\download5.zip")	
	$WebClient.DownloadFile("https://www.nuget.org/api/v2/package/OpenPop.NET/2.0.6.1120",".\download6.zip")	
	$WebClient.DownloadFile("https://www.nuget.org/api/v2/package/SenseNet.Tools/2.1.1",".\download7.zip")	
	$WebClient.DownloadFile("https://www.nuget.org/api/v2/package/SenseNet.Preview/7.0.0-beta2",".\download8.zip")	
	$WebClient.DownloadFile("https://www.nuget.org/api/v2/package/SenseNet.BlobStorage/7.0.0-beta2",".\download9.zip")	
	$WebClient.DownloadFile("https://www.nuget.org/api/v2/package/SenseNet.Common/7.0.0-beta2",".\downloadx.zip")	
	$WebClient.DownloadFile("https://www.nuget.org/api/v2/package/SenseNet.Security.EF6SecurityStore/2.3.0",".\downloady.zip")	
	$WebClient.DownloadFile("https://www.nuget.org/api/v2/package/SenseNet.TaskManagement.Core/1.1.0",".\downloadz.zip")	
	
	
	
    exit 0
}
catch [exception] {
    Write-Host $_.Exception
    exit 1
}

