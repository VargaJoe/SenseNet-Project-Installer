Param (
	[Parameter(Mandatory=$True)]
	[string]$Url,
	[Parameter(Mandatory=$True)]
	[string]$Output
)

#$url="https://dist.nuget.org/win-x86-commandline/latest/nuget.exe"
#$output="..\..\Tools\nuget\nuget.exe"

if (Test-Path $Output) {
	write-host "File already exists!"	
} else {
	write-host "File downloading started..."
	Invoke-WebRequest -Uri $Url -OutFile $Output
}