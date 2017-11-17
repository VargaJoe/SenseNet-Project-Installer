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

Write-Verbose "================================================" 
Write-Verbose "CREATE IIS SITE"
Write-Verbose "================================================"

Import-Module WebAdministration  -Verbose:$false

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
		Write-Verbose "Create the $iisAppPoolName application pool"
		$appPool = New-Item $iisAppPoolName
		$appPool | Set-ItemProperty -Name "managedRuntimeVersion" -Value $DotNetVersion
	} else {
		Write-Verbose "$iisAppPoolName application pool already exists"
	}

	#navigate to the sites root
	cd IIS:\Sites\

	#check if the site exists
	if (!(Test-Path $iisAppName -pathType container)){
		
		Write-Verbose "Create the $iisAppName site"
		Write-Verbose "Site webfolder: $DirectoryPath"
		Write-Verbose "Site host: $iisAppName:80"
		$iisApp = New-Item $iisAppName -bindings @{protocol="http";bindingInformation="*:80:" + $iisAppName} -physicalPath $DirectoryPath
		$iisApp | Set-ItemProperty -Name "applicationPool" -Value $iisAppPoolName
		
		foreach ($hostUrl in $SiteHosts) {
			$HostnameToLower = $hostUrl.ToLower()
			if ($null -ne (get-webbinding | where-object {$_.bindinginformation -eq "*:80:$HostnameToLower"}))
			{
				Write-Verbose "$HostnameToLower:80 is already a binding"
			}
			else
			{
				New-WebBinding -Name $iisAppName -Port 80 -Protocol http -HostHeader $HostnameToLower 
				Write-Verbose "$HostnameToLower:80 is now a binding"
			}
			
			# if ($null -ne (get-webbinding | where-object {$_.bindinginformation -eq "*:443:$HostnameToLower"}))
			# {
				# Write-Verbose "$HostnameToLower:443 is already a binding"
			# }
			# else
			# {
				# New-WebBinding -Name $iisAppName -Port 443 -Protocol http -HostHeader $HostnameToLower 
				# Write-Verbose "$HostnameToLower:443 is now a binding"
			# }			
		}	
	} else {
		Write-Verbose "$iisAppName site already exists"
		return
	}
}
finally
{
	Set-Location $location
}