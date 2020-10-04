# ******************************************************************  Steps ******************************************************************

Function Step-PrAsmDeployToAzure {
<#
	.SYNOPSIS
	Copy assemblies to azure
	.DESCRIPTION
	
	#>
	[CmdletBinding(SupportsShouldProcess=$True)]
		Param(
		[Parameter(Mandatory=$false)]
		[string]$Section="Production"
		)
	
	try {
		$CurrentDateTime = Get-Date -format [yyyy-MM-dd-HH-mm-ss]
		$ProjectAsmFolderPackPath = Get-FullPath $GlobalSettings.Project.AsmFolderPath
		$ProductionAsmFolderPath = Get-FullPath $GlobalSettings."$Section".AsmFolderPath
		$BackupFolderPath = Get-FullPath $GlobalSettings.Source.BackupFolderPath
		$BackupFilePath = "$($BackupFolderPath)/asmdeploy$($CurrentDateTime).zip"
		
		Write-Verbose "from: $ProjectAsmFolderPackPath"
		Write-Verbose "to: $ProductionAsmFolderPath"
		Write-Verbose "with: $BackupFolderPath"
		
		Compress-Archive -Path "$ProjectAsmFolderPackPath" -DestinationPath "$BackupFilePath"		
		
		$AzureWebAppName = $GlobalSettings."$Section".AzureWebAppName
		$username = $GlobalSettings."$Section".AzureUserName
		$password = $GlobalSettings."$Section".AzureCredentials
		$base64AuthInfo = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes(("{0}:{1}" -f $username,$password)))
		$userAgent = "powershell/1.0";
		$Headers = @{
			"Authorization"=("Basic {0}" -f $base64AuthInfo)
			"If-Match"      = "*"
		}
		
		write-verbose "$BackupFilePath"
		$apiUrl = "https://$($AzureWebAppName).scm.azurewebsites.net/api/zip/site/wwwroot/Tools/";
		Invoke-RestMethod -Uri $apiUrl -Headers $Headers -UserAgent $userAgent -Method PUT -InFile $BackupFilePath -ContentType "application/zip";
		
		# Write-Verbose "Source: $ProjectAsmFolderPackPath"
		# Write-Verbose "Target: $ProductionAsmFolderPath"
		# Copy-Item -Path "$ProjectAsmFolderPackPath/*" -Destination "$ProductionAsmFolderPath" -recurse -Force
		$script:Result = $LASTEXITCODE
	}
	catch {
		$script:Result = 1
	}
	
}

Function Step-BackupAsmFromAzure {
<#
	.SYNOPSIS
	Copy assemblies to azure
	.DESCRIPTION
	
	#>
	[CmdletBinding(SupportsShouldProcess=$True)]
		Param(
		[Parameter(Mandatory=$false)]
		[string]$Section="Production"
		)
	
	try {
		$LASTEXITCODE = 0
	
		$CurrentDateTime = Get-Date -format "(yyyy-MM-dd-HH-mm-ss)"
		$BackupFolderPath = $GlobalSettings.Source.BackupFolderPath
				
		# Write-Verbose "from: $ProjectAsmFolderPackPath"
		# Write-Verbose "to: $ProductionAsmFolderPath"
		# Write-Verbose "with: $BackupFolderPath"
		
		$AzureWebAppName = $GlobalSettings."$Section".AzureWebAppName
		$username = $GlobalSettings."$Section".AzureUserName
		$password = $GlobalSettings."$Section".AzureCredentials
		$base64AuthInfo = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes(("{0}:{1}" -f $username,$password)))
		$userAgent = "powershell/1.0";
		$Headers = @{
			"Authorization"=("Basic {0}" -f $base64AuthInfo)
			"If-Match"      = "*"
		}
		
		$filePath = Get-FullPath "$($BackupFolderPath)\azureasmbackup$($CurrentDateTime).zip"
		write-verbose "$filePath "
		$apiUrl = "https://$($AzureWebAppName).scm.azurewebsites.net/api/zip/site/wwwroot/bin/";
		Invoke-RestMethod -Uri $apiUrl -Headers $Headers -UserAgent $userAgent -Method GET -OutFile $filePath -ContentType "application/zip";
		
		# Write-Verbose "Target: $ProductionAsmFolderPath"
		# Copy-Item -Path "$ProjectAsmFolderPackPath/*" -Destination "$ProductionAsmFolderPath" -recurse -Force
		$script:Result = $LASTEXITCODE
	}
	catch {
		$script:Result = 1
	}
	
}