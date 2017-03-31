[CmdletBinding(SupportsShouldProcess=$True)]
Param(
[Parameter(Mandatory=$true)]
[string]$WebsiteName
)

$Computer = $env:computername

#================================================
#====== STOP WEBSITE AND APPLICATION POOL =======
#================================================
# CALL: .\StopWebsiteAppPool.ps1 "SiteName"

# ========= CONFIG ===================
$waitsecond = 3 # seconds
$timeout = 10 
# ====================================

#Set-ExecutionPolicy Unrestricted  
Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass 
import-module WebAdministration

Write-Host ================================================ -foregroundcolor "green"
Write-Host STOP WEBSITE AND APPLICATION POOL ">>" $WebsiteName -foregroundcolor "green"
Write-Host ================================================ -foregroundcolor "green"
Write-Host $Computer 

# IIS website stop function
Function fnStopWebsite([string]$WebsiteName)
{
	try{
		if((Get-Website -Name $WebsiteName).Name -eq $null)
		{
			# The website is not exist
			exit 10
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
		$ErrorMessage = $_.Exception.Message
		$functionname = $MyInvocation.MyCommand.Name
		Write-Host "[Error][$modulename : $functionname] => "$ErrorMessage
		exit 6
	}
}

# Application Pool stop function
Function fnStopApplicationPool([string]$WebsiteName)
{
	try{
		if((Get-WebAppPoolState -Name $WebsiteName).Name -eq $null)
		{
			# The website is not exist
			exit 10
		}
		else
		{
			if((Get-WebAppPoolState $WebsiteName).Value -ne 'Stopped')
			{
				Stop-WebAppPool -Name $WebsiteName
				Start-Sleep -s $waitsecond
			}
		}
	}
	catch{
		$ErrorMessage = $_.Exception.Message
		$functionname = $MyInvocation.MyCommand.Name
		Write-Host "[Error][$modulename : $functionname] => "$ErrorMessage
		exit 7
	}
}

fnStopWebsite($WebsiteName) # stop site
$statusSite = Get-Website -name $WebsiteName

$Websitesuccess = $false
$currentRetry = 0
do
{
	if ($statusSite.State -eq "Stopped"){
		Write-Host "The website is stopped..."
		$Websitesuccess = $true;
	}
	else{
		fnStopWebsite($WebsiteName) # stop site
		$currentRetry = $currentRetry + 1;
	}
}
while (!$Websitesuccess -and $currentRetry -le $timeout)
if($currentRetry > $timeout)
{
	Write-Host "The website can't stop"
	exit 8
}

fnStopApplicationPool($WebsiteName) # stop application pool
$statusPool = Get-WebAppPoolState $WebsiteName

$Poolsuccess = $false
$currentRetry = 0
do
{
	if ($statusPool.Value -eq "Stopped"){
		Write-Host "The application pool is stopped..."
		$Poolsuccess = $true;
	}
	else{
		fnStopApplicationPool($WebsiteName) # stop application pool
		$currentRetry = $currentRetry + 1;
	}
}
while (!$Poolsuccess -and $currentRetry -le $timeout)
if($currentRetry > $timeout)
{
	Write-Host "The application pool can't stop"
	exit 9
}

if($Poolsuccess -and  $Websitesuccess)
{
 exit 0
}