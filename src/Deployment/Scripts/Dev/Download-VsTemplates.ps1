Param (
	[Parameter(Mandatory=$False)]
	[string]$Url = "https://github.com/SenseNet/sn-vs-projecttemplates",
	[Parameter(Mandatory=$False)]
	[string]$TargetPath = "..\..\Templates"
)

$LastExitCode = 0

if (Test-Path $TargetPath\.git) {
	write-host "Template folder already exists!"	
	& git --git-dir="$TargetPath\.git" --work-tree="$TargetPath" pull
} else {
	write-host "Nuget file downloading started..."
	& git clone "$Url" "$TargetPath"
}

exit $LastExitCode