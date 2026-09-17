#requires -Version 5.1
# Opt-in real SQL Server + Compose checks in a disposable local-only container.
[CmdletBinding()] param([switch]$RunDocker,[string]$SqlImage='mcr.microsoft.com/mssql/server:2022-latest')
$ErrorActionPreference='Stop'; Set-StrictMode -Version Latest
if (-not $RunDocker) { throw 'Specify -RunDocker to create a disposable SQL Server Developer test container (ACCEPT_EULA=Y). Requires the image already locally present.' }
$scriptsPath=Join-Path (Split-Path $PSScriptRoot -Parent) 'src/Deployment/Scripts'
Import-Module (Join-Path $scriptsPath 'Core/PlotManager.psm1') -Force
$id=[guid]::NewGuid().ToString('N'); $project='plot-test-'+$id
$root=Join-Path ([IO.Path]::GetTempPath()) $project; $null=[IO.Directory]::CreateDirectory($root)
$registry=$null; $started=$false; $passed=0
$password='Pl0t!'+[guid]::NewGuid().ToString('N')
$childEnvironment=@{PLOT_TEST_SQL_PASSWORD=$password;PLOT_TEST_SQL_IMAGE=$SqlImage}
$connection=''
function Invoke-IntegrationStep([string]$Step,[hashtable]$With) {
    $config=@{Plots=@{test=@(@{Id='test';Step=$Step;With=$With})}}
    $result=Invoke-Plot $registry $config test -WorkDirectory $root
    if ($result.Status -ne 'Succeeded') { throw ($Step+' failed: '+$result.Steps[0].Error) }
    $script:passed++; $result.Steps[0].Output
}
function Invoke-SqlTest([string]$Step,[hashtable]$With=@{}) {
    $With.ConnectionString=$connection; Invoke-IntegrationStep ('sqlserver.'+$Step) $With
}
function Invoke-ComposeTest([string]$Operation,[string[]]$Arguments=@()) {
    Invoke-IntegrationStep ('compose.'+$Operation) @{ProjectName=$project;Files=@('compose.yaml');Directory=$root;Environment=$childEnvironment;Arguments=$Arguments;TimeoutSeconds=180}
}
function Assert-Integration($Condition,[string]$Message) { if (-not $Condition) { throw $Message } }
try {
    $registry=New-PlotRegistry (Join-Path $scriptsPath 'Auto')
    # JSON is also valid YAML; no pulls, shared mounts, fixed names or public listeners.
    $compose=@{services=@{database=@{image='${PLOT_TEST_SQL_IMAGE}';pull_policy='never';environment=@{ACCEPT_EULA='Y';MSSQL_PID='Developer';MSSQL_SA_PASSWORD='${PLOT_TEST_SQL_PASSWORD}'};ports=@('127.0.0.1::1433')}}}
    [IO.File]::WriteAllText((Join-Path $root 'compose.yaml'),($compose | ConvertTo-Json -Depth 10))
    $null=Invoke-ComposeTest config @('--quiet')
    $started=$true; $null=Invoke-ComposeTest up
    $ps=Invoke-ComposeTest ps @('--format','json')
    $containers=@(ConvertFrom-Json $ps.StandardOutput)
    $publisher=@($containers[0].Publishers | Where-Object TargetPort -eq 1433)[0]
    Assert-Integration ($publisher.URL -eq '127.0.0.1') 'SQL test port must be loopback-only.'
    $connection='Server=127.0.0.1,'+$publisher.PublishedPort+';User ID=sa;Password='+$password+';Encrypt=False;Pooling=False'
    $null=Invoke-SqlTest wait @{TimeoutSeconds=120;ConnectTimeoutSeconds=2;CommandTimeoutSeconds=2}
    $null=Invoke-SqlTest create @{Database='PlotFixture'}
    $query=Invoke-SqlTest query @{Query='SELECT name FROM sys.databases WHERE name = @name;';Parameters=@{name='PlotFixture'}}
    Assert-Integration ($query.RowCount -eq 1 -and $query.ResultSets[0].Rows[0][0] -eq 'PlotFixture') 'Created database was not returned by parameterized query.'
    $null=Invoke-SqlTest execute @{Query='CREATE TABLE PlotFixture.dbo.Example (Id int NOT NULL, Label nvarchar(100) NULL);'}
    $null=Invoke-SqlTest execute @{Query='INSERT INTO PlotFixture.dbo.Example VALUES (@id,@label);';Parameters=@{id=1;label="O'Brien"}}
    $null=Invoke-SqlTest execute @{Query='INSERT INTO PlotFixture.dbo.Example VALUES (@id,@label);';Parameters=@{id=2;label=$null}}
    $rows=Invoke-SqlTest query @{Query='SELECT Id,Label FROM PlotFixture.dbo.Example ORDER BY Id; SELECT 42 AS Other;'}
    Assert-Integration ($rows.ResultSets.Count -eq 2 -and $rows.RowCount -eq 3) 'Multiple result sets or rows lost.'
    Assert-Integration ($rows.ResultSets[0].Rows[0][1] -eq "O'Brien" -and $null -eq $rows.ResultSets[0].Rows[1][1]) 'SQL scalar/null values changed.'
    $null=Invoke-SqlTest configure-file @{Database='PlotFixture';LogicalName='PlotFixture';SizeMb=16;MaxSizeMb=128;GrowthMb=8}
    $null=Invoke-SqlTest login @{Action='create';LoginName='plot-reader';Password=('Reader!9'+[guid]::NewGuid().ToString('N'))}
    $null=Invoke-SqlTest user @{Database='PlotFixture';Action='create';UserName='plot-reader';LoginName='plot-reader';Roles=@('db_datareader')}
    $null=Invoke-SqlTest user @{Database='PlotFixture';Action='drop';UserName='plot-reader'}
    $null=Invoke-SqlTest login @{Action='drop';LoginName='plot-reader'}
    $backup='/var/opt/mssql/data/plot-fixture.bak'
    $null=Invoke-SqlTest backup @{Database='PlotFixture';Path=$backup}
    $files=Invoke-SqlTest query @{Query="RESTORE FILELISTONLY FROM DISK=N'$backup';"}
    $moves=@{}
    foreach ($row in $files.ResultSets[0].Rows) { $suffix=if ($row[2] -eq 'L') { 'ldf' } else { 'mdf' }; $moves[[string]$row[0]]='/var/opt/mssql/data/plot-restored-'+$row[0]+'.'+$suffix }
    $null=Invoke-SqlTest restore @{Database='PlotRestored';Path=$backup;Moves=$moves}
    $restored=Invoke-SqlTest query @{Query='SELECT COUNT(*) FROM PlotRestored.dbo.Example;'}
    Assert-Integration ($restored.ResultSets[0].Rows[0][0] -eq 2) 'Restored database content differs.'
    $null=Invoke-SqlTest drop @{Database='PlotRestored'}; $null=Invoke-SqlTest drop @{Database='PlotFixture'}
    $null=Invoke-ComposeTest logs @('--tail','5')
    $null=Invoke-ComposeTest stop
    $null=Invoke-ComposeTest up
    Write-Output "PowerShell $($PSVersionTable.PSVersion): $passed real SQL/Compose steps passed."
} finally {
    try {
        if ($started -and $null -ne $registry) { $null=Invoke-ComposeTest down @('--volumes','--timeout','10') }
    } finally {
        if ($null -ne $registry) { Remove-PlotRegistry $registry }
        $resolved=[IO.Path]::GetFullPath($root); $temp=[IO.Path]::GetFullPath([IO.Path]::GetTempPath()).TrimEnd('\','/')+[IO.Path]::DirectorySeparatorChar
        if (-not $resolved.StartsWith($temp,[StringComparison]::OrdinalIgnoreCase) -or (Split-Path $resolved -Leaf) -ne $project) { throw 'Refusing unsafe integration cleanup.' }
        Remove-Item -LiteralPath $resolved -Recurse -Force
    }
}
