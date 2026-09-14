# ******************************************************************  Steps ******************************************************************
Function Step-Docker-NetcoreTest {
<#!
    .SYNOPSIS
    Test Docker with .NET Core and SQL container
    .DESCRIPTION
    Runs a full test workflow: SQL container, empty DB, NuGet feed, config, build, run, and open webapp.
    .PARAMETER StepSettings
    Hashtable of settings for the test. Must include all required keys for sub-steps.
    .EXAMPLE
    Step-Docker-NetcoreTest -StepSettings @{ ... }
#>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [hashtable]$StepSettings
    )
    try {
        Assert-RequiredSetting -Settings $StepSettings -Key 'RequiredKey1' # TODO: List all required keys
        Write-Log -Message 'Starting Docker .NET Core test workflow...' -Severity Info
        Step-Docker-StartContainerSql -StepSettings $StepSettings
        Step-Docker-CreateEmptyDb -StepSettings $StepSettings
        Step-Docker-StartNugetFeed -StepSettings $StepSettings
        Step-Docker-PrepareNugetConfig -StepSettings $StepSettings
        Step-Docker-SetInstallerConnectionWithDb -StepSettings $StepSettings
        Step-Docker-BuildInstallerImage -StepSettings $StepSettings
        Step-Docker-CallConsoleInstaller -StepSettings $StepSettings
        Step-Docker-BuildWebAppImage -StepSettings $StepSettings
        Step-Docker-StartWebApp -StepSettings $StepSettings
        Step-Docker-OpenWebApp -StepSettings $StepSettings
        $script:Result = 0
    } catch {
        Write-Log -Message $_ -Severity Error
        $script:Result = 1
    }
}

Function Step-Docker-BuildInstallerImage {
<#!
    .SYNOPSIS
    Build .NET Core console installer Docker image
    .DESCRIPTION
    Builds a Docker image for the .NET Core console installer using StepSettings.
    .PARAMETER StepSettings
    Hashtable of settings. Must include 'InstallerDockerImageName', 'InstallerDockerFilePath', 'SolutionFolderPath'.
    .EXAMPLE
    Step-Docker-BuildInstallerImage -StepSettings @{ InstallerDockerImageName = '...'; InstallerDockerFilePath = '...'; SolutionFolderPath = '...' }
#>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [hashtable]$StepSettings
    )
    try {
        Assert-RequiredSetting -Settings $StepSettings -Key 'InstallerDockerImageName'
        Assert-RequiredSetting -Settings $StepSettings -Key 'InstallerDockerFilePath'
        Assert-RequiredSetting -Settings $StepSettings -Key 'SolutionFolderPath'
        $dockerImageName = $StepSettings['InstallerDockerImageName']
        $dockerFilePath = $StepSettings['InstallerDockerFilePath']
        $solutionFolderPath = $StepSettings['SolutionFolderPath']
        Write-Log -Message "docker build -t $dockerImageName -f $dockerFilePath $solutionFolderPath" -Severity Info
        docker build -t $dockerImageName -f "$dockerFilePath" "$solutionFolderPath"
        $script:Result = $LASTEXITCODE
    } catch {
        Write-Log -Message $_ -Severity Error
        $script:Result = 1
    }
}


Function Step-Docker-CallConsoleInstaller {
	<#
	.SYNOPSIS
	run .net core console installer from docker container
	.DESCRIPTION
	Network related error for some reason. Use default "CallConsoleInstaller" for now.
	#>	
	[CmdletBinding()]
	Param(
		[Parameter(Mandatory=$false)]
		[string]$Section="Project"
	)
	
	$exitCode = 0
	try {	
		$DataSource=$GlobalSettings."$Section".DataSource
		$InitialCatalog=$GlobalSettings."$Section".InitialCatalog 
		$UserName=$GlobalSettings."$Section".UserName 
		$UserPsw=$GlobalSettings."$Section".UserPsw 
		$networkName=$GlobalSettings."$Section".DockerNetworkName 

		# $DataSource="172.18.0.2,1433"
		# $DataSource="192.168.0.105,12433"

		Write-Output "Datasource: $DataSource"
		Write-Output "InitialCatalog: $InitialCatalog"

		if ($UserName) {
			$ConnectionString = "Persist Security Info=False;Initial Catalog=$($InitialCatalog);Data Source=$($DataSource);User ID=$($UserName);Password=$($UserPsw)"
		} else {
			$ConnectionString = "Persist Security Info=False;Initial Catalog=$($InitialCatalog);Data Source=$($DataSource);Integrated Security=true"
		}

		$dockerImageName=$GlobalSettings."$Section".InstallerDockerImageName
		$dockerContainerName=$GlobalSettings."$Section".InstallerDockerContainerName

		# start installer
		Write-Output "docker run -it --rm -e ConnectionStrings__SnCrMsSql=$ConnectionString --net $($networkName) --name $dockerContainerName $dockerImageName"
		docker run -it --rm -e ConnectionStrings__SnCrMsSql=$ConnectionString --net $($networkName) --name $dockerContainerName $dockerImageName
		#docker run -it --rm --name installertestcnt installertest
		$exitCode = $LASTEXITCODE

		$script:Result = $exitCode
	}
	catch {
		$script:Result = 1
	}
}

Function Step-Docker-BuildWebAppImage {
	<#
	.SYNOPSIS
	build .net core webapp image
	.DESCRIPTION
	build .net core webapp image from  netcore SnWebApplicationWithIdentity of vs templates
	#>	
	[CmdletBinding()]
	Param(
		[Parameter(Mandatory=$false)]
		[string]$Section="Project"
	)
	
	$exitCode = 0
	try {	
		$dockerImageName=$GlobalSettings."$Section".DockerImageName
		$dockerFilePath=$GlobalSettings."$Section".DockerFilePath
		$solutionFolderPath=$GlobalSettings."$Section".SolutionFolderPath

		if (-Not($solutionFolderPath)) {
			$solutionFolderPath = $GlobalSettings.Source.SolutionFolderPath
		}	
		
		# build docker image for installer
		Write-Output "docker build -t $dockerImageName -f $dockerFilePath $solutionFolderPath"
		docker build -t $dockerImageName -f "$dockerFilePath" "$solutionFolderPath"
		$exitCode = $LastExitCode

		$script:Result = $exitCode
	}
	catch {
		$script:Result = 1
	}
}

Function Step-Docker-StartWebApp {
	<#
	.SYNOPSIS
	start .netcore web application in docker container
	.DESCRIPTION
	
	#>	
	[CmdletBinding()]
	Param(
		[Parameter(Mandatory=$false)]
		[string]$Section="Project"
	)
	
	# $LASTEXITCODE = 0
	try {	
		$DataSource=$GlobalSettings."$Section".DataSource
		$InitialCatalog=$GlobalSettings."$Section".InitialCatalog 
		$UserName=$GlobalSettings."$Section".UserName 
		$UserPsw=$GlobalSettings."$Section".UserPsw 
		$dockerImageName=$GlobalSettings."$Section".DockerImageName
		$dockerContainerName=$GlobalSettings."$Section".DockerContainerName
		$networkName=$GlobalSettings."$Section".DockerNetworkName 
		[int]$httpPort=$GlobalSettings."$Section".DockerHttpPort
		[int]$httpsPort=$GlobalSettings."$Section".DockerHttpsPort
		
		$LucFolderPath = $GlobalSettings."$Section".LucFolderPath
		if ($LucFolderPath) {
			$LucFolderPath = Get-FullPath $LucFolderPath
		}
		
		$authenticationAuthority = $GlobalSettings."$Section".AuthenticationAuthority
		$metadataHost = $GlobalSettings."$Section".MetadataHost
		$SearchSearviceAddress = $GlobalSettings."$Section".SearchSearviceAddress
		$RabbitMqServiceUrl = $GlobalSettings."$Section".RabbitMqServiceUrl

		$CertificatePath = $GlobalSettings."$Section".CertificatePath
		if ($CertificatePath) {
			$CertificatePath = Get-FullPath $CertificatePath
		}
		
		$CertificateName = $GlobalSettings."$Section".CertificateName
		$CertificatePsw = $GlobalSettings."$Section".CertificatePsw
		
		#$sqlSettings = ""
		 if ($DataSource) {
			#$DataSourceName=$GlobalSettings."$Section".DataSourceName
			#$HostIp = (Get-NetIPAddress -AddressFamily IPv4 -InterfaceIndex 12).IpAddress
			
			if ($UserName) {
				$ConnectionString = "Persist Security Info=False;Initial Catalog=$($InitialCatalog);Data Source=$($DataSource);User ID=$($UserName);Password=$($UserPsw)"
			} else {
				$ConnectionString = "Persist Security Info=False;Initial Catalog=$($InitialCatalog);Data Source=$($DataSource);Integrated Security=true"
			}
			# $sqlSettings = "-e ConnectionStrings__SnCrMsSql=$ConnectionString --add-host $($DataSourceName):$($HostIp) "
		 }

		# start netcore
		if ($DataSource -and $SearchSearviceAddress) {
			Write-Output "docker run -d -p ""$($httpsPort):443"" -p ""$($httpPort):80"" -e ConnectionStrings__SnCrMsSql=""$ConnectionString"" -e sensenet__search__service__address=""$SearchSearviceAddress"" -e sensenet__rabbitmq__ServiceUrl=""$RabbitMqServiceUrl"" --net $networkName --name $dockerContainerName -e sensenet__authentication__authority=""$($authenticationAuthority)"" -e sensenet__authentication__metadatahost="$metadataHost" -e ASPNETCORE_URLS=""https://+;http://+"" -e ASPNETCORE_HTTPS_PORT=""$httpsPort"" -e ASPNETCORE_ENVIRONMENT=Development -e ASPNETCORE_Kestrel__Certificates__Default__Password=$($CertificatePsw) -e ASPNETCORE_Kestrel__Certificates__Default__Path=""/https/$($CertificateName)"" -v ""$($CertificatePath):/https/"" $dockerImageName"
			docker run -d -p "$($httpsPort):443" -p "$($httpPort):80" -e ConnectionStrings__SnCrMsSql="$ConnectionString" -e sensenet__search__service__address="$SearchSearviceAddress" -e sensenet__rabbitmq__ServiceUrl="$RabbitMqServiceUrl" --net $networkName --name $dockerContainerName -e sensenet__authentication__authority="$authenticationAuthority" -e sensenet__authentication__metadatahost="$metadataHost" -e ASPNETCORE_URLS="https://+;http://+" -e ASPNETCORE_HTTPS_PORT="$httpsPort" -e ASPNETCORE_ENVIRONMENT=Development -e ASPNETCORE_Kestrel__Certificates__Default__Password="$CertificatePsw" -e ASPNETCORE_Kestrel__Certificates__Default__Path="/https/$($CertificateName)" -v "$($CertificatePath):/https/" $dockerImageName
		} elseif ($DataSource -and $LucFolderPath) {
			Write-Output "docker run -d -p `"$($httpsPort):443`" -p `"$($httpPort):80`" -e ConnectionStrings__SnCrMsSql=`"$ConnectionString`" --net $networkName --name $dockerContainerName -e sensenet__authentication__authority=`"$authenticationAuthority`" -e sensenet__authentication__metadatahost="$metadataHost" -e ASPNETCORE_URLS=`"https://+;http://+`" -e ASPNETCORE_HTTPS_PORT=`"$httpsPort`" -e ASPNETCORE_ENVIRONMENT=Development -e ASPNETCORE_Kestrel__Certificates__Default__Password=`"$CertificatePsw`" -e ASPNETCORE_Kestrel__Certificates__Default__Path=`"/https/$($CertificateName)`" -v `"$($CertificatePath):/https/`" -v `"$($LucFolderPath):/app/App_Data/LocalIndex`" $dockerImageName"
			docker run -d -p "$($httpsPort):443" -p "$($httpPort):80" -e ConnectionStrings__SnCrMsSql="$ConnectionString" --net $networkName --name $dockerContainerName -e sensenet__authentication__authority="$authenticationAuthority" -e sensenet__authentication__metadatahost="$metadataHost" -e ASPNETCORE_URLS="https://+;http://+" -e ASPNETCORE_HTTPS_PORT="$httpsPort" -e ASPNETCORE_ENVIRONMENT=Development -e ASPNETCORE_Kestrel__Certificates__Default__Password="$CertificatePsw" -e ASPNETCORE_Kestrel__Certificates__Default__Path="/https/$($CertificateName)" -v "$($CertificatePath):/https/" -v "$($LucFolderPath):/app/App_Data/LocalIndex" $dockerImageName
		} elseif ($DataSource) {
			Write-Output "docker run -d -p `"$($httpsPort):443`" -p `"$($httpPort):80`" -e ConnectionStrings__SnCrMsSql=`"$ConnectionString`" --net $networkName --name $dockerContainerName -e sensenet__authentication__authority=`"$authenticationAuthority`" -e sensenet__authentication__metadatahost="$metadataHost" -e ASPNETCORE_URLS=`"https://+;http://+`" -e ASPNETCORE_HTTPS_PORT=`"$httpsPort`" -e ASPNETCORE_ENVIRONMENT=Development -e ASPNETCORE_Kestrel__Certificates__Default__Password=`"$CertificatePsw`" -e ASPNETCORE_Kestrel__Certificates__Default__Path=`"/https/$($CertificateName)`" -v `"$($CertificatePath):/https/`" $dockerImageName"
			docker run -d -p "$($httpsPort):443" -p "$($httpPort):80" -e ConnectionStrings__SnCrMsSql="$ConnectionString" --net $networkName --name $dockerContainerName -e sensenet__authentication__authority="$authenticationAuthority" -e sensenet__authentication__metadatahost="$metadataHost" -e ASPNETCORE_URLS="https://+;http://+" -e ASPNETCORE_HTTPS_PORT="$httpsPort" -e ASPNETCORE_ENVIRONMENT=Development -e ASPNETCORE_Kestrel__Certificates__Default__Password="$CertificatePsw" -e ASPNETCORE_Kestrel__Certificates__Default__Path="/https/$($CertificateName)" -v "$($CertificatePath):/https/" $dockerImageName
		} else {
			Write-Output "docker run -d -p `"$($httpsPort):443`" -p `"$($httpPort):80`" --net $networkName --name $dockerContainerName -e sensenet__authentication__authority=`"$authenticationAuthority`" -e sensenet__authentication__metadatahost="$metadataHost" -e ASPNETCORE_URLS=`"https://+;http://+`" -e ASPNETCORE_HTTPS_PORT=`"$httpsPort`" -e ASPNETCORE_ENVIRONMENT=Development -e ASPNETCORE_Kestrel__Certificates__Default__Password=`"$CertificatePsw`" -e ASPNETCORE_Kestrel__Certificates__Default__Path=`"/https/$($CertificateName)`" -v `"$($CertificatePath):/https/`" $dockerImageName"
			docker run -d -p "$($httpsPort):443" -p "$($httpPort):80" --net $networkName --name $dockerContainerName -e sensenet__authentication__authority="$authenticationAuthority" -e sensenet__authentication__metadatahost="$metadataHost" -e ASPNETCORE_URLS="https://+;http://+" -e ASPNETCORE_HTTPS_PORT="$httpsPort" -e ASPNETCORE_ENVIRONMENT=Development -e ASPNETCORE_Kestrel__Certificates__Default__Password="$CertificatePsw" -e ASPNETCORE_Kestrel__Certificates__Default__Path="/https/$($CertificateName)" -v "$($CertificatePath):/https/" $dockerImageName
		}
		
		# get docker webapp ip
		Write-Output "docker inspect --format {{ .NetworkSettings.Networks.$($networkName).IPAddress }} $dockerContainerName"
		$webAppIp = docker inspect --format "{{ .NetworkSettings.Networks.$($networkName).IPAddress }}" $dockerContainerName
		$webAppPort = docker inspect --format '{{ (index (index .NetworkSettings.Ports \"80/tcp\") 0).HostPort }}' $dockerContainerName
		Write-Output "Container webapp ip: $webAppIp"
		Write-Output "Container webapp port: $webAppPort"
		
		$script:Result = $LASTEXITCODE
	}
	catch {
		$script:Result = 1
	}
}

Function Step-Docker-GetNetCoreWebApp {
	<#
	.SYNOPSIS
	get ip of test docker container for internal nuget feed
	.DESCRIPTION
	
	#>	
	[CmdletBinding()]
	Param(
		[Parameter(Mandatory=$false)]
		[string]$Section="Project"
	)
	
	# $LASTEXITCODE = 0
	try {	
		$dockerContainerName=$GlobalSettings."$Section".DockerContainerName
		$networkName=$GlobalSettings."$Section".DockerNetworkName 

		# get docker webapp ip
		Write-Output "docker inspect --format {{ .NetworkSettings.Networks.$($networkName).IPAddress }} $dockerContainerName"
		$webAppIp = docker inspect --format "{{ .NetworkSettings.Networks.$($networkName).IPAddress }}" $dockerContainerName
		$webAppPort = docker inspect --format '{{ (index (index .NetworkSettings.Ports \"80/tcp\") 0).HostPort }}' $dockerContainerName
		Write-Output "Container webapp ip: $webAppIp"
		Write-Output "Container webapp port: $webAppPort"

		$script:Result = $LASTEXITCODE
	}
	catch {
		$script:Result = 1
		Write-Error "$_"
	}
}

Function Step-Docker-OpenWebApp {
	<#
	.SYNOPSIS
	get ip of test docker container for internal nuget feed
	.DESCRIPTION
	
	#>	
	[CmdletBinding()]
	Param(
		[Parameter(Mandatory=$false)]
		[string]$Section="Project"
	)
	
	# $LASTEXITCODE = 0
	try {	
		$dockerContainerName=$GlobalSettings."$Section".DockerContainerName
		$networkName=$GlobalSettings."$Section".DockerNetworkName 

		# get docker sql ip
		Write-Output "docker inspect --format {{ .NetworkSettings.Networks.$($networkName).IPAddress }} $dockerContainerName"
		$webAppIp = docker inspect --format "{{ .NetworkSettings.Networks.$($networkName).IPAddress }}" $dockerContainerName
		$webAppPort = docker inspect --format '{{ (index (index .NetworkSettings.Ports \"443/tcp\") 0).HostPort }}' $dockerContainerName
		Write-Output "Container webapp ip: $webAppIp"
		Write-Output "Container webapp port: $webAppPort"
		
		Write-Output "Try to open in chrome..."
		#Start-Process "chrome.exe" $webAppIp
		Start-Process "chrome.exe" "https://localhost:$webAppPort/odata.svc"
		Write-Output "Done. Use should've seen now."

		$script:Result = $LASTEXITCODE
	}
	catch {
		$script:Result = 1
		Write-Error "$_"
	}
}

Function Step-Docker-OpenWebAppUnSecure {
	<#
	.SYNOPSIS
	get ip of test docker container for internal nuget feed
	.DESCRIPTION
	
	#>	
	[CmdletBinding()]
	Param(
		[Parameter(Mandatory=$false)]
		[string]$Section="Project"
	)
	
	# $LASTEXITCODE = 0
	try {	
		$dockerContainerName=$GlobalSettings."$Section".DockerContainerName
		$networkName=$GlobalSettings."$Section".DockerNetworkName 

		# get docker sql ip
		Write-Output "docker inspect --format {{ .NetworkSettings.Networks.$($networkName).IPAddress }} $dockerContainerName"
		$webAppIp = docker inspect --format "{{ .NetworkSettings.Networks.$($networkName).IPAddress }}" $dockerContainerName
		$webAppPort = docker inspect --format '{{ (index (index .NetworkSettings.Ports \"80/tcp\") 0).HostPort }}' $dockerContainerName
		Write-Output "Container webapp ip: $webAppIp"
		Write-Output "Container webapp port: $webAppPort"
		
		Write-Output "Try to open in chrome..."
		#Start-Process "chrome.exe" $webAppIp
		Start-Process "chrome.exe" "http://localhost:$webAppPort/odata.svc"
		Write-Output "Done. Use should've seen now."

		$script:Result = $LASTEXITCODE
	}
	catch {
		$script:Result = 1
		Write-Error "$_"
	}
}

Function Step-Docker-StopNetCoreWebApp {
	<#
	.SYNOPSIS
	stop container before test from scratch again
	.DESCRIPTION
	
	#>	
	[CmdletBinding()]
	Param(
		[Parameter(Mandatory=$false)]
		[string]$Section="Project"
	)
	
	$exitCode = 0
	try {	
		$dockerContainerName=$GlobalSettings."$Section".DockerContainerName
		
		$existingContainer = docker ps -a --format '{{.Names}}' | findstr $dockerContainerName

		if ($existingContainer) {
			docker container stop $dockerContainerName
			$exitCode = $LastExitcode
			Write-Output "$dockerContainerName container has been stopped."
		} else {
			Write-Output "$dockerContainerName container is not running."
		}

		$script:Result = $exitCode
	}
	catch {
		$script:Result = 1
		Write-Error "$_"
	}
}

Function Step-Docker-RemoveNetCoreWebApp {
	<#
	.SYNOPSIS
	stop container before test from scratch again
	.DESCRIPTION
	
	#>	
	[CmdletBinding()]
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


#================CONTAINERS=====================
Function Step-Docker-PruneContainers {
	<#
	.SYNOPSIS
	remove containers before test from scratch again
	.DESCRIPTION
	
	#>	
	[CmdletBinding()]
	Param(
		[Parameter(Mandatory=$false)]
		[string]$Section="Project"
	)
	
	try {	
		docker container prune -f
		$script:Result = $LASTEXITCODE
	}
	catch {
		$script:Result = 1
		Write-Error "$_"
	}
}

Function Step-Docker-PeekLinuxContainer {
	<#
	.SYNOPSIS
	exec dash interactive mode 
	.DESCRIPTION
	
	#>	
	[CmdletBinding()]
	Param(
		[Parameter(Mandatory=$false)]
		[string]$Section="Project"
	)
	
	$LASTEXITCODE = 0
	try {	
		$dockerContainerName=$GlobalSettings."$Section".DockerContainerName

		docker exec -it $dockerContainerName dash

		$script:Result = $LASTEXITCODE
	}
	catch {
		$script:Result = 1
		Write-Error "$_"
	}
}

Function Step-Docker-PeekWindowsContainer {
	<#
	.SYNOPSIS
	exec dash interactive mode 
	.DESCRIPTION
	
	#>	
	[CmdletBinding()]
	Param(
		[Parameter(Mandatory=$false)]
		[string]$Section="Project"
	)
	
	$LASTEXITCODE = 0
	try {	
		$dockerContainerName=$GlobalSettings."$Section".DockerContainerName

		docker exec -it $dockerContainerName powershell

		$script:Result = $LASTEXITCODE
	}
	catch {
		$script:Result = 1
		Write-Error "$_"
	}
}

#================NETWORK====================
Function Step-Docker-CheckDockerNetwork {
	<#
	.SYNOPSIS
	Check whether certain network is accessible or not
	.DESCRIPTION
	
	#>	
	[CmdletBinding()]
	Param(
		[Parameter(Mandatory=$false)]
		[string]$Section="Project"
	)
	
	
	try {	
		$networkName=$GlobalSettings."$Section".DockerNetworkName
		
		Write-Output "Check if $networkName network is available..."
		# docker network inspect --format {{ '.Id' }} $networkName
		docker network inspect $networkName
		$script:Result = $LASTEXITCODE
	}
	catch {
		$script:Result = 1
		Write-Error "$_"
	}
}

Function Step-Docker-CreateDockerNetwork {
	<#
	.SYNOPSIS
	Createcertain network if it is not available
	.DESCRIPTION
	
	#>	
	[CmdletBinding()]
	Param(
		[Parameter(Mandatory=$false)]
		[string]$Section="Project"
	)
	
	
	try {	
		$networkName=$GlobalSettings."$Section".DockerNetworkName

		Write-Output "Creating $networkName network..."
		docker network create -d bridge $networkName
		$script:Result = $LASTEXITCODE
	}
	catch {
		$script:Result = 1
		Write-Error "$_"
	}
}



#===============TEMP================
Function Step-Docker-BuildInstallerImageOnWindows {
	<#
	.SYNOPSIS
	build .net core console installer image
	.DESCRIPTION
	build .net core console installer image from  netcore SnWebApplicationWithIdentity of vs templates
	#>	
	[CmdletBinding()]
	Param(
		[Parameter(Mandatory=$false)]
		[string]$Section="Project"
	)
	
	$LASTEXITCODE = 0
	try {	
		# build docker image for installer
		docker build -t installertest -f .\settings\project-installerdocker.dockerfile ..\temp\Templates\src\netcore\SnWebApplicationWithIdentity
		
		$script:Result = $LASTEXITCODE
	}
	catch {
		$script:Result = 1
	}
}

Function Step-Docker-BuildInstallerImageOnLinux {
	<#
	.SYNOPSIS
	build .net core console installer image
	.DESCRIPTION
	build .net core console installer image from  netcore SnWebApplicationWithIdentity of vs templates
	#>	
	[CmdletBinding()]
	Param(
		[Parameter(Mandatory=$false)]
		[string]$Section="Project"
	)
	
	$LASTEXITCODE = 0
	try {	
		# build docker image for installer
		docker build -t netcoretestinstallerimg -f .\settings\project-installerdocker.linux.dockerfile ..\temp\Templates\src\netcore\SnWebApplicationWithIdentity
		
		$script:Result = $LASTEXITCODE
	}
	catch {
		$script:Result = 1
	}
}
Function Step-Docker-SetJsonConnectionsWithSqlContainerOnLinux {
	<#
	.SYNOPSIS
	Set installer and project json configurations to sql container
	.DESCRIPTION
	
	#>
	[CmdletBinding()]
	Param(
		[Parameter(Mandatory=$false)]
		[string]$Section="Project"
		)
	
	$LASTEXITCODE = 0
	try {
		# get docker sql ip
		$msSqlIp = docker inspect --format '{{ .NetworkSettings.Networks.bridge.IPAddress }}' sql1
		Write-Output "Container sql server ip: $msSqlIp"
		
		# $DataSource=$GlobalSettings."$Section".DataSource
		$DataSource=$msSqlIp

		#linux hack
		$DataSource="localhost,1433"

		$instConfigFilePath = Get-FullPath $GlobalSettings."$Section".InstallerCfgFilePath
		$appConfigFilePath = Get-FullPath $GlobalSettings."$Section".AppConfigFilePath
		$InitialCatalog=$GlobalSettings."$Section".InitialCatalog 
		$UserName=$GlobalSettings."$Section".UserName 
		$UserPsw=$GlobalSettings."$Section".UserPsw 

		Write-Output "Datasource: $DataSource"
		Write-Output "InitialCatalog: $InitialCatalog"

		Write-Verbose "installer config: $instConfigFilePath"
		& $ScriptBaseFolderPath\Deploy\Set-JsonConnection.ps1 -ConfigFilePath "$instConfigFilePath" -DataSource "$DataSource" -InitialCatalog "$InitialCatalog" -UserName $UserName -UserPsw $UserPsw

		Write-Verbose "app config: $appConfigFilePath"
		& $ScriptBaseFolderPath\Deploy\Set-JsonConnection.ps1 -ConfigFilePath "$appConfigFilePath" -DataSource "$DataSource" -InitialCatalog "$InitialCatalog" -UserName $UserName -UserPsw $UserPsw
		$script:Result = $LASTEXITCODE
	}
	catch {
		$script:Result = 1
	}
}

Function Step-Docker-SetInstallerConnectionWithDockerDb {
	<#
	.SYNOPSIS
	temp Set installer json configurations
	.DESCRIPTION
	
	#>
	[CmdletBinding()]
	Param(
		[Parameter(Mandatory=$false)]
		[string]$Section="Project"
		)
	
	$LASTEXITCODE = 0
	try {
		# get docker sql ip
		$msSqlIp = docker inspect --format '{{ .NetworkSettings.Networks.nat.IPAddress }}' sql1
		Write-Output "Container sql server ip: $msSqlIp"

		#$aConfigFilePath = Get-FullPath $GlobalSettings."$Section".InstallerCfgFilePath
		$configFilePath = Get-FullPath "..\temp\Templates\src\netcore\SnWebApplicationWithIdentity\SnConsoleInstaller\appsettings.json"
		# $DataSource=$GlobalSettings."$Section".DataSource
		$DataSource=$msSqlIp
		$InitialCatalog=$GlobalSettings."$Section".InitialCatalog 
		$UserName = $GlobalSettings."$Section".UserName
		$UserPsw = $GlobalSettings."$Section".UserPsw		

		& $ScriptBaseFolderPath\Deploy\Set-JsonConnection.ps1 -ConfigFilePath "$configFilePath" -DataSource "$DataSource" -InitialCatalog "$InitialCatalog" -UserName $UserName -UserPsw $UserPsw
		$script:Result = $LASTEXITCODE
	}
	catch {
		$script:Result = 1
	}
}

	
# basic createemptydb step in default packages file
Function Step-Docker-CreateEmptyDb {
	<#
	.SYNOPSIS
	Create empty sql database using docker container ip
	.DESCRIPTION
	
	#>
	[CmdletBinding()]
		Param(
		[Parameter(Mandatory=$false)]
		[string]$Section="Project"
		)
		
	$LASTEXITCODE = 0
	try {
		$networkName=$GlobalSettings."$Section".DockerNetworkName

		# get docker sql ip
		$msSqlIp = docker inspect --format "{{ .NetworkSettings.Networks.$($networkName).IPAddress }}" sql1
		Write-Output "Container sql server ip: $msSqlIp"

		# $DataSource=$GlobalSettings."$Section".DataSource
		$DataSource=$msSqlIp
		$InitialCatalog=$GlobalSettings."$Section".InitialCatalog 
		$UserName=$GlobalSettings."$Section".UserName 
		$Password=$GlobalSettings."$Section".UserPsw 
		& $ScriptBaseFolderPath\Ops\Create-EmptyDb.ps1 -ServerName "$DataSource" -CatalogName "$InitialCatalog" -UserName $UserName -Password $Password
		$script:Result = $LASTEXITCODE
	}
	catch {
		$script:Result = 1
	}
}

Function Step-Docker-DropDockerDb {
	<#
		.SYNOPSIS
		Drop sql database
		.DESCRIPTION
		
		#>
		[CmdletBinding()]
			Param(
			[Parameter(Mandatory=$false)]
			[string]$Section="Project"
			)
			
		try {
			$networkName=$GlobalSettings."$Section".DockerNetworkName

			# get docker sql ip
			$msSqlIp = docker inspect --format {{ .NetworkSettings.Networks.$($networkName).IPAddress }} sql1
			Write-Output "Container sql server ip: $msSqlIp"

			# $DataSource=$GlobalSettings."$Section".DataSource
			$DataSource=$msSqlIp
			$InitialCatalog=$GlobalSettings."$Section".InitialCatalog 
			$UserName=$GlobalSettings."$Section".UserName 
			$Password=$GlobalSettings."$Section".UserPsw 
			& $ScriptBaseFolderPath\Ops\Drop-Db.ps1 -ServerName "$DataSource" -CatalogName "$InitialCatalog" -UserName $UserName -Password $Password
			$script:Result = $LASTEXITCODE
		}
		catch {
			$script:Result = 1
			Write-Output "$_"
		}
		
	}



	Function Step-Docker-CallConsoleInstallerWithDockerAndSqlContainer {
		<#
		.SYNOPSIS
		run .net core console installer from docker container
		.DESCRIPTION
		
		#>	
		[CmdletBinding()]
		Param(
			[Parameter(Mandatory=$false)]
			[string]$Section="Project"
		)
		
		$LASTEXITCODE = 0
		try {	
			$networkName=$GlobalSettings."$Section".DockerNetworkName
	
			# get docker sql ip
			$msSqlIp = docker inspect --format "{{ .NetworkSettings.Networks.$($networkName).IPAddress }}" sql1
			$msSqlPort = docker inspect --format "{{ .NetworkSettings.Ports."80//tcp".HostPort }}" $containerName
			Write-Output "Container sql server ip: $msSqlIp"
			
			# $DataSource=$GlobalSettings."$Section".DataSource
			$DataSource=$msSqlIp
			
			Write-Output "Container webapp ip: $webAppIp"
			Write-Output "Container webapp port: $webAppPort"
	
			#linux hack
			#$DataSource="172.17.17.137,1433"
	
			$InitialCatalog=$GlobalSettings."$Section".InitialCatalog 
			$UserName=$GlobalSettings."$Section".UserName 
			$UserPsw=$GlobalSettings."$Section".UserPsw 
	
			Write-Output "Datasource: $DataSource"
			Write-Output "InitialCatalog: $InitialCatalog"
	
			if ($UserName) {
				Write-Output "With $UserName and $UserPsw"
				$ConnectionString = "Persist Security Info=False;Initial Catalog=$($InitialCatalog);Data Source=$($DataSource);User ID=$($UserName);Password=$($UserPsw)"
			} else {
				$ConnectionString = "Persist Security Info=False;Initial Catalog=$($InitialCatalog);Data Source=$($DataSource);Integrated Security=true"
			}
	
			$webAppName=$GlobalSettings."$Section".WebAppName 
			$imageName="$($webAppName)installerimg"
			$containerName="$($webAppName)installercnt"
			
			# start installer
			docker run -it --rm --volume=c:\temp\1\:\app -e ConnectionStrings__SnCrMsSql=$ConnectionString --name $containerName $imageName
			#docker run -it --rm --name installertestcnt installertest
	
			$script:Result = $LASTEXITCODE
		}
		catch {
			$script:Result = 1
		}
	}

	Function Step-Docker-StartNetCoreWebAppWithSqlContainer {
		<#
		.SYNOPSIS
		start .netcore web application in docker container
		.DESCRIPTION
		
		#>	
		[CmdletBinding()]
		Param(
			[Parameter(Mandatory=$false)]
			[string]$Section="Project"
		)
		
		$LASTEXITCODE = 0
		try {	
			$networkName = "bridge"
	
			# get docker sql ip
			$msSqlIp = docker inspect --format "{{ .NetworkSettings.Networks.$networkName.IPAddress }}" sql1
			Write-Output "Container sql server ip: $msSqlIp"
			
			# $DataSource=$GlobalSettings."$Section".DataSource
			$DataSource=$msSqlIp
			$InitialCatalog=$GlobalSettings."$Section".InitialCatalog 
			$UserName=$GlobalSettings."$Section".UserName 
			$UserPsw=$GlobalSettings."$Section".UserPsw 
	
			if ($UserName) {
				$ConnectionString = "Persist Security Info=False;Initial Catalog=$($InitialCatalog);Data Source=$($DataSource);User ID=$($UserName);Password=$($UserPsw)"
			} else {
				$ConnectionString = "Persist Security Info=False;Initial Catalog=$($InitialCatalog);Data Source=$($DataSource);Integrated Security=true"
			}
	
			$webAppName=$GlobalSettings."$Section".WebAppName 
			$imageName="$($webAppName)img"
			$containerName="$($webAppName)cnt"
	
			# start netcore
			Write-Output "docker run -it --rm -e ConnectionStrings__SnCrMsSql="$ConnectionString" --name $containerName $imageName"
			docker run -d --rm -p 3333:80 -p 3334:443 -e ConnectionStrings__SnCrMsSql=$ConnectionString --name $containerName $imageName
	
			# get docker sql ip
			$webAppIp = docker inspect --format "{{ .NetworkSettings.Networks.$networkName.IPAddress }}" $containerName
			Write-Output "Container webapp ip: $webAppIp"
			
			$script:Result = $LASTEXITCODE
		}
		catch {
			$script:Result = 1
		}
	}

	Function Step-Docker-TagDockerImage {
		<#
		.SYNOPSIS
		tag docker image according to settings
		.DESCRIPTION

		#>	
		[CmdletBinding()]
		Param(
			[Parameter(Mandatory=$false)]
			[string]$Section="Project"
		)
		
		$LASTEXITCODE = 0
		try {	
			$DockerRegistryName=$GlobalSettings."$Section".DockerRegistryName
			$DockerImageName=$GlobalSettings."$Section".DockerImageName
			$Date = Get-Date -format "yyyy.MM.dd"

			# build docker image for installer
			docker tag "$($DockerImageName)" "$($DockerRegistryName)/$($DockerImageName):$($Date)"
			
			$script:Result = $LASTEXITCODE
		}
		catch {
			$script:Result = 1
		}
	}

	Function Step-Docker-PublishDockerImage {
		<#
		.SYNOPSIS
		tag docker image according to settings
		.DESCRIPTION

		#>	
		[CmdletBinding()]
		Param(
			[Parameter(Mandatory=$false)]
			[string]$Section="Project"
		)
		
		$LASTEXITCODE = 0
		try {	
			$DockerRegistryName=$GlobalSettings."$Section".DockerRegistryName
			$DockerImageName=$GlobalSettings."$Section".DockerImageName
			$Date = Get-Date -format "yyyy.MM.dd"

			# build docker image for installer
			docker push "$($DockerRegistryName)/$($DockerImageName):$($Date)"
			
			$script:Result = $LASTEXITCODE
		}
		catch {
			$script:Result = 1
		}
	}