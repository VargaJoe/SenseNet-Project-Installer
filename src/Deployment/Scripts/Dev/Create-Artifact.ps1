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
	$vsWhere = "D:\development\work\SnInstallClientTest\Deployment\Tools\vswhere\vswhere.exe"
	$msbuildPath = & "$vsWhere" -latest -requires Microsoft.Component.MSBuild -find MSBuild\**\Bin\MSBuild.exe | select-object -first 1
}

Write-Verbose "================================================"
Write-Verbose "====== Build Sense/Net Solution ================"
Write-Verbose "================================================"

$slnPath = [IO.Path]::GetFullPath($slnPath)
Write-Verbose "Solution fullpath: $slnPath"


Write-Verbose "$msBuildPath $slnPath /p:Configuration=Release /p:DeployOnBuild=true /p:WebPublishMethod=Package /p:PackageAsSingleFile=true /p:SkipInvalidConfigurations=true"

& "$msBuildPath" "$slnPath" /p:Configuration="$buildMode" /p:DeployOnBuild=true /p:WebPublishMethod=Package /p:PackageAsSingleFile=true /p:SkipInvalidConfigurations=true /p:AutoParameterizationWebConfigConnectionStrings=False

# TECHNICAL DEBT: the following code snippet case some unexpected results so don't use it for now'
#| & $Output

Write-Verbose "have been run: $msBuildPath $slnPath /p:Configuration=Release /p:DeployOnBuild=true /p:WebPublishMethod=Package /p:PackageAsSingleFile=true /p:SkipInvalidConfigurations=true"

exit $LASTEXITCODE