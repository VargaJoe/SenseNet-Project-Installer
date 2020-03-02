[CmdletBinding(SupportsShouldProcess=$True)]
Param(
[Parameter(Mandatory=$true)]
[string]$WebsiteName,
[Parameter(Mandatory=$false)]
[string]$AppPoolName = $WebsiteName
)

$Computer = $env:computername

# ========= CONFIG ===================
$waitsecond = 3 # seconds
$timeout = 10 
# ====================================

Write-Verbose "================================================"
Write-Verbose "STOP WEBSITE AND APPLICATION POOL >> $WebsiteName"
Write-Verbose "================================================" 
Write-Verbose "Computer: $Computer" 
# CALL: .\StopWebsiteAppPool.ps1 "SiteName"

import-module WebAdministration -Verbose:$false

# IIS website stop function
Function fnStopWebsite([string]$WebsiteName)
{
	try{
		if((Get-Website -Name $WebsiteName).Name -eq $null)
		{
			# The website is not exist
			exit 0
		}
		else
		{
			if((Get-Website -name $WebsiteName).State -ne 'Stopped')
			{
				Stop-WebSite -Name $WebsiteName
				Start-Sleep -s $waitsecond
			}
		}
		
	}
	catch
	{
		$ErrorMessage = $MaximumErrorCount
		$functionname = $MyInvocation.MyCommand.Name
		Write-Verbose "[Error][$modulename : $functionname] => $ErrorMessage"
		exit 6
	}
}

# Application Pool stop function
Function fnStopApplicationPool([string]$AppPoolName)
{
	try{
		if((Get-WebAppPoolState -Name $AppPoolName).Name -eq $null)
		{
			# The application pool is not exist
			exit 0
		}
		else
		{
			if((Get-WebAppPoolState $AppPoolName).Value -ne 'Stopped')
			{
				Stop-WebAppPool -Name $AppPoolName
				Start-Sleep -s $waitsecond
			}
		}
	}
	catch{
		$ErrorMessage = $_.Exception.Message
		$functionname = $MyInvocation.MyCommand.Name
		Write-Verbose "[Error][$modulename : $functionname] => $ErrorMessage"
		exit 7
	}
}

#fnStopWebsite($WebsiteName) # stop site
$statusSite = Get-Website -name $WebsiteName

$Websitesuccess = $false
$currentRetry = 0
do
{
	if ($statusSite.State -eq "Stopped"){
		Write-Verbose "The '$WebsiteName' website has been stopped..."
		$Websitesuccess = $true;
	}
	else{
		fnStopWebsite($WebsiteName) # stop site
		$currentRetry = $currentRetry + 1;
	}
}
while (!$Websitesuccess -and $currentRetry -le $timeout)
if($currentRetry -gt $timeout)
{
	Write-Error "The '$WebsiteName' website can't be stopped"
	exit 8
}

#fnStopApplicationPool($AppPoolName) # stop application pool
$statusPool = Get-WebAppPoolState $AppPoolName
$Poolsuccess = $false
$currentRetry = 0
do
{
	if ($statusPool.Value -eq "Stopped"){
		Write-Verbose "The '$AppPoolName' application pool has been stopped..."
		$Poolsuccess = $true;
	}
	else{
		fnStopApplicationPool($AppPoolName) # stop application pool
		$currentRetry = $currentRetry + 1;
	}
}
while (!$Poolsuccess -and $currentRetry -le $timeout)
if($currentRetry -gt $timeout)
{
	Write-Verbose "The '$AppPoolName' application pool can't bee stopped"
	exit 9
}

if($Poolsuccess -and  $Websitesuccess)
{
 exit 0
}