Param (
	[Parameter(Mandatory=$False)]
	[string]$Url,
	[Parameter(Mandatory=$False)]
	[string]$TargetPath,
	[Parameter(Mandatory=$False)]
	[string]$BranchName = "master"
)

$LastExitCode = 0

Write-Output "Source git repo: $Url"
Write-Output "Target folder: $TargetPath"
Write-Output "Selected branch: $BranchName"
Write-Output ""
if (Test-Path $TargetPath\.git) {
	write-host "Template folder already exists!"
	$currentBranch = (git --git-dir="$TargetPath\.git" --work-tree="$TargetPath" rev-parse --abbrev-ref HEAD).Trim()
	Write-Output "Current branch: $currentBranch"
	if (-Not($BranchName -eq $currentBranch)) {
		& git --git-dir="$TargetPath\.git" --work-tree="$TargetPath" fetch
		& git --git-dir="$TargetPath\.git" --work-tree="$TargetPath" checkout $BranchName 
	}
	& git --git-dir="$TargetPath\.git" --work-tree="$TargetPath" pull 
} 
else 
{
	write-host "Git reposiotry downloading started..."
	& git clone --branch $BranchName "$Url" "$TargetPath" 	
}

exit $LastExitCode