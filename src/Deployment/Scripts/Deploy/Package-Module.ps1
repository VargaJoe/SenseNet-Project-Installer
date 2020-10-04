[CmdletBinding(SupportsShouldProcess=$True)]
Param(
[Parameter(Mandatory=$true)]
[string]$SnAdminPath,
[Parameter(Mandatory=$true)]
[string]$PackagePath, 
[Parameter(Mandatory=$false)]
[string[]]$Parameters
)

$exitCode = -1
if (Test-Path $PackagePath) {
    $Output = if ($ShowOutput -eq $True) {"Out-Default"} else {"Out-Null"} 
    Write-Verbose "Starting: $SnAdminPath $PackagePath $Parameters"
    try{
        & $SnAdminPath $PackagePath $Parameters | & $Output
        $exitCode = 0
    } 
    catch {
        $exitCode = 1
    }
    Write-Verbose "Completed: $SnAdminPath $PackagePath $Parameters"
} else {
    Write-Verbose "Package is not present, so skipped:$PackagePath"
    $exitCode = 0
}

exit $exitCode
