Param (
	[Parameter(Mandatory=$True)]
	[string]$ServerName,
	[Parameter(Mandatory=$True)]
	[string]$CatalogName,
	[Parameter(Mandatory=$False)]
	[string]$UserName,
	[Parameter(Mandatory=$False)]
	[string]$Password
)

$exitCode = 0

[System.Reflection.Assembly]::LoadWithPartialName('Microsoft.SqlServer.SMO') | out-null 
[System.Reflection.Assembly]::LoadWithPartialName('Microsoft.SqlServer.SmoExtended') | out-null 

Import-Module SQLServer -DisableNameChecking

#Set variables 
$dbServer = new-object ('Microsoft.SqlServer.Management.Smo.Server') $ServerName 

if ($UserName) {
	Write-Output "username: $UserName"

	#This sets the connection to mixed-mode authentication
	$dbServer.ConnectionContext.LoginSecure=$false;

	#This sets the login name
	$dbServer.ConnectionContext.set_Login($UserName);
	
	#This sets the password
	$dbServer.ConnectionContext.set_Password($Password)
}

$databases = $dbServer.Databases 
$dbname = $CatalogName 

Write-Verbose "server: $dbServer"
Write-Verbose "dbname: $dbname"

$db = $databases[$dbname]

if ($db) {
	Write-Verbose "$dbname already exists!"
} else {
	Write-Verbose "$dbname doesn't exists!"
	try {
		$db = New-Object Microsoft.SqlServer.Management.Smo.Database($dbServer, $dbname)
		$db.Create()
		Write-Verbose "$dbname has been created"
	} 
	catch {
		Write-Output "$_.Exception"
		$exitCode = 1
	}	
}

exit $exitCode


