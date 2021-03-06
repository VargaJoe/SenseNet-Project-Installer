[CmdletBinding(SupportsShouldProcess=$True)]
Param(
	[Parameter(Mandatory=$True)]
	[string]$slnPath,
	[Parameter(Mandatory=$False)]
	[string]$buildMode = "Release",
	[Parameter(Mandatory=$False)]
	[string]$msbuildPath
)

$LASTEXITCODE = 0
# $Output = if ($ShowOutput -eq $True) {"Out-Default"} else {"Out-Null"}

if (!$msbuildPath) {
	$vsWhereFilePath = Get-FullPath "..\Tools\vswhere\vswhere.exe"
	Write-Output "The msbuild.exe path is missing, we try to locate it with $vsWhereFilePath"
	if (!(Test-Path $vsWhereFilePath)) {
		Write-Output "$vsWhereFilePath is missing too, we will try to retrieve it from github..."
		$vswhereSourceJsonUrl = "https://api.github.com/repos/Microsoft/vswhere/releases/latest"
		Write-Output "Get update info from $vswhereSourceJsonUrl"
		try {
			# Get latest release information
			[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
			$vswhereSourceJson = (Invoke-WebRequest $vswhereSourceJsonUrl | ConvertFrom-Json)

			# technical Debt: array should be filtered
			$latestObj = $vswhereSourceJson.assets[0] #| Where-Object -FilterScript { $_.Naem -eq "vswhere.exe" }			
			$vswhereFileUrl = $latestObj.browser_download_url
			Write-Output "Latest version of vswhere found at $vswhereFileUrl"

			# Download latest version of vswhere
			Write-Output "Downloading file to $vsWhereFilePath"
			$WebClient = New-Object System.Net.WebClient
			$WebClient.DownloadFile("$vswhereFileUrl","$vsWhereFilePath")	
		}
		catch [exception] {
			Write-Output "Retrieve a version of $vsWhereFilePath is failed, please check the error message below, or set either msbuild.exe in settings or copy vswhere.exe to the appropriate folder"
			Write-Host $_.Exception
			exit 1
		}
	}
	# Get msbuild path with the help of vswhere
	$msbuildPath = & "$vsWhereFilePath" -latest -requires Microsoft.Component.MSBuild -find MSBuild\**\Bin\MSBuild.exe | select-object -first 1
	Write-Output "Msbuild path identified as $msbuildPath"
}

Write-Output "================================================"
Write-Output "====== Build Sense/Net Solution ================"
Write-Output "================================================"

$slnPath = [IO.Path]::GetFullPath($slnPath)
Write-Output "Solution fullpath: $slnPath"


Write-Output "`"$msBuildPath`" `"$slnPath /p:Configuration=Release /p:DeployOnBuild=true /p:WebPublishMethod=Package /p:PackageAsSingleFile=true /p:SkipInvalidConfigurations=true`""

& "$msBuildPath" "$slnPath" /p:Configuration="$buildMode" /p:DeployOnBuild=true /p:WebPublishMethod=Package /p:PackageAsSingleFile=true /p:SkipInvalidConfigurations=true /p:AutoParameterizationWebConfigConnectionStrings=False

# TECHNICAL DEBT: the following code snippet case some unexpected results so don't use it for now'
#| & $Output

Write-Output "have been run: $msBuildPath $slnPath /p:Configuration=Release /p:DeployOnBuild=true /p:WebPublishMethod=Package /p:PackageAsSingleFile=true /p:SkipInvalidConfigurations=true"

exit $LASTEXITCODE