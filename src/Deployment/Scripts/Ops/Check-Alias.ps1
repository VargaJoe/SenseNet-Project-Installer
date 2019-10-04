Param (
	[Parameter(Mandatory=$True)]
	[string]$Server
)

# https://docs.microsoft.com/en-us/powershell/module/sqlserver/backup-sqldatabase?view=sqlserver-ps

# This is not gonna work if sqlserver module is not installed, and by default is not installed :(

Import-Module sqlserver

write-host "has started..."
Get-SqlAgent -ServerInstance "$Server"
write-host "Done"
exit $LASTEXITCODE


