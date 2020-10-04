[CmdletBinding(SupportsShouldProcess=$True)]
Param(
    [Parameter(Mandatory=$true)]
    [string]$ConfigFilePath,
    [Parameter(Mandatory=$true)]
    [string[]]$ImportPackages
)

# custom function in this separate script due to independence
function Set-ConnectionString {
	Param(
            [Parameter(Mandatory=$True)]
            [String]$ConfigPath,
			[Parameter(Mandatory=$True)]
            [String[]]$ImportPackages
         )
	
    $doc = Get-Content "$ConfigPath" -raw | ConvertFrom-Json
    Write-Host 1 $doc.sensenet
    Write-Host 2 $doc.sensenet.install
    Write-Host 3 $doc.sensenet.install.import
    # $doc.sensenet.install.import = @( $ImportPackages )    
    $doc.sensenet.install.import = $ImportPackages 
    $doc | ConvertTo-Json -depth 10 | set-content "$ConfigPath"
}


#$LASTEXITCODE = 0

Write-Output "Set import packages string value: $ImportPackages"
Write-Output "in config file: $ConfigFilePath"

Write-Output "te following packages willbe set:"
foreach ($package in $ImportPackages) {
    Write-Output "`t $package"
}

Set-ConnectionString -ConfigPath "$ConfigFilePath" -ImportPackages $ImportPackages

exit $LASTEXITCODE