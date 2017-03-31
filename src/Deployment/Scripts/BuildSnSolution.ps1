[CmdletBinding(SupportsShouldProcess=$True)]
Param(
[Parameter(Mandatory=$true)]
[string]$slnPath
)

#$slnPath = [IO.Path]::GetFullPath($slnPath)

Write-Host ================================================ -foregroundcolor "green"
Write-Host ====== Build Sense/Net Solution ================ -foregroundcolor "green"
Write-Host ================================================ -foregroundcolor "green"

$slnPath = [IO.Path]::GetFullPath($slnPath)
Write-host Solution fullpath: $slnPath

#$SNRELEASESPATH="..\.."
#$SNSRCNAME='SN6.4.0.7426test'
#$SNSRCBASEPATH=Join-Path $SNRELEASESPATH $SNSRCNAME 
#$SNDeploymentPATH=Join-Path $SNSRCBASEPATH 'Deployment'
#$SNToolsPATH=Join-Path $SNSRCBASEPATH 'Source\SenseNet\WebSite\Tools'
#$DATASOURCE='MySenseNetContentRepositoryDatasource'
#$INITIALCATALOG='powertest'
 
#$SolutionPath = Join-Path $SNSRCBASEPATH 'Source\SenseNet\SenseNet.sln'
$lib = [System.Runtime.InteropServices.RuntimeEnvironment]
$rtd = $lib::GetRuntimeDirectory()
$MsBuildPath = Join-Path $rtd msbuild.exe
$devenvPath = ((get-itemproperty -literalpath "hklm:\SOFTWARE\Microsoft\Windows\CurrentVersion\App Paths\devenv.exe").'(default)').replace(".exe",".com")

# Write-Host $MsBuildpath $SolutionPath /t:Rebuild /p:Configuration=Debug
#Write-Host will run: $MsBuildpath $slnPath /t:Build /p:Configuration=Debug /p:VisualStudioVersion=14.0

#& $MsBuildpath $slnPath /t:Rebuild /p:Configuration=Debug /p:VisualStudioVersion=14.0

& "$devenvPath" "$slnPath" /build Debug
Write-Host Exit Code: $LASTEXITCODE

#Write-Host have been run: $MsBuildpath $slnPath /t:Rebuild /p:Configuration=Debug /p:VisualStudioVersion=14.0
Write-Host have been run: "$devenvPath" "$slnPath" /Rebuild Debug

