[CmdletBinding(SupportsShouldProcess=$True)]
Param(
[Parameter(Mandatory=$true)]
[string]$ConfigFilePath,
[Parameter(Mandatory=$true)]
[string]$DataSource,
[Parameter(Mandatory=$true)]
[string]$InitialCatalog
)

$LASTEXITCODE = 0


$ConnectionString = 'Persist Security Info=False;Initial Catalog='+$InitialCatalog+';Data Source='+$DataSource+';Integrated Security=true'
Write-Verbose "Create new connection string value: $ConnectionString"
Write-Verbose "in config file: $ConfigFilePath"
Set-ConnectionString -ConfigPath "$ConfigFilePath" -ConnectionString "$ConnectionString"

exit $LASTEXITCODE