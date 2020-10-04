Param (
	[Parameter(Mandatory = $True)]
	[string]$ServerName,
	[Parameter(Mandatory = $True)]
	[string]$CatalogName,
	[Parameter(Mandatory = $False)]
	[string]$UserName,
	[Parameter(Mandatory = $False)]
	[string]$UserPsw
)

$exitCode = 0

try {
	# https://msdn.microsoft.com/en-us/library/microsoft.sqlserver.management.smo.database.drop.aspx
	[System.Reflection.Assembly]::LoadWithPartialName('Microsoft.SqlServer.SMO') | out-null 
	[System.Reflection.Assembly]::LoadWithPartialName('Microsoft.SqlServer.SmoExtended') | out-null 

	Write-Output "Initialize Drop Table on:"
	Write-Output "server: $ServerName"
	Write-Output "database: $CatalogName"

	Import-Module SQLServer -DisableNameChecking

	#Set variables 
	$dbServer = new-object ('Microsoft.SqlServer.Management.Smo.Server') $ServerName 

	if ($UserName) {
		Write-Output "username: $UserName"

		#This sets the connection to mixed-mode authentication
		$dbServer.ConnectionContext.LoginSecure = $false;

		#This sets the login name
		$dbServer.ConnectionContext.set_Login($UserName);
	
		#This sets the password
		$dbServer.ConnectionContext.set_Password($UserPsw)
	}

	$databases = $dbServer.Databases 
	$dbname = $CatalogName 
	$db = $databases[$dbname]

	if ($db) {
		Write-Verbose "$dbname exists!"
		$dbServer.KillAllProcesses("$dbname")
		#$dbServer.KillDatabase("$dbname")
		#$dbServer.KillProcess(52)
		$db.drop()
		Write-Verbose "Not anymore..."
	}
 else {
		Write-Verbose "$dbname doesn't exists!"
	}
}
catch {
	$exitCode = 1
}

exit $exitCode



