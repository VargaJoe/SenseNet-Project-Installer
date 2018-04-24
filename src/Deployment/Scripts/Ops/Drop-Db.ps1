Param (
	[Parameter(Mandatory=$True)]
	[string]$ServerName,
	[Parameter(Mandatory=$True)]
	[string]$CatalogName
)

$LASTEXITCODE = 0

# https://msdn.microsoft.com/en-us/library/microsoft.sqlserver.management.smo.database.drop.aspx
[System.Reflection.Assembly]::LoadWithPartialName('Microsoft.SqlServer.SMO') | out-null 
[System.Reflection.Assembly]::LoadWithPartialName('Microsoft.SqlServer.SmoExtended') | out-null 

#Set variables 
$dbServer = new-object ('Microsoft.SqlServer.Management.Smo.Server') $ServerName 
$databases = $dbServer.Databases 

$dbname = $CatalogName 

if ($dbServer.databases[$dbname]) {
	Write-Verbose "$dbname exists!"
	# $dbServer.KillAllProcesses("$dbname")
	# $dbServer.KillDatabase("$dbname")
	# $dbServer.KillProcess(52)
	$dbServer.databases[$dbname].drop()
	Write-Verbose "Not anymore..."
} else {
	Write-Verbose "$dbname doesn't exists!"
}

exit $LASTEXITCODE


