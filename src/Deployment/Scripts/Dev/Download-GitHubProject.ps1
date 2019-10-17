Param (
	[Parameter(Mandatory=$true)]
	[string]$GitHubrepo,
	[Parameter(Mandatory=$true)]
	[string]$TargetPath
)

$LastExitCode = 0

if (Test-Path $TargetPath\.git) {
	write-host "Temporary\SnDocs folder already exists!"	
	& git --git-dir="$TargetPath\.git" --work-tree="$TargetPath" pull
} else {
	write-host "Documents repository downloading started..."
	& git clone "$GitHubrepo" "$TargetPath"
}

exit $LastExitCode