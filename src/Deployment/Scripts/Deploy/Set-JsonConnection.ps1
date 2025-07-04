[CmdletBinding(SupportsShouldProcess=$True)]
Param(
    [Parameter(Mandatory=$true)]
    [string]$ConfigFilePath,
    [Parameter(Mandatory=$true)]
    [string]$DataSource,
    [Parameter(Mandatory=$true)]
    [string]$InitialCatalog,
	[Parameter(Mandatory=$False)]
	[string]$UserName,
	[Parameter(Mandatory=$False)]
	[string]$UserPsw
)

# custom function in this separate script due to independence
function Set-ConnectionString {
	Param(
            [Parameter(Mandatory=$True)]
            [String]$ConfigPath,
			[Parameter(Mandatory=$True)]
            [String]$ConnectionString,
            [Parameter(Mandatory=$False)]
            [string]$UserName,
            [Parameter(Mandatory=$False)]
            [string]$UserPsw
         )
	
    $doc = Get-Content "$ConfigPath" -raw | ConvertFrom-Json
    Write-Host 1 $doc    
    Write-Host 2 $doc.ConnectionStrings
    Write-Host 3 $doc.ConnectionStrings.SnCrMsSql
    $doc.ConnectionStrings.SnCrMsSql = $ConnectionString
    $doc | ConvertTo-Json -depth 10 | set-content "$ConfigPath"
}


$LASTEXITCODE = 0

if ($UserName) {
    $ConnectionString = "Persist Security Info=False;Initial Catalog=$($InitialCatalog);Data Source=$($DataSource);User ID=$($UserName);Password=$($UserPsw)"
} else {
    $ConnectionString = "Persist Security Info=False;Initial Catalog=$($InitialCatalog);Data Source=$($DataSource);Integrated Security=true"
}

Write-Output "Create new connection string value: $ConnectionString"
Write-Output "in config file: $ConfigFilePath"
Set-ConnectionString -ConfigPath "$ConfigFilePath" -ConnectionString "$ConnectionString"

exit $LASTEXITCODE