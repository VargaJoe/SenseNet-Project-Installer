[CmdletBinding(SupportsShouldProcess=$True)]
Param(
[Parameter(Mandatory=$true)]
[string]$WebsiteName,
[Parameter(Mandatory=$false)]
[string]$AppPoolName = $WebsiteName
)

#$Computer = $env:computername
$WebsiteName = $WebsiteName.ToLower()
$AppPoolName = $AppPoolName.ToLower()

# ================================================
# ====== START WEBSITE AND APPLICATION POOL ======
# ================================================
# CALL: .\StartWebsiteAppPool.ps1 "SiteName"

# ========= CONFIG ===================
$waitsecond = 3 # seconds
$timeout = 4 # max waiting while not starting: $timeout*$waitsecond
# ====================================

#Write-Host ================================================ -foregroundcolor "green"
#Write-Host START WEBSITE AND APPLICATION POOL ">>" $WebsiteName -foregroundcolor "green"
#Write-Host ================================================ -foregroundcolor "green"
#Write-Host Computer: $Computer 

#Set-ExecutionPolicy Unrestricted  
# Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass 
import-module WebAdministration
# $modulename = $MyInvocation.MyCommand.Name

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
		Write-Error "[Error][$modulename : $functionname] => "$ErrorMessage
		exit 2
	}
}

# Application Pool start function
Function fnStartApplicationPool([string]$AppPoolName)
{
	try{
		if((Get-WebAppPoolState -Name $AppPoolName).Name -eq $null)
		{
			# The website is not exist
			exit 10
		}
		else
		{
			if((Get-WebAppPoolState $AppPoolName).Value -ne 'Started')
			{
				Start-WebAppPool -Name $AppPoolName
				Start-Sleep -s $waitsecond
			}
		}
	}
	catch{
		$ErrorMessage = $_.Exception.Message
		$functionname = $MyInvocation.MyCommand.Name
		Write-Error "[Error][$modulename : $functionname] => "$ErrorMessage
		exit 3
	}
}

#fnStartWebsite($WebsiteName) # start site
$statusSite = Get-Website -name $WebsiteName

$Websitesuccess = $false
$currentRetry = 0
do
{
	if ($statusSite.State -eq "Started"){
		Write-Output "[END]:The '$WebsiteName' website is running..."
		$Websitesuccess = $true;
	}
	else{
		fnStartWebsite($WebsiteName) # start site
		$currentRetry = $currentRetry + 1;
	}
}
while (!$Websitesuccess -and $currentRetry -le $timeout)

if($currentRetry -gt $timeout)
{
	Write-Error "The '$WebsiteName' website can't be started"
	exit 5
}

#fnStartApplicationPool($AppPoolName) # start application pool
$statusPool = Get-WebAppPoolState $AppPoolName

$Poolsuccess = $false
$currentRetry = 0
do
{
	if ($statusPool.Value -eq "Started"){
		Write-Output "[END]:The '$AppPoolName' application pool is running..."
		
		$Poolsuccess = $true;
	}
	else{
		fnStartApplicationPool($AppPoolName) # start application pool
		$currentRetry = $currentRetry + 1;
	}
}
while (!$Poolsuccess -and $currentRetry -le $timeout)

if($currentRetry -gt $timeout)
{
	Write-Error "The '$AppPoolName' application pool can't start"
	exit 4
}

if($Poolsuccess -and  $Websitesuccess)
{
 exit 0
}

