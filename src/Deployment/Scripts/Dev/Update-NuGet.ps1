[CmdletBinding(SupportsShouldProcess=$True)]
Param (
	[Parameter(Mandatory=$false)]
	[string]$nugetVersion = "4.1.0"
)

#Set-StrictMode -version 2.0
$ErrorActionPreference = "Stop"

# if meg nincs behuzva
#{
$SettingsPath = 'project-local.json' #ezt kulso parameternek kellene eldonteni melyik legyen
$ProjectConfig = (Get-Content $SettingsPath) -join "`n" | ConvertFrom-Json 
$NuGetFolderPath = [IO.Path]::GetFullPath($ProjectConfig.Tools.NuGetFolderPath) 
$NuGetFilePath = [IO.Path]::Combine($NuGetFolderPath, "NuGet.exe")
#}

Write-Verbose "================================================"
Write-Verbose "UPGRADE NUGET IF NECESSARY"
Write-Verbose "================================================"
Write-Verbose "NuGet command-line tool parent folder path: $NuGetFolderPath"
Write-Verbose "NuGet command-line tool file path: $NuGetFilePath"

try {
	Write-Verbose "Helper functions initialization from $Initfunctions"
	# . ".\init-functions.ps1"

    $tempdownloadDirectoryPath = "nuget"
    $tempFile = Join-Path $tempdownloadDirectoryPath "NuGet.exe"
    $versionFile = Join-Path $tempdownloadDirectoryPath "version.txt"

    New-Directory $NuGetFolderPath
    New-Directory $tempdownloadDirectoryPath

    # Check and see if we already have a NuGet.exe which exists and is the correct version.
    if ((Test-Path $NuGetFilePath) -and (Test-Path $tempFile) -and (Test-Path $versionFile)) {
        $destHash = (Get-FileHash $NuGetFilePath -algorithm MD5).Hash
        $scratchHash = (Get-FileHash $tempFile -algorithm MD5).Hash
        $scratchVersion = Get-Content $versionFile
        if (($destHash -eq $scratchHash) -and ($scratchVersion -eq $nugetVersion)) {
            Write-Verbose "Using existing NuGet.exe at version $nuGetVersion"
            exit 0
        }
    }

    Write-Verbose "Downloading NuGet $nugetVersion..."
    $webClient = New-Object -TypeName "System.Net.WebClient"
    $webClient.DownloadFile("https://dist.nuget.org/win-x86-commandline/v$nugetVersion/NuGet.exe", $tempFile)
    $nugetVersion | Out-File $versionFile
    Copy-Item $tempFile $NuGetFilePath
    exit 0
}
catch [exception] {
    Write-Verbose "$_.Exception"
    exit 1
}

