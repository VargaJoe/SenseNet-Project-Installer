# SQL Server, IIS, web maintenance and Compose

The native runtime now exposes **14 packages / 49 steps**. These packages implement generic platform operations with explicit settings; they contain no application-specific chart, server list, credentials or database schema. Each step also works independently through `Run.ps1 -Step <id> -Params '{"single":{...}}'`.

## SQL Server (`sqlserver`)

Requires `System.Data.SqlClient` in the PowerShell host (verified on Windows PowerShell 5.1 and PowerShell 7). It does not require SMO, the SqlServer PowerShell module or sqlcmd. This package targets SQL Server, not every SQL dialect or Azure SQL Database's restricted DDL/backup surface.

All steps require a secret `ConnectionString`. Use an environment reference rather than committing credentials. Integrated authentication and SQL authentication follow that connection string. Encryption and certificate validation are also connection-string settings. `ConnectTimeoutSeconds` defaults to 15 and `CommandTimeoutSeconds` to 60; neither permits an infinite timeout.

| Step | Settings besides connection/timeouts | Behavior |
| --- | --- | --- |
| `sqlserver.query` | Query, Parameters={}, MaxRows=10000 | Executes one T-SQL batch, returns every result set as Columns and Rows arrays, plus total RowCount. Duplicate column names and SQL NULL survive. |
| `sqlserver.execute` | Query **or** Path, Parameters={} | Executes one T-SQL batch or local UTF-8 script; returns AffectedRows (DDL may return -1). |
| `sqlserver.wait` | TimeoutSeconds=60, IntervalMilliseconds=1000 | Retries authenticated `SELECT 1` against the configured database. |
| `sqlserver.create` | Database, RecoveryModel=SIMPLE | Creates a new database; existing names fail. FULL and BULK_LOGGED are also accepted. |
| `sqlserver.drop` | Database | Drops the named user database; does not force disconnection of other sessions. |
| `sqlserver.backup` | Database, Path, CopyOnly=true, Initialize=false | CHECKSUM backup to a SQL-server-side file. Appends a backup set unless Initialize explicitly requests media overwrite. |
| `sqlserver.restore` | Database, Path, Moves, Replace=false, BackupSet=1 | CHECKSUM restore with explicit logical-name to server-path mappings. Replacement is opt-in. |
| `sqlserver.configure-file` | Database, LogicalName, SizeMb, MaxSizeMb, GrowthMb=64 | Sets an explicitly named file's size, maximum and growth in MB. Does not shrink it or discover all files implicitly. |
| `sqlserver.login` | Action=create/drop, LoginName, Password for create | Creates a SQL-authenticated login with password policy enabled, or drops it. Built-in sa is excluded. |
| `sqlserver.user` | Database, Action=create/drop, UserName, LoginName for create, Roles=[] | Maps a database user to an existing login and grants only the named roles; user/role creation is transactional. |

Parameters are scalar ADO.NET command parameters, named with or without `@`. Identifiers and server-side paths in generated administrative statements are escaped separately. Query text is trusted operator input and can mutate a database even in `query`; it is not a read-only SQL sandbox. SQLCMD `GO`, `:r`, and variable substitutions are not supported: split scripts into sequential `sqlserver.execute` invocations. Downloaded scripts compose `http.download` (optionally with SHA256) and `sqlserver.execute`.

Provider errors omit connection strings, SQL and raw provider messages. Use SQL Server diagnostics for details. Successful query results may contain sensitive data, so choose queries and output destinations deliberately. Row limits bound row count, not total result bytes. The readiness deadline has up to two seconds of provider timeout rounding; command timeout is the provider's execution/read timeout, not a transaction rollback guarantee.

Backup/restore paths belong to the **SQL Server machine/container**, not WorkDirectory. Use `RESTORE FILELISTONLY` through query to obtain every logical name; do not assume the name equals the database name. [Microsoft RESTORE reference](https://learn.microsoft.com/en-us/sql/t-sql/statements/restore-statements-transact-sql) describes MOVE/CHECKSUM/REPLACE. System databases are excluded from generated database-management steps. Explicit `query`/`execute` remain general-purpose.

`create` includes recovery-model configuration; provider failure after creation can leave the database present. There is no automatic drop/rollback of a partially completed administration operation. SQL users and server logins are separate operations; no implicit db_owner or server-wide permissions are granted.

See [database.json](../src/Deployment/Scripts/Examples/platform/database.json). Supply `PLOT_SQL_CONNECTION` through your local secret mechanism and override Values with actual database names and server paths. The example includes readiness, creation, backup, restore into a separate database, and query-to-JSON export. For multiple databases, use one explicitly named backup invocation per database; there is no implicit server-wide discovery or bulk deletion.

## IIS and web maintenance

IIS steps require Windows, IIS/WebAdministration and appropriate local permissions. Use Windows PowerShell 5.1 on the IIS host when WebAdministration is unavailable in your PowerShell 7 host. Native runtime/package tests cover both shells; WebAdministration availability is a separate platform prerequisite.

- `iis.create`: WebsiteName, AppPoolName, existing PhysicalPath; Port=80, IPAddress=*, HostHeader='', RuntimeVersion='' (no managed runtime; v2.0/v4.0 also supported), PipelineMode=Integrated (or Classic). Creates a dedicated application pool and HTTP site. Existing site/pool or identical binding fails. It does not change unrelated pools, install IIS, configure TLS certificates or grant filesystem ACLs. New-Website applies IIS's normal startup behavior. If provisioning fails after pool creation, inspect and remove that new pool before retrying; no broad rollback runs.
- `iis.status`: WebsiteName. Returns site state, pool name/state and physical path; missing sites fail.
- `iis.recycle`: AppPoolName, TimeoutSeconds=30, PollMilliseconds=200. Requests a recycle and waits for pool Started. This is not proof that an application has warmed up; follow it with `http.wait` on an application health endpoint.
- `iis.start` / `iis.stop` retain their existing bounded site/pool lifecycle behavior.
- `web.offline`: existing Directory, Content='Maintenance in progress.'. Creates `app_offline.htm` without overwriting an existing maintenance page.
- `web.online`: Directory. Removes that exact maintenance page; an absent page is already online.

The web package only manages the ASP.NET maintenance-file convention. The application host must honor it. It neither stops arbitrary web servers nor grants access rights. `web.online` removes the page in the explicitly selected directory regardless of who originally created it.

[iis.json](../src/Deployment/Scripts/Examples/platform/iis.json) contains create, deploy, status, recycle and recover-online plots. Deploy places the app offline, copies a prepared artifact, brings it online and checks HTTP readiness. **Copy failure stops the plot and intentionally leaves maintenance enabled.** Inspect the partial deployment, restore/correct files and then run recover-online. Artifact content must exclude `app_offline.htm`; directory copy merges files and does not remove stale destination files. Use a separate scoped removal or versioned deployment directory where required. XML configuration edits remain available through `xml.set`.

## Docker Compose (`compose`)

Steps: `compose.config`, `pull`, `build`, `up`, `ps`, `logs`, `stop`, `down`. Declares a dependency on `process`. Requires Docker CLI with Compose support and access to the intended Docker context.

Every step requires `ProjectName` and a nonempty ordered `Files` list. Optional settings: Directory='.', EnvFiles=[], Profiles=[], Services=[], Arguments=[], Environment={}, TimeoutSeconds=300. Relative file/env-file paths resolve against Directory, which resolves against WorkDirectory. File order is preserved. Files must exist; project names use lowercase Compose naming rules. Environment values are passed only to the child process.

`up` includes `--detach`; pass `Arguments: ["--wait", "--wait-timeout", "30"]` for running/healthy readiness, as described in [Docker's up reference](https://docs.docker.com/reference/cli/docker/compose/up/). `down` does not add volume deletion or orphan removal. Additional native Arguments are trusted operator choices and may request destructive behavior. The adapter always supplies explicit project/file/directory flags; do not override that scope with extra global options. No daemon-wide prune runs.

Outputs follow process.run (ExitCode, StandardOutput, StandardError). `compose.config` output can contain interpolated secrets; use `--quiet` for validation only. Timeout terminates the client; daemon-side changes already accepted can continue. `logs --follow` is bounded by the same client timeout.

[compose.json](../src/Deployment/Scripts/Examples/platform/compose.json) and [compose.yaml](../src/Deployment/Scripts/Examples/platform/compose.yaml) provide validate/up/status/down plots. Run with WorkDirectory set to their platform example directory. The example binds localhost:18080 and uses a generic nginx image; it requires an available/free port and may pull the image.

## General workflow equivalents

| Older capability | Native composition |
| --- | --- |
| Database connectivity / credential check / wait | sqlserver.wait (authenticated database operation, not a TCP-only check) |
| SQL query export / downloaded SQL execution | sqlserver.query -> json.write; http.download -> sqlserver.execute |
| Empty DB / file sizes / users / backup / restore / drop | Dedicated sqlserver steps above |
| Automatic dated or multi-database backups | Explicit plot invocation IDs and caller-supplied paths; schedule the plot through the operator's scheduler |
| IIS site creation / lifecycle / check / warmup | iis.create/start/stop/status/recycle -> http.wait |
| App offline / copy deployment / app online | web.offline -> filesystem.copy-tree -> web.online -> http.wait |
| Build / publish / package / download artifacts | Existing build, archive, filesystem and http packages |
| Connection/config edits | json.merge, json.write and xml.set with application-owned keys/values |
| Multi-container local lifecycle | compose config/up/ps/logs/stop/down |
| GUI catalog / plot execution | Structured local protocol and Windows host in [local integration](local-integration.md) |

This is capability migration, not binary compatibility with every historical step name or a promise that every historical scenario runs unchanged. External schedulers, remote Windows access, host-file/firewall/ACL administration and application-specific install/index/import/export still require explicitly configured tools or their own adapters; process.run can launch those tools, but does not supply their domain semantics. The retained legacy runner remains separate. No company configurations or application-specific Helm charts are included.
