# ******************************************************************  Steps ******************************************************************
Function Step-StartNugetFeed {
	<#
	.SYNOPSIS
	test docker container for internal nuget feed
	.DESCRIPTION
	
	#>	
	[CmdletBinding(SupportsShouldProcess=$True)]
	Param(
		[Parameter(Mandatory=$false)]
		[string]$Section="Project"
	)
	
	$LASTEXITCODE = 0
	try {	
		$nugetContainer = $GlobalSettings."$Section".TestNugetFolderPath
		$volumesetting = "$($nugetcontainer):C:/nuget.server.web/NuGet.Server.Web/Packages"
		
		# nuget feed
		#https://hub.docker.com/r/coderobin/nuget.server/
		Write-Output "Start nugetfeed container with $volumeSetting"
		docker run -d --name nuget --hostname nuget --rm -v $volumeSetting coderobin/nuget.server:latest

		# get user info
		docker exec nuget powershell cat C:\nuget.server.web\NuGet.Server.Web\App_Data\UserCredentials.xml

		$nugetIp = docker inspect --format '{{ .NetworkSettings.Networks.nat.IPAddress }}' nuget
		Write-Output "Nuget feed ip: $nugetip"
		
		$script:Result = $LASTEXITCODE
	}
	catch {
		$script:Result = 1
	}
}

Function Step-GetNugetFeed {
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
		# get user info
		docker exec nuget powershell cat C:\nuget.server.web\NuGet.Server.Web\App_Data\UserCredentials.xml

		# nuget feed
		$nugetIp = docker inspect --format '{{ .NetworkSettings.Networks.nat.IPAddress }}' nuget
		Write-Output "Nuget feed ip: $nugetip"
		
		$script:Result = $LASTEXITCODE
	}
	catch {
		$script:Result = 1
	}
}

Function Step-StartContainerSql {
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
		# UserName is defaul sa
		#$UserName = $GlobalSettings."$Section".UserName
		$UserPsw = $GlobalSettings."$Section".UserPsw
		
		# Start mssql container
		Write-Output "docker run --rm -it -e ACCEPT_EULA=Y -e sa_password=$($UserPsw) -p 1433:1433 -d --name sql1 microsoft/mssql-server-windows-developer:2017-latest"
		docker run --rm -it -e ACCEPT_EULA=Y -e sa_password=$($UserPsw) -p 1433:1433 -d --name sql1 microsoft/mssql-server-windows-developer:2017-latest
		
		# get mssql ip
		$msSqlIp = docker inspect --format '{{ .NetworkSettings.Networks.nat.IPAddress }}' sql1
		Write-Output "Container sql server ip: $msSqlIp"
		
		$script:Result = $LASTEXITCODE
	}
	catch {
		$script:Result = 1
	}
}

Function Step-GetContainerSql {
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
		# get docker sql ip
		$msSqlIp = docker inspect --format '{{ .NetworkSettings.Networks.nat.IPAddress }}' sql1
		Write-Output "Container sql server ip: $msSqlIp"
		
		$script:Result = $LASTEXITCODE
	}
	catch {
		$script:Result = 1
	}
}

Function Step-PrepareNugetConfig {
	<#
	.SYNOPSIS
	temp prepare nuget config with test feed
	.DESCRIPTION
	
	#>	
	[CmdletBinding(SupportsShouldProcess=$True)]
	Param(
		[Parameter(Mandatory=$false)]
		[string]$Section="Project"
	)
	
	$LASTEXITCODE = 0
	try {	
		$baseNugetconfig = Get-FullPath "..\nuget\nuget-internal.config"
		$targetNugetconfig = Get-FullPath "..\temp\Templates\src\netcore\SnWebApplicationWithIdentity\nuget.config"
		Copy-Item "${baseNugetconfig}" "${targetNugetconfig}"
		
		$nugetIp = docker inspect --format '{{ .NetworkSettings.Networks.nat.IPAddress }}' nuget

		$xmlNugetconfig = [xml](Get-Content $targetNugetconfig)

		$nugetFeed = "http://$($nugetIp)/nuget"

		$newFeed = $xmlNugetconfig.CreateElement("add")		
		$xmlNugetconfig.configuration.packageSources.AppendChild($newFeed)
		$newFeed.SetAttribute("key","testfeed")
		$newFeed.SetAttribute("value","$nugetFeed")

		$pDriveFeed = $xmlNugetconfig.SelectSingleNode("//add[@key='LocalFolder']")
		$xmlNugetconfig.configuration.packageSources.RemoveChild($pDriveFeed)

		$credElement = $xmlNugetconfig.CreateElement("packageSourceCredentials")
		$xmlNugetconfig.configuration.AppendChild($credElement)
		$testElement = $xmlNugetconfig.CreateElement("testfeed")
		$credElement.AppendChild($testElement)
		$userElement = $xmlNugetconfig.CreateElement("add")
		$testElement.AppendChild($userElement)
		$userElement.SetAttribute("key","Username")
		$userElement.SetAttribute("value","nugetuser")

		$passElement = $xmlNugetconfig.CreateElement("add")
		$testElement.AppendChild($passElement)
		$passElement.SetAttribute("key","ClearTextPassword")
		$passElement.SetAttribute("value","nugetpass")
		
		Write-Output "target file: $targetNugetconfig"
		$xmlNugetconfig.Save($targetNugetconfig)

		$script:Result = $LASTEXITCODE
	}
	catch {
		$script:Result = 1
		Write-Error "$_"
	}
}

Function Step-SetInstallerConnection {
	<#
	.SYNOPSIS
	temp Set installer json configurations
	.DESCRIPTION
	
	#>
	[CmdletBinding(SupportsShouldProcess=$True)]
	Param(
		[Parameter(Mandatory=$false)]
		[string]$Section="Project"
		)
	
	$LASTEXITCODE = 0
	try {
		#$aConfigFilePath = Get-FullPath $GlobalSettings."$Section".InstallerCfgFilePath
		$configFilePath = Get-FullPath "..\temp\Templates\src\netcore\SnWebApplicationWithIdentity\SnConsoleInstaller\appsettings.json"
		$DataSource=$GlobalSettings."$Section".DataSource
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

Function Step-SetInstallerConnectionWithDockerDb {
	<#
	.SYNOPSIS
	temp Set installer json configurations
	.DESCRIPTION
	
	#>
	[CmdletBinding(SupportsShouldProcess=$True)]
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

Function Step-BuildInstallerImage {
	<#
	.SYNOPSIS
	build .net core console installer image
	.DESCRIPTION
	build .net core console installer image from  netcore SnWebApplicationWithIdentity of vs templates
	#>	
	[CmdletBinding(SupportsShouldProcess=$True)]
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

Function Step-DropDockerDb {
	<#
		.SYNOPSIS
		Drop sql database
		.DESCRIPTION
		
		#>
		[CmdletBinding(SupportsShouldProcess=$True)]
			Param(
			[Parameter(Mandatory=$false)]
			[string]$Section="Project"
			)
			
		try {
			# get docker sql ip
		$msSqlIp = docker inspect --format '{{ .NetworkSettings.Networks.nat.IPAddress }}' sql1
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

# basic createemptydb step in default packages file
Function Step-CreateEmptyDockerDb {
	<#
	.SYNOPSIS
	Create empty sql database using docker container ip
	.DESCRIPTION
	
	#>
	[CmdletBinding(SupportsShouldProcess=$True)]
		Param(
		[Parameter(Mandatory=$false)]
		[string]$Section="Project"
		)
		
	$LASTEXITCODE = 0
	try {
		# get docker sql ip
		$msSqlIp = docker inspect --format '{{ .NetworkSettings.Networks.nat.IPAddress }}' sql1
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

Function Step-CallConsoleInstallerInContainer {
	<#
	.SYNOPSIS
	run .net core console installer from docker container
	.DESCRIPTION
	
	#>	
	[CmdletBinding(SupportsShouldProcess=$True)]
	Param(
		[Parameter(Mandatory=$false)]
		[string]$Section="Project"
	)
	
	$LASTEXITCODE = 0
	try {	
		# get docker sql ip
		$msSqlIp = docker inspect --format '{{ .NetworkSettings.Networks.nat.IPAddress }}' sql1
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

		# start installer
		docker run -it --rm -e ConnectionStrings__SnCrMsSql=$ConnectionString --name installertestcnt installertest
		#docker run -it --rm --name installertestcnt installertest

		$script:Result = $LASTEXITCODE
	}
	catch {
		$script:Result = 1
	}
}

Function Step-BuildNetcoreWebAppImage {
	<#
	.SYNOPSIS
	build .net core webapp image
	.DESCRIPTION
	build .net core webapp image from  netcore SnWebApplicationWithIdentity of vs templates
	#>	
	[CmdletBinding(SupportsShouldProcess=$True)]
	Param(
		[Parameter(Mandatory=$false)]
		[string]$Section="Project"
	)
	
	$LASTEXITCODE = 0
	try {	
		# build docker image
		docker build -t netcoretest -f .\settings\project-netcoredocker.dockerfile ..\temp\Templates\src\netcore\SnWebApplicationWithIdentity
		
		$script:Result = $LASTEXITCODE
	}
	catch {
		$script:Result = 1
	}
}

Function Step-StartNetCoreWebApp {
	<#
	.SYNOPSIS
	start .netcore web application in docker container
	.DESCRIPTION
	
	#>	
	[CmdletBinding(SupportsShouldProcess=$True)]
	Param(
		[Parameter(Mandatory=$false)]
		[string]$Section="Project"
	)
	
	$LASTEXITCODE = 0
	try {	
		# get docker sql ip
		$msSqlIp = docker inspect --format '{{ .NetworkSettings.Networks.nat.IPAddress }}' sql1
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

		# start netcore
		Write-Output "docker run -it --rm -e ConnectionStrings__SnCrMsSql="$ConnectionString" --name netcoretestcnt netcoretest"
		docker run -d --rm -e ConnectionStrings__SnCrMsSql=$ConnectionString --name netcoretestcnt netcoretest

		# get docker sql ip
		$webAppIp = docker inspect --format '{{ .NetworkSettings.Networks.nat.IPAddress }}' netcoretestcnt
		Write-Output "Container sql server ip: $webAppIp"
		
		$script:Result = $LASTEXITCODE
	}
	catch {
		$script:Result = 1
	}
}

Function Step-GetNetCoreWebApp {
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
		# get docker sql ip
		$webAppIp = docker inspect --format '{{ .NetworkSettings.Networks.nat.IPAddress }}' netcoretestcnt
		Write-Output "Container sql server ip: $webAppIp"

		$script:Result = $LASTEXITCODE
	}
	catch {
		$script:Result = 1
		Write-Error "$_"
	}
}

Function Step-OpenNetCoreWebApp {
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
		# get docker sql ip
		$webAppIp = docker inspect --format '{{ .NetworkSettings.Networks.nat.IPAddress }}' netcoretestcnt
		Write-Output "Container sql server ip: $webAppIp"
		
		Write-Output "Try to open in chrome..."
		Start-Process "chrome.exe" $webAppIp
		Write-Output "Done. Use should've seen now."

		$script:Result = $LASTEXITCODE
	}
	catch {
		$script:Result = 1
		Write-Error "$_"
	}
}

Function Step-StopNetCoreWebApp {
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
		$containerName = "netcoretestcnt"
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

Function Step-StopContainerSql {
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
		$containerName = "sql1"
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

Function Step-StopNugetFeed {
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
		$containerName = "nuget"
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

Function Step-PruneContainers {
	<#
	.SYNOPSIS
	remove containers before test from scratch again
	.DESCRIPTION
	
	#>	
	[CmdletBinding(SupportsShouldProcess=$True)]
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
