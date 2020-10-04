# ******************************************************************  Steps ******************************************************************
Function Step-CreateDevCert {
	<#
		.SYNOPSIS
		create dev cert
		.DESCRIPTION
		
		#>	
	[CmdletBinding(SupportsShouldProcess = $True)]
	Param(
		[Parameter(Mandatory = $false)]
		[string]$Section = "Project"
	)
		
	$LASTEXITCODE = 0
	try {	
		dotnet dev-certs https -ep $env:USERPROFILE\.aspnet\https\aspnetapp.pfx -p pwd8hGbmSaxynW6r5mVqc
		dotnet dev-certs https --trust
			
		$script:Result = $LASTEXITCODE
	}
	catch {
		$script:Result = 1
	}
}

Function Step-RemoveDevCert {
	<#
		.SYNOPSIS
		remove dev cert
		.DESCRIPTION
		
		#>	
	[CmdletBinding(SupportsShouldProcess = $True)]
	Param(
		[Parameter(Mandatory = $false)]
		[string]$Section = "Project"
	)
		
	$LASTEXITCODE = 0
	try {	
		dotnet dev-certs https --clean
			
		$script:Result = $LASTEXITCODE
	}
	catch {
		$script:Result = 1
	}
}

Function Step-RegisterCertAuthority {
	<#
		.SYNOPSIS
		register local dev cert authority
		.DESCRIPTION
		
		#>	
	[CmdletBinding(SupportsShouldProcess = $True)]
	Param(
		[Parameter(Mandatory = $false)]
		[string]$Section = "Project"
	)
		
	$LASTEXITCODE = 0
	try {	
		../tools/mkcert/mkcert-v1.4.1-windows-amd64.exe -install
			
		$script:Result = $LASTEXITCODE
	}
	catch {
		$script:Result = 1
	}
}

Function Step-CreateDockerCert {
	<#
		.SYNOPSIS
		create local docker cert
		.DESCRIPTION
		
		#>	
	[CmdletBinding(SupportsShouldProcess = $True)]
	Param(
		[Parameter(Mandatory = $false)]
		[string]$Section = "Project"
	)
		
	$LASTEXITCODE = 0
	try {	
		. ../tools/mkcert/mkcert-v1.4.1-windows-amd64.exe -cert-file ../tools/mkcert/certs/host.docker.internal.crt -key-file ../tools/mkcert/certs/host.docker.internal.key -install host.docker.internal *.host.docker.internal kubernetes.docker.internal *.kubernetes.docker.internal localhost 127.0.0.1 ::1
		. ../tools/openssl/openssl.exe pkcs12 -export -out ../certificate/host.docker.internal.pfx -inkey ../tools/mkcert/certs/host.docker.internal.key -in ../tools/mkcert/certs/host.docker.internal.crt -password pass:QWEasd123%
		#& ../tools/mkcert/certs/create.ps1
			
		$script:Result = $LASTEXITCODE
	}
	catch {
		$script:Result = 1
	}
}

Function Step-CopyCertificate {
	<#
	.SYNOPSIS
	Copy certificates to solution folder
	.DESCRIPTION
	
	#>	
	[CmdletBinding(SupportsShouldProcess=$True)]
	Param(
		[Parameter(Mandatory=$false)]
		[string]$Section="Project"
	)
	
	$exitcode = 0
	try {
		#$RemoteContainer = Get-FullPath $GlobalSettings.Source.RemotePackagesPath
		$SourcePath = "../certificate"
		$TargetPath = Get-FullPath $GlobalSettings."$Section".SolutionFolderPath
	
		Write-Output "Copy certificates"
		Write-Output "Source: $SourcePath"
		Write-Output "Target: $TargetPath"
		if (Test-Path $SourcePath) {
			try{
				Copy-Item -Path "$SourcePath" -Destination "$TargetPath" -force -Recurse
			}
			catch {
				Write-Output $_.Exception
				exitcode = 1
			}
		} else {
			Write-Output "Remote package folder does not exists or cannot be accessed."
		}

		$script:Result = $exitcode
	}
	catch {
		$script:Result = 1
	}
}