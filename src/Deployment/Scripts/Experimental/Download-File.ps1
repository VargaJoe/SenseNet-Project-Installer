$url="https://dist.nuget.org/win-x86-commandline/latest/nuget.exe"
$output="..\..\Tools\nuget\nuget.exe"

if (Test-Path $output) {
	write-host "Nuget file already exists!"	
} else {
	write-host "Nuget file downloading started..."
	Invoke-WebRequest -Uri $url -OutFile $output
}