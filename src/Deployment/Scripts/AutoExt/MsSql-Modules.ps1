# MsSql Step Module
# Implements PowerShell standards for SQL-related steps

$ErrorActionPreference = 'Stop'
. "$ScriptBaseFolderPath/Core/Core-Helpers.ps1"

# ******************************************************************  Steps ******************************************************************
Function Step-Db-StartSqlWindowsContainer {
	<#
	.SYNOPSIS
	Start test SQL Server in a Windows Docker container
	.DESCRIPTION
	Starts a SQL Server Windows container for testing, outputs connection info.
	.PARAMETER StepSettings
	Hashtable of settings. Must include 'UserPsw', 'DockerNetworkName'.
	.EXAMPLE
	Step-Db-StartSqlWindowsContainer -StepSettings @{ UserPsw = 'P@ssw0rd'; DockerNetworkName = 'default' }
	#>
	[CmdletBinding()]
	param(
		[Parameter(Mandatory=$true)]
		[hashtable]$StepSettings
	)
	try {
		Assert-RequiredSetting -Settings $StepSettings -Key 'UserPsw'
		Assert-RequiredSetting -Settings $StepSettings -Key 'DockerNetworkName'
		$networkName = $StepSettings['DockerNetworkName']
		$userPsw = $StepSettings['UserPsw']
		Write-Log -Message "Starting SQL Server Windows container..." -Severity Info
		Write-Log -Message "docker run --rm -it -e ACCEPT_EULA=Y -e sa_password=$userPsw -p 1433:1433 -d --name sql1 microsoft/mssql-server-windows-developer:2017-latest" -Severity Debug
		docker run --rm -it -e ACCEPT_EULA=Y -e sa_password=$userPsw -p 1433:1433 -d --name sql1 microsoft/mssql-server-windows-developer:2017-latest
		$msSqlIp = docker inspect --format "{{ .NetworkSettings.Networks.$networkName.IPAddress }}" sql1
		Write-Log -Message "Container sql server ip: $msSqlIp" -Severity Info
		$script:Result = $LASTEXITCODE
	} catch {
		Write-Log -Message $_ -Severity Error
		$script:Result = 1
	}
}

Function Step-Db-StartSqlLinuxContainer {
	<#
	.SYNOPSIS
	Start test SQL Server in a Linux Docker container
	.DESCRIPTION
	Starts a SQL Server Linux container for testing, outputs connection info.
	.PARAMETER StepSettings
	Hashtable of settings. Must include 'UserPsw', 'DockerNetworkName', 'DockerContainerName'.
	.EXAMPLE
	Step-Db-StartSqlLinuxContainer -StepSettings @{ UserPsw = 'P@ssw0rd'; DockerNetworkName = 'default'; DockerContainerName = 'sql1' }
	#>
	[CmdletBinding()]
	param(
		[Parameter(Mandatory=$true)]
		[hashtable]$StepSettings
	)
	try {
		Assert-RequiredSetting -Settings $StepSettings -Key 'UserPsw'
		Assert-RequiredSetting -Settings $StepSettings -Key 'DockerNetworkName'
		Assert-RequiredSetting -Settings $StepSettings -Key 'DockerContainerName'
		$containerName = $StepSettings['DockerContainerName']
		$networkName = $StepSettings['DockerNetworkName']
		$userPsw = $StepSettings['UserPsw']
		Write-Log -Message "Starting SQL Server Linux container..." -Severity Info
		Write-Log -Message "docker run -it -e ACCEPT_EULA=Y -e SA_PASSWORD=$userPsw -p 12433:1433 -d --net $networkName --name $containerName mcr.microsoft.com/mssql/server:2017-latest-ubuntu" -Severity Debug
		docker run -it -e ACCEPT_EULA=Y -e SA_PASSWORD=$userPsw -p 12433:1433 -d --net $networkName --name $containerName mcr.microsoft.com/mssql/server:2017-latest-ubuntu
		$msSqlIp = docker inspect --format "{{ .NetworkSettings.Networks.$networkName.IPAddress }}" $containerName
		$msSqlPort = docker inspect --format '{{ (index (index .NetworkSettings.Ports "1433/tcp") 0).HostPort }}' $containerName
		Write-Log -Message "Container sql server ip: $msSqlIp" -Severity Info
		Write-Log -Message "Container sql server port: $msSqlPort" -Severity Info
		$script:Result = $LASTEXITCODE
	} catch {
		Write-Log -Message $_ -Severity Error
		$script:Result = 1
	}
}

Function Step-Db-GetSqlContainer {
	<#
	.SYNOPSIS
	Get IP and port of test SQL Server Docker container
	.DESCRIPTION
	Outputs connection info for a running SQL Server Docker container.
	.PARAMETER StepSettings
	Hashtable of settings. Must include 'DockerNetworkName', 'DockerContainerName'.
	.EXAMPLE
	Step-Db-GetSqlContainer -StepSettings @{ DockerNetworkName = 'default'; DockerContainerName = 'sql1' }
	#>
	[CmdletBinding()]
	param(
		[Parameter(Mandatory=$true)]
		[hashtable]$StepSettings
	)
	try {
		Assert-RequiredSetting -Settings $StepSettings -Key 'DockerNetworkName'
		Assert-RequiredSetting -Settings $StepSettings -Key 'DockerContainerName'
		$containerName = $StepSettings['DockerContainerName']
		$networkName = $StepSettings['DockerNetworkName']
		$msSqlIp = docker inspect --format "{{ .NetworkSettings.Networks.$networkName.IPAddress }}" $containerName
		$msSqlPort = docker inspect --format '{{ (index (index .NetworkSettings.Ports "1433/tcp") 0).HostPort }}' $containerName
		Write-Log -Message "Container sql server ip: $msSqlIp" -Severity Info
		Write-Log -Message "Container sql server port: $msSqlPort" -Severity Info
		$script:Result = $LASTEXITCODE
	} catch {
		Write-Log -Message $_ -Severity Error
		$script:Result = 1
	}
}

Function Step-Db-OpenSqlManagementStudio {
	<#
	.SYNOPSIS
	Open SQL Server Management Studio for Docker SQL Server
	.DESCRIPTION
	Opens SSMS for a running SQL Server Docker container.
	.PARAMETER StepSettings
	Hashtable of settings. Must include 'DockerNetworkName', 'DockerContainerName', 'UserName', 'UserPsw'.
	.EXAMPLE
	Step-Db-OpenSqlManagementStudio -StepSettings @{ DockerNetworkName = 'default'; DockerContainerName = 'sql1'; UserName = 'sa'; UserPsw = 'P@ssw0rd' }
	#>
	[CmdletBinding()]
	param(
		[Parameter(Mandatory=$true)]
		[hashtable]$StepSettings
	)
	try {
		Assert-RequiredSetting -Settings $StepSettings -Key 'DockerNetworkName'
		Assert-RequiredSetting -Settings $StepSettings -Key 'DockerContainerName'
		Assert-RequiredSetting -Settings $StepSettings -Key 'UserName'
		Assert-RequiredSetting -Settings $StepSettings -Key 'UserPsw'
		$containerName = $StepSettings['DockerContainerName']
		$networkName = $StepSettings['DockerNetworkName']
		$userName = $StepSettings['UserName']
		$userPsw = $StepSettings['UserPsw']
		$msSqlIp = docker inspect --format "{{ .NetworkSettings.Networks.$networkName.IPAddress }}" $containerName
		$msSqlPort = docker inspect --format '{{ (index (index .NetworkSettings.Ports "1433/tcp") 0).HostPort }}' $containerName
		Write-Log -Message "Container sql server ip: $msSqlIp" -Severity Info
		Write-Log -Message "Container sql server port: $msSqlPort" -Severity Info
		Write-Log -Message "Try to open sql server in sql management studio..." -Severity Info
		Start-Process "Ssms.exe" "-S localhost,$msSqlPort -U $userName -P $userPsw"
		Write-Log -Message "Done. You should see SSMS now." -Severity Info
		$script:Result = $LASTEXITCODE
	} catch {
		Write-Log -Message $_ -Severity Error
		$script:Result = 1
	}
}

Function Step-Db-StopSqlContainer {
	<#
	.SYNOPSIS
	Stop SQL Server Docker container
	.DESCRIPTION
	Stops a running SQL Server Docker container.
	.PARAMETER StepSettings
	Hashtable of settings. Must include 'DockerContainerName'.
	.EXAMPLE
	Step-Db-StopSqlContainer -StepSettings @{ DockerContainerName = 'sql1' }
	#>
	[CmdletBinding()]
	param(
		[Parameter(Mandatory=$true)]
		[hashtable]$StepSettings
	)
	try {
		Assert-RequiredSetting -Settings $StepSettings -Key 'DockerContainerName'
		$containerName = $StepSettings['DockerContainerName']
		$existingContainer = docker ps -a --format '{{.Names}}' | findstr $containerName
		if ($existingContainer) {
			docker container stop $containerName
			Write-Log -Message "$containerName container has been stopped." -Severity Info
		} else {
			Write-Log -Message "$containerName container is not running." -Severity Warning
		}
		$script:Result = $LASTEXITCODE
	} catch {
		Write-Log -Message $_ -Severity Error
		$script:Result = 1
	}
}

Function Step-Db-RemoveSqlContainer {
	<#
	.SYNOPSIS
	Remove SQL Server Docker container
	.DESCRIPTION
	Removes a stopped SQL Server Docker container.
	.PARAMETER StepSettings
	Hashtable of settings. Must include 'DockerContainerName'.
	.EXAMPLE
	Step-Db-RemoveSqlContainer -StepSettings @{ DockerContainerName = 'sql1' }
	#>
	[CmdletBinding()]
	param(
		[Parameter(Mandatory=$true)]
		[hashtable]$StepSettings
	)
	try {
		Assert-RequiredSetting -Settings $StepSettings -Key 'DockerContainerName'
		$containerName = $StepSettings['DockerContainerName']
		$existingContainer = docker ps -a --format '{{.Names}}' | findstr $containerName
		if ($existingContainer) {
			docker container rm $containerName
			Write-Log -Message "$containerName container has been removed." -Severity Info
		} else {
			Write-Log -Message "$containerName container does not exist." -Severity Warning
		}
		$script:Result = $LASTEXITCODE
	} catch {
		Write-Log -Message $_ -Severity Error
		$script:Result = 1
	}
}

Function Step-Db-SetHostSqlServer {
	<#
	.SYNOPSIS
	Set SQL Server host entries
	.DESCRIPTION
	Sets host file entries for SQL Server containers.
	.PARAMETER StepSettings
	Hashtable of settings. Must include 'Hosts'.
	.EXAMPLE
	Step-Db-SetHostSqlServer -StepSettings @{ Hosts = @('127.0.0.1 sql1') }
	#>
	[CmdletBinding()]
	param(
		[Parameter(Mandatory=$true)]
		[hashtable]$StepSettings
	)
	try {
		Assert-RequiredSetting -Settings $StepSettings -Key 'Hosts'
		$projectSiteHosts = $StepSettings['Hosts']
		& $ScriptBaseFolderPath\Ops\Set-Host.ps1 -SiteHosts $projectSiteHosts
		$script:Result = $LASTEXITCODE
	} catch {
		Write-Log -Message $_ -Severity Error
		$script:Result = 1
	}
}