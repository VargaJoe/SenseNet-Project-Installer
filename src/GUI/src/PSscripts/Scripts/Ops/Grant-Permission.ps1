[CmdletBinding(SupportsShouldProcess=$True)]
Param(
[Parameter(Mandatory=$true)]
[string]$DataSource,
[Parameter(Mandatory=$true)]
[string]$Catalog,
[Parameter(Mandatory=$true)]
[string]$User 	
)

#$DataSource = "MySenseNetContentRepositoryDatasource"
#$Catalog = "RorWeb"
#$User = "SN\sndev11$"
$DBrole = "'db_owner'" 	

#Add role script
$ARS = "exec sp_addrolemember @rolename = $DBRole, @membername = '$User'"

function Import-Module-SQLPS {
    #pushd and popd to avoid import from changing the current directory (ref: http://stackoverflow.com/questions/12915299/sql-server-2012-sqlps-module-changing-current-location-automatically)
    #3>&1 puts warning stream to standard output stream (see https://connect.microsoft.com/PowerShell/feedback/details/297055/capture-warning-verbose-debug-and-host-output-via-alternate-streams)
    #out-null blocks that output, so we don't see the annoying warnings described here: https://www.codykonior.com/2015/05/30/whats-wrong-with-sqlps/
    push-location
    import-module sqlps 3>&1 | out-null
    pop-location
}

"Is SQLPS Loaded?"
if(get-module sqlps){"yes"}else{"no"}
 
Import-Module-SQLPS
 
"Is SQLPS Loaded Now?"
if(get-module sqlps){"yes"}else{"no"}

#Grant Owner role
#Invoke-Sqlcmd -ServerInstance $DataSource -Database $Catalog -Query $ARS

Write-Verbose "ServerInstance: $DataSource"
Write-Verbose "Database: $Catalog" 
Write-Verbose "Rolename: $DBRole"
Write-Verbose "Membername: $User"
Invoke-Sqlcmd -ServerInstance "$DataSource" -Database "$Catalog" -Query "$ARS"



#Invoke-Sqlcmd -ServerInstance MySenseNetContentRepositoryDatasource -Database RorWeb -Query $ARS