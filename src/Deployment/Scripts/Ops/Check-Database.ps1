param(
	[Parameter(Mandatory)]
	[string]$DataSource,
	[Parameter(Mandatory)]
	[string]$Catalog
)

$exitCode = -1
try {
	$connectionString = "Data Source=$($DataSource);Initial Catalog=$($Catalog);Integrated Security=True"
	Write-Output "Checking connection string $connectionString"
	$connection = New-Object System.Data.SqlClient.SqlConnection $ConnectionString
	$connection.Open()
	Write-Output "Database connection successfull"
	$exitCode = 0
} catch {
	Write-Output "Database connection failed. Check if available and if you use properly set alias."
	$exitCode = 1
} finally {
	$connection.Close()
}

Write-Output "$exitCode"
exit $exitCode