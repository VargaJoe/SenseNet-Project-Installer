# ******************************************************************  Steps ******************************************************************
Function Step-StartSqlWindowsContainer {
	<#
	.SYNOPSIS
	test docker container for test sql server
	.DESCRIPTION
	
	#>	
	[CmdletBinding(SupportsShouldProcess=$True)]
	Param(
		[Parameter(Mandatory=$false)]
		[string]$Section="Project"
	)
	
	$LASTEXITCODE = 0
	try {	
		$networkName=$GlobalSettings."$Section".DockerNetworkName

		# UserName is defaul sa
		#$UserName = $GlobalSettings."$Section".UserName
		$UserPsw = $GlobalSettings."$Section".UserPsw
		
		# Start mssql container
		Write-Output "docker run --rm -it -e ACCEPT_EULA=Y -e sa_password=$($UserPsw) -p 1433:1433 -d --name sql1 microsoft/mssql-server-windows-developer:2017-latest"

		# Windows container
		docker run --rm -it -e ACCEPT_EULA=Y -e sa_password=$($UserPsw) -p 1433:1433 -d --name sql1 microsoft/mssql-server-windows-developer:2017-latest
		#docker run --rm -it -e ACCEPT_EULA=Y -e sa_password=QWEasd123% -p 1433:1433 -d --name sql1 microsoft/mssql-server-windows-developer:2017-latest
		
		# get mssql ip
		$msSqlIp = docker inspect --format "{{ .NetworkSettings.Networks.$($networkName).IPAddress }}" sql1
		Write-Output "Container sql server ip: $msSqlIp"
		
		$script:Result = $LASTEXITCODE
	}
	catch {
		$script:Result = 1
	}
}

Function Step-StartSqlLinuxContainer {
	<#
	.SYNOPSIS
	test docker container for test sql server on linux 
	.DESCRIPTION
	
	#>	
	[CmdletBinding(SupportsShouldProcess=$True)]
	Param(
		[Parameter(Mandatory=$false)]
		[string]$Section="Project"
	)
	
	$LASTEXITCODE = 0
	try {	
		$containerName=$GlobalSettings."$Section".DockerContainerName
		$networkName=$GlobalSettings."$Section".DockerNetworkName

		# UserName is defaul sa
		#$UserName = $GlobalSettings."$Section".UserName
		$UserPsw = $GlobalSettings."$Section".UserPsw
		
		# Linux container
		Write-Output "docker run -it -e ACCEPT_EULA=Y -e SA_PASSWORD=$($UserPsw) -p 1433:1433 -d --net $($networkName) --name $($containerName) mcr.microsoft.com/mssql/server:2017-latest-ubuntu"
		docker run -it -e ACCEPT_EULA=Y -e SA_PASSWORD=$($UserPsw) -p 12433:1433 -d --net $($networkName) --name $($containerName) mcr.microsoft.com/mssql/server:2017-latest-ubuntu
		# docker run --rm -it -e 'ACCEPT_EULA=Y' -e 'SA_PASSWORD=QWEasd123%' --net mynet123 -p 1433:1433 -d --name sql1 mcr.microsoft.com/mssql/server:2017-latest-ubuntu
		
		# get mssql ip
		#Write-Output "docker inspect --format {{ .NetworkSettings.Networks.$($networkName).IPAddress }} $containerName"
		$msSqlIp = docker inspect --format "{{ .NetworkSettings.Networks.$($networkName).IPAddress }}" $containerName
		#Write-Output "docker inspect --format {{ .NetworkSettings.Ports.1433//tcp.HostPort }} $containerName"
		$msSqlPort = docker inspect --format '{{ (index (index .NetworkSettings.Ports \"1433/tcp\") 0).HostPort }}' $containerName
		Write-Output "Container sql server ip: $msSqlIp"
		Write-Output "Container sql server port: $msSqlPort"
		Write-Output "Container sql server private: $($msSqlIp):$($msSqlPort)"
		Write-Output "Container sql server public: localhost:$msSqlPort"


	
		
		$script:Result = $LASTEXITCODE
	}
	catch {
		$script:Result = 1
	}
}

Function Step-GetSqlContainer {
	<#
	.SYNOPSIS
	get ip of test docker container for internal nuget feed
	.DESCRIPTION
	
	#>	
	[CmdletBinding(SupportsShouldProcess=$True)]
	Param(
		[Parameter(Mandatory=$false)]
		[string]$Section="Project"
	)
	
	$LASTEXITCODE = 0
	try {	
		$containerName=$GlobalSettings."$Section".DockerContainerName
		$networkName=$GlobalSettings."$Section".DockerNetworkName

		# get docker sql ip
		$msSqlIp = docker inspect --format "{{ .NetworkSettings.Networks.$($networkName).IPAddress }}" $containerName
		$msSqlPort = docker inspect --format '{{ (index (index .NetworkSettings.Ports \"1433/tcp\") 0).HostPort }}' $containerName
		Write-Output "Container sql server ip: $msSqlIp"
		Write-Output "Container sql server port: $msSqlPort"
		Write-Output "Container sql server private: $($msSqlIp):$($msSqlPort)"
		Write-Output "Container sql server public: localhost:$msSqlPort"
		
		$script:Result = $LASTEXITCODE
	}
	catch {
		$script:Result = 1
	}
}

Function Step-OpenSqlManagementStudio {
	<#
	.SYNOPSIS
	get ip of test docker container for internal nuget feed
	.DESCRIPTION
	
	#>	
	[CmdletBinding(SupportsShouldProcess=$True)]
	Param(
		[Parameter(Mandatory=$false)]
		[string]$Section="Project"
	)
	
	$LASTEXITCODE = 0
	try {	
		$containerName=$GlobalSettings."$Section".DockerContainerName
		$networkName=$GlobalSettings."$Section".DockerNetworkName

		# UserName is defaul sa
		$UserName = $GlobalSettings."$Section".UserName
		$UserPsw = $GlobalSettings."$Section".UserPsw

		# get mssql ip
		$msSqlIp = docker inspect --format "{{ .NetworkSettings.Networks.$($networkName).IPAddress }}" $containerName
		$msSqlPort = docker inspect --format '{{ (index (index .NetworkSettings.Ports \"1433/tcp\") 0).HostPort }}' $containerName
		Write-Output "Container sql server ip: $msSqlIp"
		Write-Output "Container sql server port: $msSqlPort"
		Write-Output "Container sql server private: $($msSqlIp):$($msSqlPort)"
		Write-Output "Container sql server public: localhost:$msSqlPort"
		
		Write-Output "Try to open sql server in sql management studio..."
		Start-Process "Ssms.exe" "-S localhost,$($MsSqlPort) -U $($UserName) -P $($UserPsw)"
		Write-Output "Done. Use should've seen now."

		$script:Result = $LASTEXITCODE
	}
	catch {
		$script:Result = 1
		Write-Error "$_"
	}
}

Function Step-StopSqlContainer {
	<#
	.SYNOPSIS
	stop container before test from scratch again
	.DESCRIPTION
	
	#>	
	[CmdletBinding(SupportsShouldProcess=$True)]
	Param(
		[Parameter(Mandatory=$false)]
		[string]$Section="Project"
	)
	
	$exitCode = 0
	try {	
		$containerName=$GlobalSettings."$Section".DockerContainerName
		$existingContainer = docker ps -a --format '{{.Names}}' | findstr $containerName

		if ($existingContainer) {
			docker container stop $containerName
			$exitCode = $LastExitcode
			Write-Output "$containerName container has been stopped."
		} else {
			Write-Output "$containerName container is not running."
		}

		$script:Result = $exitCode
	}
	catch {
		$script:Result = 1
		Write-Error "$_"
	}
}

Function Step-RemoveSqlContainer {
	<#
	.SYNOPSIS
	stop container before test from scratch again
	.DESCRIPTION
	
	#>	
	[CmdletBinding(SupportsShouldProcess=$True)]
	Param(
		[Parameter(Mandatory=$false)]
		[string]$Section="Project"
	)
	
	$exitCode = 0
	try {	
		$containerName=$GlobalSettings."$Section".DockerContainerName
		$existingContainer = docker ps -a --format '{{.Names}}' | findstr $containerName

		if ($existingContainer) {
			docker container rm $containerName
			$exitCode = $LastExitcode
			Write-Output "$containerName container has been removed."
		} else {
			Write-Output "$containerName container is not exist."
		}

		$script:Result = $exitCode
	}
	catch {
		$script:Result = 1
		Write-Error "$_"
	}
}

Function Step-SetHostSqlServer {
<#
	.SYNOPSIS
	Set urls in hosts file
	.DESCRIPTION
	
	#>
	[CmdletBinding(SupportsShouldProcess=$True)]
		Param(
		[Parameter(Mandatory=$false)]
		[string]$Section="Project"
		)
	
	try {
		$ProjectSiteHosts = $GlobalSettings."$Section".Hosts
		& $ScriptBaseFolderPath\Ops\Set-Host.ps1 -SiteHosts $ProjectSiteHosts
		$script:Result = $LASTEXITCODE
	}
	catch {
		$script:Result = 1
	}
	
}