Param (
	[Parameter(Mandatory=$True)]
	[string]$Server,
	[Parameter(Mandatory=$True)]
	[string]$Catalog,
	[Parameter(Mandatory=$True)]
	[string]$FileName
)

# https://docs.microsoft.com/en-us/powershell/module/sqlserver/restore-sqldatabase?view=sqlserver-ps

Import-module sqlserver
write-host "Restoreing database has started..."
Restore-SqlDatabase -ServerInstance "$Server" -Database "$Catalog" -BackupFile "$FileName"
write-host "Done"
exit $LASTEXITCODE


