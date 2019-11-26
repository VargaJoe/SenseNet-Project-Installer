$exitcode = -1

If (-NOT ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole(`
    [Security.Principal.WindowsBuiltInRole] "Administrator"))
{
    Write-Warning "You do not have Administrator rights to run this script!`nPlease re-run this script as an Administrator!"
    $exitcode = 1
} else {
    Write-Output "You have Administrator rights to run this script!`nYou are so cool!"
    $exitcode = 0
}

exit $exitcode





