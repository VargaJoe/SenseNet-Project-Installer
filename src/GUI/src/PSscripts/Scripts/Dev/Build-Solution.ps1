[CmdletBinding(SupportsShouldProcess=$True)]
Param(
[Parameter(Mandatory=$true)]
[string]$slnPath
)

#$slnPath = [IO.Path]::GetFullPath($slnPath)

Write-Verbose "================================================"
Write-Verbose "====== Build Sense/Net Solution ================"
Write-Verbose "================================================"

$slnPath = [IO.Path]::GetFullPath($slnPath)
Write-Verbose "Solution fullpath: $slnPath"

$Output = if ($ShowOutput -eq $True) {"Out-Default"} else {"Out-Null"}
$lib = [System.Runtime.InteropServices.RuntimeEnvironment]
$rtd = $lib::GetRuntimeDirectory()
$MsBuildPath = Join-Path $rtd msbuild.exe
$devenvPath = "c:\Program Files (x86)\Microsoft Visual Studio\2017\Enterprise\Common7\IDE\devenv.com"
#$devenvPath = ((get-itemproperty -literalpath "hklm:\SOFTWARE\Microsoft\Windows\CurrentVersion\App Paths\devenv.exe").'(default)').replace(".exe",".com").Replace("`"","")

Write-Verbose "$devenvPath $slnPath /build Debug"
& "$devenvPath" "$slnPath" /build Debug

#Write-Verbose have been run: $MsBuildpath $slnPath /t:Rebuild /p:Configuration=Debug /p:VisualStudioVersion=14.0
Write-Verbose "have been run: $devenvPath $slnPath /Rebuild Debug"

exit $LASTEXITCODE
