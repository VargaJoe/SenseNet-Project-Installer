#requires -Version 7.2
<#
.SYNOPSIS
Checks the portable SenseNet example; Docker lifecycle acceptance is explicitly opt-in.
.DESCRIPTION
Without -RunDocker, validates every native plot and proves that the unaccepted SQL
license stops prepare before runtime files or Docker side effects. -RunDocker accepts
the SQL Server Developer license for this disposable development/test fixture only.
It creates a unique loopback-only stack, verifies real content, tests both volume
backups against changed data, and removes only the fixture's checked Docker resources.
#>
[CmdletBinding()]
param([switch]$RunDocker)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest
$RepoRoot = [IO.Path]::GetFullPath((Split-Path $PSScriptRoot -Parent))
$ScriptsRoot = Join-Path $RepoRoot 'src/Deployment/Scripts'
$ExampleRoot = Join-Path $RepoRoot 'examples/sensenet-docker'
$FixturesRoot = Join-Path $RepoRoot 'artifacts/sensenet-example-tests'
$FixtureId = [guid]::NewGuid().ToString('N')
$FixtureRoot = [IO.Path]::GetFullPath((Join-Path $FixturesRoot $FixtureId))
$StackName = 'pm-sensenet-test-' + $FixtureId.Substring(0, 12)
$PathComparison = if ($IsWindows) { [StringComparison]::OrdinalIgnoreCase } else { [StringComparison]::Ordinal }
$identityPath = if ($IsWindows) { $FixtureRoot.ToLowerInvariant() } else { $FixtureRoot }
$DirectoryHash = [Convert]::ToHexString([Security.Cryptography.SHA256]::HashData([Text.Encoding]::UTF8.GetBytes($identityPath)))
$Pwsh = (Get-Process -Id $PID).Path
$Registry = $null
$Checks = [Collections.Generic.List[object]]::new()
$CleanupRequired = $false
$CleanupSucceeded = $false
$Failure = $null
$Evidence = [ordered]@{
    FormatVersion = 1; CreatedUtc = [DateTime]::UtcNow.ToString('o'); RunDocker = [bool]$RunDocker
    Fixture = $FixtureRoot; StackName = $StackName; Checks = $Checks
    CleanupSucceeded = $false; PrivateFilesRemoved = $false; Failure = $null
}

function Assert-Test([bool]$Condition, [string]$Message) {
    if (-not $Condition) { throw $Message }
}

function Add-Check([string]$Name, $Details = $null) {
    $Checks.Add([ordered]@{ Name = $Name; Status = 'Passed'; Details = $Details })
}

function Invoke-CheckedProcess([string]$Executable, [string[]]$Arguments, [string]$Label,
    [int]$TimeoutSeconds = 1200, [switch]$AllowFailure) {
    $start = [Diagnostics.ProcessStartInfo]::new($Executable)
    $start.UseShellExecute = $false; $start.CreateNoWindow = $true
    $start.WorkingDirectory = $FixtureRoot
    $start.RedirectStandardInput = $true; $start.RedirectStandardOutput = $true; $start.RedirectStandardError = $true
    foreach ($argument in $Arguments) { $start.ArgumentList.Add($argument) }
    $process = [Diagnostics.Process]::new(); $process.StartInfo = $start
    $started = $false
    try {
        $started = $process.Start()
        if (-not $started) { throw "$Label could not start." }
        $process.StandardInput.Close()
        $stdout = $process.StandardOutput.ReadToEndAsync(); $stderr = $process.StandardError.ReadToEndAsync()
        if (-not $process.WaitForExit($TimeoutSeconds * 1000)) {
            $process.Kill($true); $process.WaitForExit()
            throw "$Label exceeded its timeout."
        }
        $tasks = [Threading.Tasks.Task[]]@($stdout, $stderr)
        if (-not [Threading.Tasks.Task]::WaitAll($tasks, 10000)) { throw "$Label left an output pipe open." }
        if (-not $AllowFailure -and $process.ExitCode -ne 0) { throw "$Label failed (exit $($process.ExitCode)); raw output was withheld." }
        # Raw output stays in memory; Docker configuration, tokens and credentials
        # must never be dumped into this test's console or durable evidence.
        return [pscustomobject]@{ ExitCode = $process.ExitCode; Stdout = $stdout.Result; Stderr = $stderr.Result }
    } finally {
        if ($started -and -not $process.HasExited) { $process.Kill($true) }
        $process.Dispose()
    }
}

function Invoke-Docker([string[]]$Arguments, [string]$Label) {
    (Invoke-CheckedProcess 'docker' $Arguments $Label).Stdout.Trim()
}

function Get-FreePort {
    $listener = [Net.Sockets.TcpListener]::new([Net.IPAddress]::Loopback, 0)
    try { $listener.Start(); return $listener.LocalEndpoint.Port } finally { $listener.Stop() }
}

function Write-ProjectSettings([bool]$AcceptLicense, [string]$Backup = '', [string]$Confirmation = '') {
    $settings = [ordered]@{
        SenseNet = [ordered]@{ StackName = $StackName; ApiPort = $script:ApiPort; IdentityPort = $script:IdentityPort; AcceptSqlLicense = $AcceptLicense }
        Restore = [ordered]@{ BackupPath = $Backup; ConfirmStackName = $Confirmation }
    }
    [IO.File]::WriteAllText((Join-Path $FixtureRoot 'project.json'), ($settings | ConvertTo-Json -Depth 8), [Text.UTF8Encoding]::new($false))
}

function Invoke-NativePlot([string]$Plot, [switch]$ExpectFailure) {
    $argsForRun = @('-NoProfile', '-File', (Join-Path $ScriptsRoot 'Run.ps1'), $Plot,
        '-DefaultConfigPath', (Join-Path $FixtureRoot 'default.json'), '-ConfigPath', (Join-Path $FixtureRoot 'project.json'),
        '-EnvironmentConfigPath', (Join-Path $FixtureRoot 'environments/development.json'), '-WorkDirectory', $FixtureRoot)
    $process = Invoke-CheckedProcess $Pwsh $argsForRun "Native plot $Plot" -TimeoutSeconds 2400 -AllowFailure
    try { $result = $process.Stdout | ConvertFrom-Json -AsHashtable } catch { throw "Native plot $Plot did not return its structured result." }
    if ($ExpectFailure) {
        Assert-Test ($process.ExitCode -ne 0 -and $result.Status -eq 'Failed') "Native plot $Plot should have rejected the request."
    } else {
        Assert-Test ($process.ExitCode -eq 0 -and $result.Status -eq 'Succeeded') "Native plot $Plot failed; inspect the fixture locally without sharing private files."
        Add-Check "plot:$Plot" ([ordered]@{ RunId = $result.RunId; Steps = @($result.Steps | ForEach-Object { [ordered]@{ Id = $_.Id; Status = $_.Status; DurationMs = $_.DurationMs } }) })
    }
    return $result
}

function Get-ContentId($Result) {
    $text = @($Result.Steps | ForEach-Object { if ($_.Output -and $_.Output.ContainsKey('StandardOutput')) { $_.Output.StandardOutput } }) -join "`n"
    $match = [regex]::Match($text, '\(Id=(\d+)\)')
    Assert-Test $match.Success 'The helper returned no persistent demo content identifier.'
    return [int]$match.Groups[1].Value
}

function Get-CheckedResources([switch]$RequireEmpty) {
    Assert-Test ($StackName -cmatch '^pm-sensenet-test-[0-9a-f]{12}$') 'Refusing an unexpected test namespace.'
    $containers = @()
    $ids = Invoke-Docker @('container', 'ls', '--all', '--quiet', '--filter', "label=com.docker.compose.project=$StackName") 'Test container lookup'
    foreach ($id in ($ids -split '\r?\n' | Where-Object { $_ })) {
        $labels = Invoke-Docker @('container', 'inspect', '--format', '{{json .Config.Labels}}', $id) 'Test container ownership' | ConvertFrom-Json -AsHashtable
        $directory = [IO.Path]::GetFullPath(($labels['com.docker.compose.project.working_dir'] -replace '[/\\]', [IO.Path]::DirectorySeparatorChar))
        Assert-Test ($labels['com.docker.compose.project'] -ceq $StackName -and $directory.Equals($FixtureRoot, $PathComparison) -and
            $labels['com.docker.compose.service'] -in @('snsql', 'db-init', 'snapp', 'snis')) 'Refusing a container outside this fixture.'
        $containers += [pscustomobject]@{ Id = $id; Service = $labels['com.docker.compose.service'] }
    }
    # Look up names too, so a colliding volume with foreign/missing labels is
    # rejected rather than silently omitted from the ownership check.
    $volumeNames = @( (Invoke-Docker @('volume', 'ls', '--quiet', '--filter', "name=$StackName") 'Test volume lookup') -split '\r?\n' | Where-Object { $_ } )
    foreach ($name in $volumeNames) {
        $labels = Invoke-Docker @('volume', 'inspect', '--format', '{{json .Labels}}', $name) 'Test volume ownership' | ConvertFrom-Json -AsHashtable
        $volume = $labels['com.docker.compose.volume']
        Assert-Test ($volume -in @('db-data', 'app-data') -and $name -ceq "${StackName}_$volume" -and
            $labels['com.docker.compose.project'] -ceq $StackName -and
            $labels['io.github.vargajoe.plotmanager.project-directory-sha256'] -ceq $DirectoryHash) 'Refusing a data volume outside this fixture.'
    }
    $networks = @( (Invoke-Docker @('network', 'ls', '--quiet', '--filter', "label=com.docker.compose.project=$StackName") 'Test network lookup') -split '\r?\n' | Where-Object { $_ } )
    foreach ($id in $networks) {
        $name = Invoke-Docker @('network', 'inspect', '--format', '{{.Name}}', $id) 'Test network ownership'
        Assert-Test ($name -ceq "${StackName}_default") 'Refusing a network outside this fixture.'
    }
    if ($RequireEmpty) { Assert-Test ($containers.Count + $volumeNames.Count + $networks.Count -eq 0) 'The fresh test namespace is already in use.' }
    return [pscustomobject]@{ Containers = $containers; Volumes = $volumeNames; Networks = $networks }
}

function Get-ServiceContainer([string]$Service) {
    $matches = @((Get-CheckedResources).Containers | Where-Object Service -eq $Service)
    Assert-Test ($matches.Count -eq 1) "Expected one fixture $Service container."
    return $matches[0].Id
}

function Invoke-FixtureSql([string]$Query) {
    $container = Get-ServiceContainer 'snsql'
    # The password expands inside the owned container, never into host arguments.
    $command = 'exec /opt/mssql-tools18/bin/sqlcmd -S localhost -U sa -P "$MSSQL_SA_PASSWORD" -C -b -h -1 -W -Q "$1"'
    Invoke-Docker @('exec', $container, '/bin/bash', '-ec', $command, 'plot-manager-acceptance', $Query) 'Fixture SQL marker'
}

function Set-AppMarker([string]$Value) {
    $container = Get-ServiceContainer 'snapp'
    $command = 'printf "%s\n" "$1" > /app/App_Data/plot-manager-acceptance-marker.txt'
    $null = Invoke-Docker @('exec', $container, '/bin/sh', '-ec', $command, 'plot-manager-acceptance', $Value) 'Fixture App_Data marker'
}

function Assert-Markers([string]$Expected) {
    $sql = Invoke-FixtureSql 'SET NOCOUNT ON; SELECT Marker FROM PlotManagerAcceptance.dbo.Marker;'
    Assert-Test ($sql -ceq $Expected) 'The restored SQL marker differs from the backup.'
    $app = Invoke-Docker @('exec', (Get-ServiceContainer 'snapp'), '/bin/sh', '-ec', 'cat /app/App_Data/plot-manager-acceptance-marker.txt') 'Fixture App_Data marker read'
    Assert-Test ($app -ceq $Expected) 'The restored App_Data marker differs from the backup.'
}

function Remove-CheckedPrivateFiles {
    $expectedRoot = [IO.Path]::GetFullPath((Join-Path $FixturesRoot $FixtureId))
    $private = [IO.Path]::GetFullPath((Join-Path $FixtureRoot '.local'))
    Assert-Test ($FixtureRoot.Equals($expectedRoot, $PathComparison) -and (Split-Path $FixtureRoot -Leaf) -ceq $FixtureId -and
        (Split-Path $private -Parent).Equals($FixtureRoot, $PathComparison)) 'Refusing unsafe fixture file cleanup.'
    foreach ($path in @($FixturesRoot, $FixtureRoot, $private)) {
        if (Test-Path -LiteralPath $path) {
            Assert-Test (-not ((Get-Item -LiteralPath $path -Force).Attributes -band [IO.FileAttributes]::ReparsePoint)) 'Refusing cleanup through a symbolic link or junction.'
        }
    }
    if (Test-Path -LiteralPath $private) { Remove-Item -LiteralPath $private -Recurse -Force }
}

try {
    $null = [IO.Directory]::CreateDirectory($FixtureRoot)
    foreach ($item in Get-ChildItem -LiteralPath $ExampleRoot -Force | Where-Object Name -ne '.local') {
        Assert-Test (-not ($item.Attributes -band [IO.FileAttributes]::ReparsePoint)) 'The source example must not contain symbolic links.'
        Copy-Item -LiteralPath $item.FullName -Destination $FixtureRoot -Recurse -Force
    }
    $ApiPort = Get-FreePort
    do { $IdentityPort = Get-FreePort } while ($IdentityPort -eq $ApiPort)
    $Evidence.ApiPort = $ApiPort; $Evidence.IdentityPort = $IdentityPort
    Write-ProjectSettings $false
    Import-Module (Join-Path $ScriptsRoot 'Core/PlotManager.psm1') -Force
    $Registry = New-PlotRegistry -AutoPath (Join-Path $ScriptsRoot 'Auto')
    $configuration = Read-PlotConfiguration -Path @((Join-Path $FixtureRoot 'default.json'), (Join-Path $FixtureRoot 'project.json'), (Join-Path $FixtureRoot 'environments/development.json'))
    $Evidence.Images = $configuration.SenseNet.Images
    foreach ($plot in ($configuration.Plots.Keys | Sort-Object)) {
        $plan = Get-PlotPlan -Registry $Registry -Configuration $configuration -Plot $plot
        Add-Check "preflight:$plot" ([ordered]@{ Steps = $plan.Count })
    }
    $unaccepted = $configuration.SenseNet
    $unaccepted.AcceptSqlLicense = $false
    $licenseConfiguration = Join-Path $FixtureRoot 'license-not-accepted.json'
    [IO.File]::WriteAllText($licenseConfiguration, ($unaccepted | ConvertTo-Json -Depth 10), [Text.UTF8Encoding]::new($false))
    $rejected = Invoke-CheckedProcess $Pwsh @('-NoProfile', '-File', (Join-Path $FixtureRoot 'scripts/Manage-SenseNet.ps1'), '-Action', 'prepare', '-Configuration', $licenseConfiguration) 'Unaccepted license check' -AllowFailure
    Assert-Test ($rejected.ExitCode -ne 0 -and ($rejected.Stdout + $rejected.Stderr) -match 'AcceptSqlLicense') 'Prepare must reject the unaccepted SQL license.'
    Assert-Test (-not (Test-Path -LiteralPath (Join-Path $FixtureRoot '.local'))) 'Unaccepted prepare created runtime files.'
    Add-Check 'license-rejected-before-runtime-effects'

    if ($RunDocker) {
        Assert-Test ((Invoke-Docker @('info', '--format', '{{.OSType}}') 'Docker Linux check') -ceq 'linux') 'Docker must run Linux containers.'
        $null = Invoke-Docker @('compose', 'version', '--short') 'Docker Compose check'
        $null = Get-CheckedResources -RequireEmpty
        Write-ProjectSettings $true
        $CleanupRequired = $true
        $null = Invoke-NativePlot 'install'
        $contentId = Get-ContentId (Invoke-NativePlot 'demo-content')
        $Evidence.ContentId = $contentId
        $before = 'before-' + $FixtureId
        $after = 'after-' + $FixtureId
        $null = Invoke-FixtureSql "CREATE DATABASE PlotManagerAcceptance;"
        $null = Invoke-FixtureSql "USE PlotManagerAcceptance; CREATE TABLE dbo.Marker (Marker nvarchar(100) NOT NULL); INSERT dbo.Marker VALUES (N'$before');"
        Set-AppMarker $before
        $null = Invoke-NativePlot 'backup'
        $backups = @(Get-ChildItem -LiteralPath (Join-Path $FixtureRoot '.local/backups') -Directory | Where-Object { Test-Path -LiteralPath (Join-Path $_.FullName 'manifest.json') })
        Assert-Test ($backups.Count -eq 1) 'Expected exactly one completed fixture backup.'
        $backupPath = '.local/backups/' + $backups[0].Name
        $Evidence.BackupDirectory = $backupPath
        $null = Invoke-FixtureSql "UPDATE PlotManagerAcceptance.dbo.Marker SET Marker = N'$after';"
        Set-AppMarker $after
        Assert-Markers $after
        $null = Invoke-NativePlot 'stop'
        $null = Invoke-NativePlot 'start'
        Assert-Test ((Get-ContentId (Invoke-NativePlot 'verify-demo-content')) -eq $contentId) 'Content ID changed after stop/start.'
        Add-Check 'content-id-survives-stop-start' $contentId
        $null = Invoke-NativePlot 'remove-containers-keep-data'
        $null = Invoke-NativePlot 'start'
        Assert-Test ((Get-ContentId (Invoke-NativePlot 'verify-demo-content')) -eq $contentId) 'Content ID changed after container recreation.'
        Assert-Markers $after
        Add-Check 'content-and-current-markers-survive-container-recreation' $contentId
        Write-ProjectSettings $true $backupPath ''
        $null = Invoke-NativePlot 'restore' -ExpectFailure
        Assert-Markers $after
        Add-Check 'restore-requires-exact-stack-confirmation'
        Write-ProjectSettings $true $backupPath $StackName
        $null = Invoke-NativePlot 'restore'
        Assert-Markers $before
        Assert-Test ((Get-ContentId (Invoke-NativePlot 'verify-demo-content')) -eq $contentId) 'Restored SenseNet content ID differs from its backup.'
        Add-Check 'restore-replaces-both-volumes-and-retains-content-id' $contentId
    }
} catch {
    $Failure = $_.Exception.Message
} finally {
    try {
        if ($CleanupRequired) {
            $remaining = Get-CheckedResources
            if ($remaining.Containers.Count + $remaining.Volumes.Count + $remaining.Networks.Count -gt 0) {
                $null = Invoke-Docker @('compose', '--project-name', $StackName, '--project-directory', $FixtureRoot,
                    '--env-file', (Join-Path $FixtureRoot '.local/runtime.env'), '--file', (Join-Path $FixtureRoot 'compose.yaml'),
                    'down', '--volumes', '--timeout', '30') 'Owned fixture cleanup'
            }
            $null = Get-CheckedResources -RequireEmpty
            Add-Check 'cleanup-removes-only-owned-fixture-resources'
        }
        $CleanupSucceeded = $true
        Remove-CheckedPrivateFiles
        $Evidence.PrivateFilesRemoved = $true
    } catch {
        if (-not $Failure) { $Failure = 'Fixture cleanup failed; private files were retained for local recovery.' }
        $Evidence.CleanupFailure = 'Ownership validation or scoped cleanup failed. Inspect only this fixture locally.'
    }
    if ($null -ne $Registry) { Remove-PlotRegistry -Registry $Registry }
    $Evidence.CleanupSucceeded = $CleanupSucceeded
    $Evidence.Failure = $Failure
    $Evidence.CompletedUtc = [DateTime]::UtcNow.ToString('o')
    if (Test-Path -LiteralPath $FixtureRoot -PathType Container) {
        $evidencePath = Join-Path $FixtureRoot 'acceptance-evidence.json'
        [IO.File]::WriteAllText($evidencePath, ($Evidence | ConvertTo-Json -Depth 15), [Text.UTF8Encoding]::new($false))
    }
}
if ($Failure) { throw $Failure }
Write-Output "SenseNet example: $($Checks.Count) checks passed; Docker=$([bool]$RunDocker). Evidence: $evidencePath"
