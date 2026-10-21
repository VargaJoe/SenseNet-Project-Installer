# Provider contract tests use isolated modules. No external database or IIS site is modified.
Test-Case 'Web maintenance uses real files and preserves existing maintenance content' {
    $directory=Join-Path $testRoot 'web'; $null=[IO.Directory]::CreateDirectory($directory)
    Assert-Succeeded (Invoke-TestStep web.offline @{Directory=$directory;Content='Maintenance'})
    Assert-Equal ([IO.File]::ReadAllText((Join-Path $directory 'app_offline.htm'))) 'Maintenance'
    Assert-Equal (Invoke-TestStep web.offline @{Directory=$directory;Content='replace'}).Status 'Failed'
    Assert-Equal ([IO.File]::ReadAllText((Join-Path $directory 'app_offline.htm'))) 'Maintenance'
    Assert-Succeeded (Invoke-TestStep web.online @{Directory=$directory})
    Assert-Succeeded (Invoke-TestStep web.online @{Directory=$directory})
    Assert-True (-not [IO.File]::Exists((Join-Path $directory 'app_offline.htm')))
}
Test-Case 'Failed web deployment leaves maintenance page in place' {
    $directory=Join-Path $testRoot 'failed-web'; $null=[IO.Directory]::CreateDirectory($directory)
    $config=New-Config @(@{Step='web.offline';With=@{Directory=$directory}},@{Step='filesystem.copy-tree';With=@{Source='missing-artifact';Destination=$directory}},@{Step='web.online';With=@{Directory=$directory}})
    $result=Invoke-Plot $registry $config demo -WorkDirectory $testRoot
    Assert-Equal $result.Status 'Failed'; Assert-True ([IO.File]::Exists((Join-Path $directory 'app_offline.htm')))
}
Test-Case 'Compose adapters preserve project scope, ordered files, profiles and arguments' {
    $fixture=New-Module -ScriptBlock {
        function Invoke-FixtureProcess { param($Settings,$Context) $Settings }
        Export-ModuleMember Invoke-FixtureProcess
    }
    $context=[pscustomobject]@{WorkDirectory=$testRoot;Dependencies=@{'process.run'=[pscustomobject]@{Command=$fixture.ExportedFunctions['Invoke-FixtureProcess'];Defaults=@{SuccessExitCodes=@(0)}}}}
    $base=Join-Path $testRoot 'base compose.yaml'; $override=Join-Path $testRoot 'override.yaml'; $envFile=Join-Path $testRoot 'test.env'
    foreach ($path in @($base,$override,$envFile)) { [IO.File]::WriteAllText($path,'fixture') }
    foreach ($operation in @('config','pull','build','up','ps','logs','stop','down')) {
        $config=New-Config @(@{Step=('compose.'+$operation);With=@{ProjectName='test-project';Files=@($base,$override);EnvFiles=@($envFile);Profiles=@('worker');Services=@('web');Arguments=@('--label=two words');Environment=@{TOKEN='child-secret'}}})
        $plan=Get-PlotPlan $registry $config demo
        $actual=& $plan[0].Step.Command -Settings $plan[0].Settings -Context $context
        $expected=@('compose','--project-name','test-project','--project-directory',$testRoot,'--file',$base,'--file',$override,'--env-file',$envFile,'--profile','worker',$operation)
        if ($operation -eq 'up') { $expected+='--detach' }
        $expected+=@('--label=two words','web')
        Assert-Equal $actual.FilePath 'docker'
        Assert-Equal ($actual.Arguments | ConvertTo-Json -Compress) ($expected | ConvertTo-Json -Compress)
        Assert-Equal $actual.Environment.TOKEN 'child-secret'; Assert-Equal $actual.SuccessExitCodes[0] 0
    }
}
Test-Case 'Compose refuses implicit project scope and invalid inputs before process execution' {
    foreach ($with in @(
        @{ProjectName='Bad Name';Files=@('missing.yaml')},
        @{ProjectName='demo';Files=@()},
        @{ProjectName='demo';Files=@('missing.yaml')},
        @{ProjectName='demo';Files=@(42)}
    )) { Assert-Equal (Invoke-TestStep compose.up $with).Status 'Failed' }
}
Test-Case 'SQL provider errors are sanitized and connection timeout is bounded' {
    $timer=[Diagnostics.Stopwatch]::StartNew()
    $result=Invoke-TestStep sqlserver.query @{ConnectionString='Server=127.0.0.1,1;User ID=test;Password=never-print-this;Encrypt=False';Query='SELECT 1';ConnectTimeoutSeconds=1;CommandTimeoutSeconds=1}
    Assert-Equal $result.Status 'Failed'; Assert-True ($timer.Elapsed.TotalSeconds -lt 8)
    Assert-True (($result | ConvertTo-Json -Depth 12) -notlike '*never-print-this*')
    Assert-True ($result.Steps[0].Error -like '*SQL operation failed*')
}
$sqlModule=$registry.Packages.sqlserver.Module
$originalSql=& $sqlModule { (Get-Command Invoke-SqlCommand).ScriptBlock }
try {
    & $sqlModule {
        $script:SqlCalls=0; $script:FailSql=$false
        function script:Invoke-SqlCommand($Settings,[string]$Text,[hashtable]$Parameters=@{},[string]$Database='',[switch]$ReadRows,[int]$MaxRows=10000) {
            $script:SqlCalls++
            if ($script:FailSql) { throw 'simulated provider failure' }
            [pscustomobject]@{Text=$Text;Parameters=$Parameters;Database=$Database;ReadRows=[bool]$ReadRows;MaxRows=$MaxRows}
        }
    }
    function Invoke-TestSql([string]$Step,[hashtable]$With) {
        $With.ConnectionString='test-only'; Invoke-TestStep $Step $With
    }
    Test-Case 'SQL query uses scalar parameters and script execution resolves work directory' {
        $query=Invoke-TestSql sqlserver.query @{Query='SELECT @name';Parameters=@{name="O'Brien"};MaxRows=3}
        Assert-Succeeded $query; Assert-Equal $query.Steps[0].Output.Parameters.name "O'Brien"; Assert-Equal $query.Steps[0].Output.MaxRows 3
        [IO.File]::WriteAllText((Join-Path $testRoot 'batch.sql'),'SELECT @value;')
        $batch=Invoke-TestSql sqlserver.execute @{Path='batch.sql';Parameters=@{value=1}}
        Assert-Succeeded $batch; Assert-Equal $batch.Steps[0].Output.Text 'SELECT @value;'
        Assert-Equal (Invoke-TestSql sqlserver.execute @{Query='SELECT 1';Path='batch.sql'}).Status 'Failed'
        Assert-Equal (Invoke-TestSql sqlserver.execute @{Query="SELECT 1;`nGO`nSELECT 2;"}).Status 'Failed'
    }
    Test-Case 'SQL backup quotes identifiers and paths without implicit overwrite' {
        $result=Invoke-TestSql sqlserver.backup @{Database='db]; DROP TABLE x;--';Path="D:\Backups\O'Brien.bak"}
        Assert-Succeeded $result
        Assert-Equal $result.Steps[0].Output.Text "BACKUP DATABASE [db]]; DROP TABLE x;--] TO DISK = N'D:\Backups\O''Brien.bak' WITH CHECKSUM, COPY_ONLY"
        Assert-Equal $result.Steps[0].Output.Database 'master'
        Assert-True ($result.Steps[0].Output.Text -notmatch '\bINIT\b')
    }
    Test-Case 'SQL restore uses explicit logical file mappings and opt-in replacement' {
        $result=Invoke-TestSql sqlserver.restore @{Database='restored';Path='backup.bak';Moves=@{'actual-data'='D:\data.mdf';'actual-log'='D:\log.ldf'};BackupSet=2}
        Assert-Succeeded $result; $text=$result.Steps[0].Output.Text
        Assert-True ($text.Contains("MOVE N'actual-data' TO N'D:\data.mdf'")); Assert-True ($text.Contains('FILE = 2')); Assert-True ($text -notmatch '\bREPLACE\b')
        Assert-Equal (Invoke-TestSql sqlserver.restore @{Database='demo';Path='backup.bak';Moves=@{}}).Status 'Failed'
        $replace=Invoke-TestSql sqlserver.restore @{Database='demo';Path='backup.bak';Moves=@{data='file.mdf'};Replace=$true}
        Assert-True ($replace.Steps[0].Output.Text -match '\bREPLACE\b')
    }
    Test-Case 'SQL database creation, file configuration and protected database checks' {
        $create=Invoke-TestSql sqlserver.create @{Database='demo';RecoveryModel='FULL'}
        Assert-Succeeded $create; Assert-True ($create.Steps[0].Output.Text.Contains('CREATE DATABASE [demo]'))
        $file=Invoke-TestSql sqlserver.configure-file @{Database='demo';LogicalName='data';SizeMb=128;MaxSizeMb=1024;GrowthMb=64}
        Assert-Succeeded $file; Assert-True ($file.Steps[0].Output.Text.Contains('SIZE = 128MB, MAXSIZE = 1024MB, FILEGROWTH = 64MB'))
        Assert-Equal (Invoke-TestSql sqlserver.configure-file @{Database='demo';LogicalName='data';SizeMb=128;MaxSizeMb=1}).Status 'Failed'
        foreach ($db in @('master','model','msdb','tempdb')) { Assert-Equal (Invoke-TestSql sqlserver.drop @{Database=$db}).Status 'Failed' }
        Assert-Succeeded (Invoke-TestSql sqlserver.drop @{Database='demo'})
    }
    Test-Case 'SQL user and login operations preserve names and grant only requested roles' {
        $user=Invoke-TestSql sqlserver.user @{Database='demo';Action='create';UserName='app-user';LoginName='app-login';Roles=@('db_datareader')}
        Assert-Succeeded $user; $text=$user.Steps[0].Output.Text
        Assert-True ($text.Contains('CREATE USER [app-user] FOR LOGIN [app-login]')); Assert-True ($text.Contains('ALTER ROLE [db_datareader] ADD MEMBER [app-user]'))
        Assert-True ($text -notmatch 'db_owner|VIEW SERVER STATE')
        Assert-Succeeded (Invoke-TestSql sqlserver.user @{Database='demo';Action='drop';UserName='app-user'})
        $login=Invoke-TestSql sqlserver.login @{Action='create';LoginName='app-login';Password="p'ass"}
        Assert-Succeeded $login; Assert-True ($login.Steps[0].Output.Text.Contains("PASSWORD = N'p''ass'"))
        Assert-Equal (Invoke-TestSql sqlserver.login @{Action='drop';LoginName='sa'}).Status 'Failed'
        Assert-Succeeded (Invoke-TestSql sqlserver.login @{Action='drop';LoginName='app-login'})
    }
    Test-Case 'SQL readiness retries are bounded and later steps stop on provider failure' {
        Assert-Succeeded (Invoke-TestSql sqlserver.wait @{})
        & $sqlModule { $script:FailSql=$true; $script:SqlCalls=0 }
        try {
            $timer=[Diagnostics.Stopwatch]::StartNew()
            $result=Invoke-TestSql sqlserver.wait @{TimeoutSeconds=1;IntervalMilliseconds=30}
            Assert-Equal $result.Status 'Failed'; Assert-True ($timer.Elapsed.TotalSeconds -lt 3)
            Assert-True ((& $sqlModule { $script:SqlCalls }) -gt 1)
            $config=New-Config @(@{Step='sqlserver.execute';With=@{ConnectionString='test';Query='SELECT 1'}},@{Step='filesystem.write';With=@{Path='after-sql.txt'}})
            Assert-Equal (Invoke-Plot $registry $config demo -WorkDirectory $testRoot).Status 'Failed'
            Assert-True (-not [IO.File]::Exists((Join-Path $testRoot 'after-sql.txt')))
        } finally { & $sqlModule { $script:FailSql=$false } }
    }
    Test-Case 'New packages honor direct WhatIf before provider or process calls' {
        $context=[pscustomobject]@{WorkDirectory=$testRoot;Dependencies=@{}}
        $before=& $sqlModule { $script:SqlCalls }
        foreach ($case in @(
            @{Step='sqlserver.backup';With=@{ConnectionString='test';Database='demo';Path='backup.bak'}},
            @{Step='sqlserver.wait';With=@{ConnectionString='test'}},
            @{Step='compose.up';With=@{ProjectName='demo';Files=@('missing.yaml')}},
            @{Step='iis.create';With=@{WebsiteName='demo';AppPoolName='demo';PhysicalPath=$testRoot}},
            @{Step='iis.status';With=@{WebsiteName='demo'}},
            @{Step='web.offline';With=@{Directory=$testRoot}}
        )) {
            $plan=Get-PlotPlan $registry (New-Config @(@{Step=$case.Step;With=$case.With})) demo
            $null=& $plan[0].Step.Command -Settings $plan[0].Settings -Context $context -WhatIf
        }
        Assert-Equal (& $sqlModule { $script:SqlCalls }) $before
        Assert-True (-not [IO.File]::Exists((Join-Path $testRoot 'app_offline.htm')))
    }
} finally { & $sqlModule { param($original) Set-Item Function:script:Invoke-SqlCommand $original } $originalSql }
Test-Case 'IIS provisioning uses dedicated pools and refuses existing site or binding' {
    # Use a separate module instance so earlier lifecycle test fixtures remain untouched.
    $iis=New-Module -ScriptBlock ([scriptblock]::Create([IO.File]::ReadAllText((Join-Path $scriptsPath 'Auto/Iis/Plot.Iis.psm1'))))
    & $iis {
        $script:Existing=$false; $script:Collision=$false; $script:Calls=New-Object Collections.ArrayList
        function script:Import-Module { [CmdletBinding()]param($Name) }
        function script:Get-Website { [CmdletBinding()]param($Name) if ($script:Existing) { [pscustomobject]@{Name=$Name;State='Started';applicationPool='demo-pool';physicalPath='web'} } }
        function script:Get-WebBinding { [CmdletBinding()]param($Protocol) if ($script:Collision) { [pscustomobject]@{bindingInformation='*:18081:'} } }
        function script:Test-Path { [CmdletBinding()]param($LiteralPath) $false }
        function script:New-WebAppPool { [CmdletBinding()]param($Name) $null=$script:Calls.Add('pool:'+ $Name) }
        function script:Set-ItemProperty { [CmdletBinding()]param($LiteralPath,$Name,$Value) $null=$script:Calls.Add($Name+':'+$Value) }
        function script:New-Website { [CmdletBinding()]param($Name,$PhysicalPath,$ApplicationPool,$IPAddress,$Port,$HostHeader) $null=$script:Calls.Add('site:'+ $Name) }
        function script:Get-WebAppPoolState { [CmdletBinding()]param($Name) [pscustomobject]@{Value='Started'} }
        function script:Restart-WebAppPool { [CmdletBinding()]param($Name) $null=$script:Calls.Add('recycle:'+ $Name) }
    }
    $plan=Get-PlotPlan $registry (New-Config @(@{Step='iis.create';With=@{WebsiteName='demo';AppPoolName='demo-pool';PhysicalPath=$testRoot;Port=18081}})) demo
    $context=[pscustomobject]@{WorkDirectory=$testRoot}
    $actual=& $iis.ExportedFunctions['New-PlotIisSite'] -Settings $plan[0].Settings -Context $context
    Assert-Equal $actual.Binding '*:18081:'
    Assert-Equal ((& $iis { $script:Calls }) -join '|') 'pool:demo-pool|managedRuntimeVersion:|managedPipelineMode:Integrated|site:demo'
    & $iis { $script:Existing=$true }
    Assert-Throws { & $iis.ExportedFunctions['New-PlotIisSite'] -Settings $plan[0].Settings -Context $context } '*already exists*'
    $status=& $iis.ExportedFunctions['Get-PlotIisStatus'] -Settings @{WebsiteName='demo'} -Context $context
    Assert-Equal $status.AppPoolState 'Started'
    $recycled=& $iis.ExportedFunctions['Restart-PlotIisPool'] -Settings @{AppPoolName='demo-pool';TimeoutSeconds=1;PollMilliseconds=5} -Context $context
    Assert-Equal $recycled.State 'Started'
    & $iis { $script:Existing=$false; $script:Collision=$true }
    Assert-Throws { & $iis.ExportedFunctions['New-PlotIisSite'] -Settings $plan[0].Settings -Context $context } '*binding is already assigned*'
}
Test-Case 'Structured integration catalog, plan, preview and run share layered native settings' {
    Import-Module (Join-Path $scriptsPath 'Core/PlotIntegration.psm1') -Force
    $default=Join-Path $testRoot 'ui-default.json'; $project=Join-Path $testRoot 'ui-project.json'
    Write-TestJson $default (New-Config @(@{Id='save';Step='filesystem.write';With=@{Path='ui.txt';Content=@{'$ref'='settings.Values.Content'}}}))
    Write-TestJson $project @{Values=@{Content='project value'}}
    $request=@{Operation='catalog';ConfigurationFiles=@($default,$project);WorkDirectory=$testRoot}
    $catalog=Invoke-PlotRequest $request
    Assert-Equal $catalog.ProtocolVersion 1; Assert-Equal $catalog.Steps.Count 49; Assert-Equal $catalog.Plots[0] 'demo'
    Assert-True (($catalog | ConvertTo-Json -Depth 20) -notlike '*project value*')
    $request.Operation='plan'; $request.Plot='demo'
    $plan=Invoke-PlotRequest $request; Assert-Equal $plan.Steps[0].Step 'filesystem.write'
    Assert-True (($plan | ConvertTo-Json -Depth 20) -notlike '*project value*')
    $request.Operation='run'; $request.WhatIf=$true
    Assert-Equal (Invoke-PlotRequest $request).Status 'Skipped'; Assert-True (-not [IO.File]::Exists((Join-Path $testRoot 'ui.txt')))
    $request.WhatIf=$false; $request.Overrides=@{save=@{Content='override'}}
    Assert-Succeeded (Invoke-PlotRequest $request)
    Assert-Equal ([IO.File]::ReadAllText((Join-Path $testRoot 'ui.txt'))) 'override'
}
Test-Case 'Structured integration rejects command strings and ambiguous requests' {
    foreach ($request in @(
        @{Operation='run';Command='Write-Host unsafe'},
        @{Operation='run';Plot='x';Step='text.join'},
        @{Operation='run';Step='text.join';WhatIf='false'},
        @{Operation='catalog';ConfigurationFiles='file.json'},
        @{Operation='catalog';ConfigurationFiles=@('')}
    )) { Assert-Throws { Invoke-PlotRequest $request } '*' }
}
Test-Case 'Request CLI returns machine-readable success and nonzero error status' {
    $file=Join-Path $testRoot 'request.json'
    Write-TestJson $file @{Operation='run';Step='text.join';Overrides=@{single=@{Items=@('hello','world');Separator=' '}}}
    $out=& (Get-Process -Id $PID).Path -NoProfile -NonInteractive -File (Join-Path $scriptsPath 'Invoke-Request.ps1') -RequestPath $file
    Assert-Equal $LASTEXITCODE 0
    Assert-Equal (($out -join [Environment]::NewLine | ConvertFrom-Json).Status) 'Succeeded'
    Write-TestJson $file @{Operation='run';Step='text.join';WhatIf=$true;Overrides=@{single=@{Items=@('preview')}}}
    $out=& (Get-Process -Id $PID).Path -NoProfile -NonInteractive -File (Join-Path $scriptsPath 'Invoke-Request.ps1') -RequestPath $file
    Assert-Equal $LASTEXITCODE 0
    Assert-Equal (($out -join [Environment]::NewLine | ConvertFrom-Json).Status) 'Skipped'
    Write-TestJson $file @{Operation='run';Step='filesystem.read';Overrides=@{single=@{Path=(Join-Path $testRoot 'absent.txt')}}}
    $out=& (Get-Process -Id $PID).Path -NoProfile -NonInteractive -File (Join-Path $scriptsPath 'Invoke-Request.ps1') -RequestPath $file
    Assert-Equal $LASTEXITCODE 1
    Assert-Equal (($out -join [Environment]::NewLine | ConvertFrom-Json).Status) 'Failed'
}
Test-Case 'Platform scenarios preflight with dummy SQL credentials without calling providers' {
    $old=[Environment]::GetEnvironmentVariable('PLOT_SQL_CONNECTION'); $env:PLOT_SQL_CONNECTION='test-only'
    try {
        foreach ($file in @('compose.json','database.json','iis.json')) {
            $config=Read-PlotConfiguration (Join-Path $scriptsPath ('Examples/platform/'+$file))
            foreach ($name in $config.Plots.Keys) { Assert-True ((Get-PlotPlan $registry $config $name).Count -gt 0); Assert-Equal (Invoke-Plot $registry $config $name -WhatIf).Status 'Skipped' }
        }
    } finally { [Environment]::SetEnvironmentVariable('PLOT_SQL_CONNECTION',$old) }
}
