Param (
	[Parameter(Mandatory=$True)]
	[string]$Url,
	[Parameter(Mandatory=$True)]
	[string]$TargetFolderPath
)

$filename = $Url.Substring($Url.LastIndexOf("/") + 1)
$output=[IO.Path]::Combine($TargetFolderPath, $filename) 


if (Test-Path $output) {
	write-host "Url file already exists!"	
} else {
	write-host "Url downloading started..."
	Invoke-WebRequest -Uri $url -OutFile $output
}