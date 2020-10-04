[CmdletBinding(SupportsShouldProcess=$True)]
Param(
    [Parameter(Mandatory=$true)]
    [string]$ConfigFilePath,
    [Parameter(Mandatory=$true)]
    [string]$AuthenticationAuthority
)

# custom function in this separate script due to independence
function Set-ConnectionString {
	Param(
            [Parameter(Mandatory=$True)]
            [String]$ConfigPath,
			[Parameter(Mandatory=$True)]
            [String]$AuthenticationAuthority
         )
	
    $doc = Get-Content "$ConfigPath" -raw | ConvertFrom-Json
    Write-Host 1 $doc    
    Write-Host 2 $doc.sensenet
    Write-Host 3 $doc.sensenet.authentication
    Write-Host 4 $doc.sensenet.authentication.authority
    $doc.sensenet.authentication.authority = $AuthenticationAuthority
    $doc | ConvertTo-Json -depth 10 | set-content "$ConfigPath"
}


$LASTEXITCODE = 0

Write-Output "Create new authority value: $AuthenticationAuthority"
Write-Output "in config file: $ConfigFilePath"
Set-ConnectionString -ConfigPath "$ConfigFilePath" -AuthenticationAuthority "$AuthenticationAuthority"

exit $LASTEXITCODE