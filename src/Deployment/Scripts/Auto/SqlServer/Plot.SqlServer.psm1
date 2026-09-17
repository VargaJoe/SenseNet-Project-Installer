#requires -Version 5.1
Set-StrictMode -Version Latest
function Quote-SqlIdentifier([string]$Value) {
    if ([string]::IsNullOrWhiteSpace($Value) -or $Value.Length -gt 128 -or $Value.Contains([char]0)) { throw 'SQL identifier must contain 1-128 non-NUL characters.' }
    '['+$Value.Replace(']',']]')+']'
}
function Quote-SqlLiteral([string]$Value) {
    if ([string]::IsNullOrWhiteSpace($Value) -or $Value.Contains([char]0)) { throw 'SQL value must not be blank or contain NUL.' }
    "N'"+$Value.Replace("'","''")+"'"
}
function Get-SqlDatabase($Settings) {
    if ($Settings.Database -in @('master','model','msdb','tempdb')) { throw 'This operation requires a user database.' }
    Quote-SqlIdentifier $Settings.Database
}
# Provider seam for tests. Never include connection strings, SQL or provider error text in exceptions.
function Invoke-SqlCommand($Settings,[string]$Text,[hashtable]$Parameters=@{},[string]$Database='', [switch]$ReadRows, [int]$MaxRows=10000) {
    $connection=$null; $command=$null; $reader=$null
    try {
        $builder=New-Object System.Data.SqlClient.SqlConnectionStringBuilder
        # CLR accessors bypass PowerShell dictionary adaptation of DbConnectionStringBuilder.
        $builder.set_ConnectionString($Settings.ConnectionString)
        $builder.set_ConnectTimeout($Settings.ConnectTimeoutSeconds)
        if ($Database) { $builder.set_InitialCatalog($Database) }
        $connection=New-Object System.Data.SqlClient.SqlConnection ($builder.get_ConnectionString())
        $command=$connection.CreateCommand(); $command.CommandText=$Text; $command.CommandTimeout=$Settings.CommandTimeoutSeconds
        foreach ($key in $Parameters.Keys) {
            if ($key -notmatch '^@?[A-Za-z_][A-Za-z0-9_]*$') { throw 'Invalid SQL parameter name.' }
            $value=$Parameters[$key]
            if ($null -eq $value) { $value=[DBNull]::Value }
            if ($value -is [System.Collections.IDictionary] -or $value -is [array]) { throw 'SQL parameters must be scalar values.' }
            $null=$command.Parameters.AddWithValue(('@'+$key.TrimStart('@')),$value)
        }
        $connection.Open()
        if (-not $ReadRows) { return [pscustomobject]@{AffectedRows=$command.ExecuteNonQuery()} }
        $reader=$command.ExecuteReader(); $sets=New-Object System.Collections.ArrayList; $total=0
        do {
            if ($reader.FieldCount -eq 0) { continue }
            $columns=@(for ($i=0;$i -lt $reader.FieldCount;$i++) { $reader.GetName($i) })
            $rows=New-Object System.Collections.ArrayList
            while ($reader.Read()) {
                $total++; if ($total -gt $MaxRows) { throw 'SQL row limit exceeded.' }
                $values=New-Object object[] $reader.FieldCount
                $null=$reader.GetValues($values)
                for ($i=0;$i -lt $values.Count;$i++) { if ($values[$i] -is [DBNull]) { $values[$i]=$null } }
                $null=$rows.Add($values)
            }
            $null=$sets.Add([pscustomobject]@{Columns=$columns;Rows=@($rows.ToArray())})
        } while ($reader.NextResult())
        [pscustomobject]@{ResultSets=@($sets.ToArray());RowCount=$total}
    } catch { throw 'SQL operation failed. Check provider availability, authentication, permissions, SQL, row limit and timeout.' }
    finally { if ($null -ne $reader) { $reader.Dispose() }; if ($null -ne $command) { $command.Dispose() }; if ($null -ne $connection) { $connection.Dispose() } }
}
function Assert-SqlBatch([string]$Query) {
    if ([string]::IsNullOrWhiteSpace($Query)) { throw 'A nonempty SQL batch is required.' }
    if ($Query -match '(?im)^\s*(GO(?:\s|$)|:[a-z])' -or $Query -match '\$\([A-Za-z_][A-Za-z0-9_]*\)') { throw 'SQLCMD directives, GO separators and SQLCMD variables are unsupported. Supply separate T-SQL batches.' }
}
function Invoke-PlotSqlQuery {
    [CmdletBinding(SupportsShouldProcess)] param([hashtable]$Settings,$Context)
    Assert-SqlBatch $Settings.Query
    if ($PSCmdlet.ShouldProcess('configured database','Execute SQL query')) { Invoke-SqlCommand $Settings $Settings.Query $Settings.Parameters -ReadRows -MaxRows $Settings.MaxRows }
}
function Invoke-PlotSqlExecute {
    [CmdletBinding(SupportsShouldProcess)] param([hashtable]$Settings,$Context)
    if ([bool]$Settings.Query -eq [bool]$Settings.Path) { throw 'Supply exactly one of Query or Path.' }
    $query=$Settings.Query
    if ($Settings.Path) {
        $path=$Settings.Path; if (-not [IO.Path]::IsPathRooted($path)) { $path=Join-Path $Context.WorkDirectory $path }
        $query=[IO.File]::ReadAllText($path)
    }
    Assert-SqlBatch $query
    if ($PSCmdlet.ShouldProcess('configured database','Execute SQL batch')) { Invoke-SqlCommand $Settings $query $Settings.Parameters }
}
function Invoke-PlotSqlBackup {
    [CmdletBinding(SupportsShouldProcess)] param([hashtable]$Settings,$Context)
    $db=Get-SqlDatabase $Settings; $path=Quote-SqlLiteral $Settings.Path
    $options=@('CHECKSUM'); if ($Settings.CopyOnly) { $options+='COPY_ONLY' }; if ($Settings.Initialize) { $options+='INIT' }
    if ($PSCmdlet.ShouldProcess($Settings.Database,'Back up SQL database')) { Invoke-SqlCommand $Settings ("BACKUP DATABASE $db TO DISK = $path WITH "+($options -join ', ')) -Database master }
}
function Invoke-PlotSqlRestore {
    [CmdletBinding(SupportsShouldProcess)] param([hashtable]$Settings,$Context)
    $db=Get-SqlDatabase $Settings; $path=Quote-SqlLiteral $Settings.Path
    if ($Settings.Moves.Count -eq 0) { throw 'Moves must map backup logical file names to server-side paths.' }
    $options=@('CHECKSUM',('FILE = '+[int]$Settings.BackupSet))
    foreach ($name in ($Settings.Moves.Keys | Sort-Object)) {
        if ($Settings.Moves[$name] -isnot [string]) { throw 'Moves values must be server-side path strings.' }
        $options+=('MOVE '+(Quote-SqlLiteral $name)+' TO '+(Quote-SqlLiteral $Settings.Moves[$name]))
    }
    if ($Settings.Replace) { $options+='REPLACE' }
    if ($PSCmdlet.ShouldProcess($Settings.Database,'Restore SQL database')) { Invoke-SqlCommand $Settings ("RESTORE DATABASE $db FROM DISK = $path WITH "+($options -join ', ')) -Database master }
}
function Invoke-PlotSqlCreate {
    [CmdletBinding(SupportsShouldProcess)] param([hashtable]$Settings,$Context)
    $db=Get-SqlDatabase $Settings
    if ($Settings.RecoveryModel -notin @('SIMPLE','FULL','BULK_LOGGED')) { throw 'Invalid recovery model.' }
    if ($PSCmdlet.ShouldProcess($Settings.Database,'Create SQL database')) {
        Invoke-SqlCommand $Settings ("CREATE DATABASE $db; ALTER DATABASE $db SET RECOVERY "+$Settings.RecoveryModel+';') -Database master
    }
}
function Invoke-PlotSqlDrop {
    [CmdletBinding(SupportsShouldProcess)] param([hashtable]$Settings,$Context)
    $db=Get-SqlDatabase $Settings
    if ($PSCmdlet.ShouldProcess($Settings.Database,'Drop SQL database')) { Invoke-SqlCommand $Settings "DROP DATABASE $db;" -Database master }
}
function Invoke-PlotSqlConfigureFile {
    [CmdletBinding(SupportsShouldProcess)] param([hashtable]$Settings,$Context)
    $db=Get-SqlDatabase $Settings; $name=Quote-SqlLiteral $Settings.LogicalName
    if ($Settings.MaxSizeMb -lt $Settings.SizeMb) { throw 'MaxSizeMb must be at least SizeMb.' }
    $query="ALTER DATABASE $db MODIFY FILE (NAME = $name, SIZE = $([int]$Settings.SizeMb)MB, MAXSIZE = $([int]$Settings.MaxSizeMb)MB, FILEGROWTH = $([int]$Settings.GrowthMb)MB);"
    if ($PSCmdlet.ShouldProcess($Settings.Database,'Configure SQL file size and growth')) { Invoke-SqlCommand $Settings $query -Database master }
}
function Invoke-PlotSqlUser {
    [CmdletBinding(SupportsShouldProcess)] param([hashtable]$Settings,$Context)
    $null=Get-SqlDatabase $Settings; $user=Quote-SqlIdentifier $Settings.UserName
    if ($Settings.Action -eq 'create') {
        $login=Quote-SqlIdentifier $Settings.LoginName; $query="CREATE USER $user FOR LOGIN $login;"
        foreach ($role in $Settings.Roles) { if ($role -isnot [string]) { throw 'Roles must be strings.' }; $query+=' ALTER ROLE '+(Quote-SqlIdentifier $role)+" ADD MEMBER $user;" }
        $query="SET XACT_ABORT ON; BEGIN TRANSACTION; $query COMMIT;"
    } elseif ($Settings.Action -eq 'drop') { $query="DROP USER $user;" } else { throw 'Invalid user action.' }
    if ($PSCmdlet.ShouldProcess($Settings.Database,'Change SQL database user')) { Invoke-SqlCommand $Settings $query -Database $Settings.Database }
}
function Invoke-PlotSqlLogin {
    [CmdletBinding(SupportsShouldProcess)] param([hashtable]$Settings,$Context)
    $login=Quote-SqlIdentifier $Settings.LoginName
    if ($Settings.LoginName -eq 'sa') { throw 'The built-in sa login is not managed by this step.' }
    if ($Settings.Action -eq 'create') { $query="CREATE LOGIN $login WITH PASSWORD = "+(Quote-SqlLiteral $Settings.Password)+', CHECK_POLICY = ON;' }
    elseif ($Settings.Action -eq 'drop') { $query="DROP LOGIN $login;" } else { throw 'Invalid login action.' }
    if ($PSCmdlet.ShouldProcess('configured server','Change SQL login')) { Invoke-SqlCommand $Settings $query -Database master }
}
function Invoke-PlotSqlWait {
    [CmdletBinding(SupportsShouldProcess)] param([hashtable]$Settings,$Context)
    if (-not $PSCmdlet.ShouldProcess('configured database','Wait for authenticated SQL readiness')) { return }
    $timer=[Diagnostics.Stopwatch]::StartNew()
    do {
        $remaining=$Settings.TimeoutSeconds-$timer.Elapsed.TotalSeconds
        if ($remaining -le 0) { throw 'SQL readiness timeout.' }
        $attempt=@{}; foreach ($key in $Settings.Keys) { $attempt[$key]=$Settings[$key] }
        # Connection and query each receive half the remaining budget, with a one-second provider floor.
        $budget=[Math]::Max(1,[Math]::Floor($remaining/2))
        $attempt.ConnectTimeoutSeconds=[int][Math]::Min($Settings.ConnectTimeoutSeconds,$budget)
        $attempt.CommandTimeoutSeconds=[int][Math]::Min($Settings.CommandTimeoutSeconds,$budget)
        try { $null=Invoke-SqlCommand $attempt 'SELECT 1;' -ReadRows -MaxRows 1; return [pscustomobject]@{Ready=$true} } catch { }
        $remaining=$Settings.TimeoutSeconds-$timer.Elapsed.TotalSeconds
        if ($remaining -gt 0) { Start-Sleep -Milliseconds ([int][Math]::Min($Settings.IntervalMilliseconds,$remaining*1000)) }
    } while ($true)
}
Export-ModuleMember -Function Invoke-PlotSql*
