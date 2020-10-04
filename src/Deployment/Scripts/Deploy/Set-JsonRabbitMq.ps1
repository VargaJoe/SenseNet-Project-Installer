[CmdletBinding(SupportsShouldProcess=$True)]
Param(
    [Parameter(Mandatory=$true)]
    [string]$ConfigFilePath,
    [Parameter(Mandatory=$true)]
    [string]$RabbitMqServiceUrl
)

$exitCode = 0

Write-Output "Set rabbitmq value to: $RabbitMqServiceUrl"
Write-Output "in config file: $ConfigFilePath"

try {
    $doc = Get-Content "$ConfigFilePath" -raw | ConvertFrom-Json
    Write-Host 1 $doc    
    Write-Host 2 $doc.sensenet
    Write-Host 3 $doc.sensenet.rabbitmq
    $doc.sensenet.rabbitmq = $RabbitMqServiceUrl
    $doc | ConvertTo-Json -depth 10 | set-content "$ConfigFilePath"
}
catch {
    Write-Verbose "Exception: $_.Exception"
    $exitCode = 1
}

exit $exitCode