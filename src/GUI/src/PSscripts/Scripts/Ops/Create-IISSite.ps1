[CmdletBinding(SupportsShouldProcess=$True)]
Param(
[Parameter(Mandatory=$true)]
[string]$DirectoryPath,
[Parameter(Mandatory=$true)]
[string]$SiteName,
[Parameter(Mandatory=$false)]
[string]$PoolName = $SiteName,
[Parameter(Mandatory=$false)]
[string[]]$SiteHosts = "$SiteName",
[Parameter(Mandatory=$false)]
[string]$DotNetVersion = "v4.0"
)

Write-Host ================================================ -foregroundcolor "green"
Write-Host CREATE IIS SITE -foregroundcolor "green"
Write-Host ================================================ -foregroundcolor "green"

Import-Module WebAdministration
$iisAppPoolName = $PoolName.ToLower()
$iisAppName = $SiteName.ToLower()

$location = Get-Location
try
{
	#navigate to the app pools root
	cd IIS:\AppPools\

	#check if the app pool doesn't exists
	if (!(Test-Path $iisAppPoolName -pathType container))
	{
		Write-Host Create the $iisAppPoolName application pool
		$appPool = New-Item $iisAppPoolName
		$appPool | Set-ItemProperty -Name "managedRuntimeVersion" -Value $DotNetVersion
	} else {
		Write-Host $iisAppPoolName application pool already exists
	}

	#navigate to the sites root
	cd IIS:\Sites\

	#check if the site exists
	if (!(Test-Path $iisAppName -pathType container)){
		
		Write-Host Create the $iisAppName site
		Write-Host Site webfolder: $DirectoryPath
		Write-Host Site host: $iisAppName":80"
		$iisApp = New-Item $iisAppName -bindings @{protocol="http";bindingInformation="*:80:" + $iisAppName} -physicalPath $DirectoryPath
		$iisApp | Set-ItemProperty -Name "applicationPool" -Value $iisAppPoolName
		
		foreach ($hostUrl in $SiteHosts) {
			$HostnameToLower = $hostUrl.ToLower()
			if ($null -ne (get-webbinding | where-object {$_.bindinginformation -eq "*:80:$HostnameToLower"}))
			{
				Write-Host $HostnameToLower":80 is already a binding"
			}
			else
			{
				New-WebBinding -Name $iisAppName -Port 80 -Protocol http -HostHeader $HostnameToLower 
				Write-Host $HostnameToLower":80 is now a binding"
			}
			
			# if ($null -ne (get-webbinding | where-object {$_.bindinginformation -eq "*:443:$HostnameToLower"}))
			# {
				# Write-Host $HostnameToLower":443 is already a binding"
			# }
			# else
			# {
				# New-WebBinding -Name $iisAppName -Port 443 -Protocol http -HostHeader $HostnameToLower 
				# Write-Host $HostnameToLower":443 is now a binding"
			# }			
		}	
	} else {
		Write-Host $iisAppName site already exists	
		return
	}
}
finally
{
	Set-Location $location
}