Param (
	[Parameter(Mandatory=$True)]
	[string]$ServerName,
	[Parameter(Mandatory=$True)]
	[string]$CatalogName,
	[Parameter(Mandatory=$True)]
	[string]$FileName
)

# https://docs.microsoft.com/en-us/powershell/module/sqlserver/backup-sqldatabase?view=sqlserver-ps
# Import-module sqlserver

[System.Reflection.Assembly]::LoadWithPartialName('Microsoft.SqlServer.SMO') | out-null 
[System.Reflection.Assembly]::LoadWithPartialName('Microsoft.SqlServer.SmoExtended') | out-null 

#Set variables 
$dbServer = new-object ('Microsoft.SqlServer.Management.Smo.Server') $ServerName 
$databases = $dbServer.Databases 

# Default backup directory
# $bkdir = $dbServer.Settings.BackupDirectory 

# Iterate through all databases and backup
# each user database 
$databases | foreach-object { 
  $db = $_ 
  if ($db.IsSystemObject -eq $False) {
    $dbname = $db.Name 
    $dt = get-date -format yyyyMMddHHmmss 
    $dbbk = new-object 
      ('Microsoft.SqlServer.Management.Smo.Backup')
    $dbbk.Action = 'Database' 
    $dbbk.BackupSetDescription = "FULL - " + $dbname
    $dbbk.BackupSetName = $dbname + " FULL Backup" 
    $dbbk.Database = $dbname 
    $dbbk.MediaDescription = "Disk"
    $dbbk.Devices.AddDevice($bkdir + "\"
      + $dbname + "_db_" + $dt + ".bak", 'File')
    $dbbk.SqlBackup($dbServer) 
    write-host "Backed up " $dbname " to " 
      $bkdir  "\"  $dbname  "_db_"  $dt ".bak"
    } 
  } 
write-host "Backup Operation(s) Complete"












write-host "Backuping database has started..."
Backup-SqlDatabase -ServerInstance "$ServerName" -Database "$CatalogName" -BackupFile "$FileName"
write-host "Done"
exit $LASTEXITCODE


