Param (
	[Parameter(Mandatory=$True)]
	[string]$ServerName,
	[Parameter(Mandatory=$True)]
	[string]$CatalogName,
	[Parameter(Mandatory=$True)]
	[string]$FileName
)

$LASTEXITCODE = 0

# https://docs.microsoft.com/en-us/powershell/module/sqlserver/backup-sqldatabase?view=sqlserver-ps
# Import-module sqlserver

# https://redmondmag.com/articles/2009/12/14/automated-backups.aspx
[System.Reflection.Assembly]::LoadWithPartialName('Microsoft.SqlServer.SMO') | out-null 
[System.Reflection.Assembly]::LoadWithPartialName('Microsoft.SqlServer.SmoExtended') | out-null 

#Set variables 
$dbServer = new-object ('Microsoft.SqlServer.Management.Smo.Server') $ServerName 
$databases = $dbServer.Databases 

# Backup selected catalog on given path
$dbname = $CatalogName 

$dbbk = new-object ('Microsoft.SqlServer.Management.Smo.Backup')
$dbbk.Action = 'Database' 
$dbbk.BackupSetDescription = "FULL - " + $dbname
$dbbk.BackupSetName = $dbname + " FULL Backup" 
$dbbk.Database = $dbname 
$dbbk.MediaDescription = "Disk"
$dbbk.Devices.AddDevice($FileName, 'File')

Write-Verbose "Restoring $CatalogName database has started..."
$dbbk.SqlBackup($dbServer) 
Write-Verbose "Restore of $CatalogName to $FileName complete"

# write-host "Backuping database has started..."
# Backup-SqlDatabase -ServerInstance "$ServerName" -Database "$CatalogName" -BackupFile "$FileName"
# write-host "Done"

exit $LASTEXITCODE


