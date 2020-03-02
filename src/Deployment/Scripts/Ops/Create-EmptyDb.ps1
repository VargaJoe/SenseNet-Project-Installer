Param (
	[Parameter(Mandatory=$True)]
	[string]$ServerName,
	[Parameter(Mandatory=$True)]
	[string]$CatalogName
)

$LASTEXITCODE = 0

[System.Reflection.Assembly]::LoadWithPartialName('Microsoft.SqlServer.SMO') | out-null 
[System.Reflection.Assembly]::LoadWithPartialName('Microsoft.SqlServer.SmoExtended') | out-null 

#Set variables 
$dbServer = new-object ('Microsoft.SqlServer.Management.Smo.Server') $ServerName 
$databases = $dbServer.Databases 

$dbname = $CatalogName 

if ($databases[$dbname]) {
	Write-Verbose "$dbname already exists!"
} else {
	Write-Verbose "$dbname doesn't exists!"
	$db = New-Object Microsoft.SqlServer.Management.Smo.Database($dbServer, $dbname)
	$db.Create()
	Write-Verbose "$dbname has been created on $db.CreateDate"
}

exit $LASTEXITCODE


