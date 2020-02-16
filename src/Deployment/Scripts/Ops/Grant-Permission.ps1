[CmdletBinding(SupportsShouldProcess=$True)]
Param(
[Parameter(Mandatory=$true)]
[string]$DataSource,
[Parameter(Mandatory=$true)]
[string]$Catalog,
[Parameter(Mandatory=$true)]
[string]$User 	
)

$DBrole = "'db_owner'" 	
$ARS = "exec sp_addrolemember @rolename = $DBRole, @membername = '$User'"
$exitcode = 0

function Import-Module-SQLPS {
    #pushd and popd to avoid import from changing the current directory (ref: http://stackoverflow.com/questions/12915299/sql-server-2012-sqlps-module-changing-current-location-automatically)
    #3>&1 puts warning stream to standard output stream (see https://connect.microsoft.com/PowerShell/feedback/details/297055/capture-warning-verbose-debug-and-host-output-via-alternate-streams)
    #out-null blocks that output, so we don't see the annoying warnings described here: https://www.codykonior.com/2015/05/30/whats-wrong-with-sqlps/
    push-location
    import-module sqlps 3>&1 | out-null
    pop-location
}

try {

    "Is SQLPS Loaded?"
    if(get-module sqlps){"yes"}else{"no"}
    
    Import-Module-SQLPS
    
    "Is SQLPS Loaded Now?"
    if(get-module sqlps){"yes"}else{"no"}
    
    #Grant Owner role
    Write-Verbose "ServerInstance: $DataSource"
    Write-Verbose "Database: $Catalog" 
    Write-Verbose "Rolename: $DBRole"
    Write-Verbose "Membername: $User"
    Invoke-Sqlcmd -ServerInstance "$DataSource" -Database "$Catalog" -Query "$ARS"
    
    $listOwnersQuery = "SELECT members.name as 'members_name', roles.name as 'roles_name',roles.type_desc as 'roles_desc',members.type_desc as 'members_desc' FROM sys.database_role_members rolemem INNER JOIN sys.database_principals roles ON rolemem.role_principal_id = roles.principal_id INNER JOIN sys.database_principals members ON rolemem.member_principal_id = members.principal_id where roles.name = 'db_owner' ORDER BY members.name"
    
    Invoke-Sqlcmd -ServerInstance "$DataSource" -Database "$Catalog" -Query "$listOwnersQuery"
} catch {
    $exitcode = 1
    Write-Output "Grant permission failed: $_"
}

exit $exitcode