[CmdletBinding(SupportsShouldProcess=$True)]
Param(
[Parameter(Mandatory=$true)]
[string]$WebsiteName
)

# ================================================
# ====== START WEBSITE AND APPLICATION POOL ======
# ================================================
# CALL: .\StartWebsiteAppPool.ps1 "SiteName"

Write-Host ================================================ -foregroundcolor "green"
Write-Host START WEBSITE AND APPLICATION POOL ">>" $WebsiteName -foregroundcolor "green"
Write-Host ================================================ -foregroundcolor "green"

# ========= CONFIG ===================
$waitsecond = 3 # seconds
$timeout = 4 # max waiting while not starting: $timeout*$waitsecond
# ====================================

#Set-ExecutionPolicy Unrestricted  
Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass 
import-module WebAdministration
$modulename = $MyInvocation.MyCommand.Name

# IIS website start function
Function fnStartWebsite([string]$WebsiteName)
{
	try{
		if((Get-Website -Name $WebsiteName).Name -eq $null)
		{
			# The website is not exist
			exit 10
		}
		else
		{
			if((Get-Website -name $WebsiteName).State -ne 'Started')
			{
				Start-WebSite -Name $WebsiteName
				Start-Sleep -s $waitsecond
			}
		}
	}
	catch{
		$ErrorMessage = $_.Exception.Message
		$functionname = $MyInvocation.MyCommand.Name
		Write-Host "[Error][$modulename : $functionname] => "$ErrorMessage
		exit 2
	}
}

# Application Pool start function
Function fnStartApplicationPool([string]$WebsiteName)
{
	try{
		if((Get-WebAppPoolState -Name $WebsiteName).Name -eq $null)
		{
			# The website is not exist
			exit 10
		}
		else
		{
			if((Get-WebAppPoolState $WebsiteName).Value -ne 'Started')
			{
				Start-WebAppPool -Name $WebsiteName
				Start-Sleep -s $waitsecond
			}
		}
	}
	catch{
		$ErrorMessage = $_.Exception.Message
		$functionname = $MyInvocation.MyCommand.Name
		Write-Host "[Error][$modulename : $functionname] => "$ErrorMessage
		exit 3
	}
}

fnStartWebsite($WebsiteName) # start site
$statusSite = Get-Website -name $WebsiteName

$Websitesuccess = $false
$currentRetry = 0
do
{
	if ($statusSite.State -eq "Started"){
		Write-Host "The website is running..."
		$Websitesuccess = $true;
	}
	else{
		fnStartWebsite($WebsiteName) # start site
		$currentRetry = $currentRetry + 1;
	}
}
while (!$Websitesuccess -and $currentRetry -le $timeout)

if($currentRetry > $timeout)
{
	Write-Host "The website can't start"
	exit 5
}

fnStartApplicationPool($WebsiteName) # start application pool
$statusPool = Get-WebAppPoolState $WebsiteName

$Poolsuccess = $false
$currentRetry = 0
do
{
	if ($statusPool.Value -eq "Started"){
		Write-Host "The application pool is running..."
		$Poolsuccess = $true;
	}
	else{
		fnStartApplicationPool($WebsiteName) # start application pool
		$currentRetry = $currentRetry + 1;
	}
}
while (!$Poolsuccess -and $currentRetry -le $timeout)

if($currentRetry > $timeout)
{
	Write-Host "The application pool can't start"
	exit 4
}

if($Poolsuccess -and  $Websitesuccess)
{
 exit 0
}

