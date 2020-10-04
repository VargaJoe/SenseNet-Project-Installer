[CmdletBinding(SupportsShouldProcess=$True)]
Param(
    [Parameter(Mandatory=$true)]
    [string]$ConfigFilePath,
    [Parameter(Mandatory=$True)]
    [String]$ClientId,
    [Parameter(Mandatory=$True)]
    [String]$ClientSecret,
    [Parameter(Mandatory=$False)]
    [string]$Provider = "GitHub"
)

$exitCode = -1

Write-Output "Create new client value: $ClientId"
Write-Output "in config file: $ConfigFilePath"

try {
    # custom function in this separate script due to independence
    $doc = Get-Content "$ConfigFilePath" -raw | ConvertFrom-Json
    write-output 21
    Write-Host 2 $doc.sensenet
    Write-Host 3 $doc.sensenet.authentication
    Write-Host 4 $doc.sensenet.authentication.externalproviders
    Write-Host 5 $doc.sensenet.authentication.externalproviders."$Provider"
    Write-Host 6 $doc.sensenet.authentication.externalproviders."$Provider".ClientId
    #Write-Host 7 $doc.sensenet.authentication.externalproviders."$Provider".ClientSecret
    $doc.sensenet.authentication.externalproviders."$Provider".ClientId = $ClientId
    $doc.sensenet.authentication.externalproviders."$Provider".ClientSecret = $ClientSecret
    $doc | ConvertTo-Json -depth 10 | set-content "$ConfigFilePath"
    $exitCode = 0
} catch {
    $exitCode = 1
}

exit $exitCode