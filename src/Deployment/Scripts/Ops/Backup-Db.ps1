Param (
	[Parameter(Mandatory=$True)]
	[string]$ServerName,
	[Parameter(Mandatory=$True)]
	[string]$CatalogName,
	[Parameter(Mandatory=$True)]
	[string]$FileName
)

$exitCode = -1

# Technical Debt: FileName is file path actually, it should be fixed
$backupFileName = $FileName | split-path -leaf
$backupFileParentPath = $FileName | split-path -parent

Write-Verbose "Server name: $($ServerName)"
Write-Verbose "Catalog name: $($CatalogName)"
Write-Verbose "Backup path: $($FileName)"

if (!(Test-Path $backupFileParentPath)) {	
	$backupFileParentName = $backupFileParentPath | split-path -leaf
	$backupFileParentsParentPath = $backupFileParentPath | split-path -parent	
	Write-Verbose "Backup folder does not exists, let's create it"
	Write-Verbose "`twith name: $backupFileParentName"
	Write-Verbose "`tunder: $backupFileParentsParentPath"
	New-Item -Path "$backupFileParentsParentPath" -Name "$backupFileParentName" -ItemType "directory"
}

# https://docs.microsoft.com/en-us/powershell/module/sqlserver/backup-sqldatabase?view=sqlserver-ps
# Import-module sqlserver

try {
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

	Write-Verbose "Backuping $CatalogName database has started..."
	$dbbk.SqlBackup($dbServer) 
	Write-Verbose "Backup of $CatalogName to $FileName complete"
	$exitCode = 0
}
catch {
	Write-Verbose "Db backup failed: $($_.Exception.Message)" 
 	$exitCode = 1	
}

# backup by module 
# write-host "Backuping database has started..."
# Backup-SqlDatabase -ServerInstance "$ServerName" -Database "$CatalogName" -BackupFile "$FileName"
# write-host "Done"

exit $exitCode


