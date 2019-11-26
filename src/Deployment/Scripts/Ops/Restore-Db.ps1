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

if (!(Test-Path $FileName)) {	
	Write-Verbose "Backup file does not exists, stop process"
	$exitCode = 2
} else {
	# https://docs.microsoft.com/en-us/powershell/module/sqlserver/restore-sqldatabase?view=sqlserver-ps
	# Import-module sqlserver

	try{
		# https://redmondmag.com/articles/2009/12/21/automated-restores.aspx
		# Load dlls instead of module, so we don't have to install the module
		[System.Reflection.Assembly]::LoadWithPartialName('Microsoft.SqlServer.SMO') | out-null 
		[System.Reflection.Assembly]::LoadWithPartialName('Microsoft.SqlServer.SmoExtended') | out-null

		# Required instances for restore metas
		$dbServer = new-object("Microsoft.SqlServer.Management.Smo.Server") $ServerName 
		$dbRestore = new-object("Microsoft.SqlServer.Management.Smo.Restore")

		#settings for the restore 
		$dbRestore.Action = "Database" 
		$dbRestore.NoRecovery = $false; 
		$dbRestore.ReplaceDatabase = $true; 
		$dbRestorePercentCompleteNotification = 5; 
		$dbRestore.Devices.AddDevice("$FileName", [Microsoft.SqlServer.Management.Smo.DeviceType]::File)

		#get the db name 
		$dbRestoreDetails = $dbRestore.ReadBackupHeader($dbServer)

		#print database name 
		# Write-Verbose "Original Database Name from Backup File : "+$dbRestoreDetails.Rows[0]["DatabaseName"] 
		 
		# If we would like to restore with the original name we could use 
		# $dbRestore.Database = $dbRestoreDetails.Rows[0]["DatabaseName"]

		# But we rather want to restore with a given name (that can be the same as in the backup of course)
		$dbRestore.Database = $CatalogName

		# Instances for renaming the db
		$dbRestoreFile = new-object("Microsoft.SqlServer.Management.Smo.RelocateFile") 
		$dbRestoreLog = new-object("Microsoft.SqlServer.Management.Smo.RelocateFile")

		$masterDbPath = $dbServer.Information.MasterDBPath
		Write-Verbose "DB save path: $masterDbPath"

		# Set file names on the default database directory path
		$dbRestoreFile.LogicalFileName = $dbRestoreDetails.Rows[0]["DatabaseName"]
		$dbRestoreFile.PhysicalFileName = $dbServer.Information.MasterDBPath + "\" + $dbRestore.Database + ".mdf" 
		$dbRestoreLog.LogicalFileName = $dbRestoreDetails.Rows[0]["DatabaseName"] + "_log" 
		$dbRestoreLog.PhysicalFileName = $dbServer.Information.MasterDBLogPath + "\" + $dbRestore.Database + "_log.ldf" 
		$dbRestore.RelocateFiles.Add($dbRestoreFile) 
		$dbRestore.RelocateFiles.Add($dbRestoreLog)

		# And after all the settings done finally restore the db 
		Write-Verbose "Restoring $CatalogName database has started..."
		$dbRestore.SqlRestore($dbServer) 
		Write-Verbose "Restore of $CatalogName complete"
		$exitCode = 0
	}
	catch {
		Write-Verbose "Db restore failed: $($_.Exception.Message)" 
		$exitCode = 1	
	}
}
# restore by module but without renaming
# Write-Verbose "Restoring $CatalogName database has started..."
# Restore-SqlDatabase -ServerInstance "$ServerName" -Database "$CatalogName" -BackupFile "$FileName"
# Write-Verbose "Restore of $CatalogName Complete"

exit $exitCode