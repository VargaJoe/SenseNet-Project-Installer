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

$lib = [System.Runtime.InteropServices.RuntimeEnvironment]
$rtd = $lib::GetRuntimeDirectory()
$MsBuildPath = Join-Path $rtd msbuild.exe
$devenvPath = "c:\Program Files (x86)\Microsoft Visual Studio\2017\Enterprise\Common7\IDE\devenv.com"
#$devenvPath = ((get-itemproperty -literalpath "hklm:\SOFTWARE\Microsoft\Windows\CurrentVersion\App Paths\devenv.exe").'(default)').replace(".exe",".com").Replace("`"","")

# Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass 
# Set-ExecutionPolicy Unrestricted  



Write-Host "$devenvPath" "$slnPath" /build Debug
& "$devenvPath" "$slnPath" /build Debug
Write-Host Exit Code: $LASTEXITCODE

#Write-Host have been run: $MsBuildpath $slnPath /t:Rebuild /p:Configuration=Debug /p:VisualStudioVersion=14.0
Write-Host have been run: "$devenvPath" "$slnPath" /Rebuild Debug

