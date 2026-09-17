# Local-only integration fixtures; no remote services or corporate data.
Test-Case 'JSON readers preserve ISO strings and nested arrays on every supported host' {
    $text='{"Stamp":"2026-09-16T10:20:30+05:00","Nested":{"Items":["2026-01-02T03:04:05.1234567Z"],"Empty":[],"No":false,"Nil":null}}'
    $path=Join-Path $testRoot 'dates.json'; [IO.File]::WriteAllText($path,$text)
    $configuration=Read-PlotConfiguration $path
    Assert-Equal $configuration.Stamp '2026-09-16T10:20:30+05:00'
    Assert-True ($configuration.Stamp -is [string])
    $read=Invoke-TestStep json.read @{Path=$path}; Assert-Succeeded $read
    Assert-Equal $read.Steps[0].Output.Value.Stamp $configuration.Stamp
    $written=Join-Path $testRoot 'dates-roundtrip.json'
    Assert-Succeeded (Invoke-TestStep json.write @{Path=$written;Value=$read.Steps[0].Output.Value})
    $roundtrip=Read-PlotConfiguration $written
    Assert-Equal $roundtrip.Nested.Items[0] '2026-01-02T03:04:05.1234567Z'
    Assert-Equal $roundtrip.Nested.Empty.Count 0
    Assert-True ($null -eq $roundtrip.Nested.Nil)
    Assert-Equal $roundtrip.Nested.No $false
    Assert-Equal ([IO.File]::ReadAllText((Join-Path $scriptsPath 'Core/JsonText.ps1'))) ([IO.File]::ReadAllText((Join-Path $scriptsPath 'Auto/Json/JsonText.ps1')))
}
Test-Case 'CLI JSON overrides preserve timezone offsets literally' {
    $file=Join-Path $testRoot 'dates-cli.json'
    Write-TestJson $file (New-Config @(@{Id='save';Step='filesystem.write';With=@{Path='date.txt';Content='default'}}))
    $cli=Invoke-TestCli @('demo','-ConfigPath',$file,'-WorkDirectory',$testRoot,'-Params','{"save":{"Content":"2026-09-16T10:20:30+05:00"}}')
    Assert-Equal $cli.Code 0
    Assert-Equal ([IO.File]::ReadAllText((Join-Path $testRoot 'date.txt'))) '2026-09-16T10:20:30+05:00'
}
Test-Case 'CLI rejects explicit blank configuration layers including help and legacy' {
    foreach ($parameter in @('-DefaultConfigPath','-ConfigPath','-EnvironmentConfigPath')) {
        foreach ($mode in @('explain','help','legacy')) {
            $arguments=@($parameter,' ')
            if ($mode -eq 'explain') { $arguments+=@('layered','-Explain') }
            elseif ($mode -eq 'help') { $arguments+=@('-Help','steps') }
            else { $arguments+=@('-Legacy','-Help','steps') }
            $cli=Invoke-TestCli $arguments
            Assert-True ($cli.Code -ne 0)
            Assert-True (($cli.ErrorText -replace '\s+',' ') -like '*must not be empty*')
        }
    }
}
$operationsRoot=Join-Path $testRoot 'operations with spaces'
$null=[IO.Directory]::CreateDirectory($operationsRoot)
$hostExecutable=(Get-Process -Id $PID).Path
function Invoke-TestProcess([string]$Script,[hashtable]$Options=@{}) {
    $settings=@{FilePath=$hostExecutable;Arguments=@('-NoProfile','-NonInteractive','-EncodedCommand',[Convert]::ToBase64String([Text.Encoding]::Unicode.GetBytes($Script)))}
    foreach ($key in $Options.Keys) { $settings[$key]=$Options[$key] }
    Invoke-TestStep process.run $settings $operationsRoot
}
Test-Case 'Process captures both streams, custom exit code, directory and child-only environment' {
    $result=Invoke-TestProcess '[Console]::Out.Write($env:PLOT_CHILD_TEST+"|"+[Environment]::CurrentDirectory); [Console]::Error.Write("error stream"); exit 7' @{Environment=@{PLOT_CHILD_TEST='child value'};SuccessExitCodes=@(7)}
    Assert-Succeeded $result
    Assert-Equal $result.Steps[0].Output.ExitCode 7
    Assert-Equal $result.Steps[0].Output.StandardOutput ('child value|'+$operationsRoot)
    Assert-Equal $result.Steps[0].Output.StandardError 'error stream'
    Assert-True (-not (Test-Path Env:PLOT_CHILD_TEST))
}
Test-Case 'Process preserves empty, quoted, trailing slash and shell metacharacter arguments' {
    $script=Join-Path $operationsRoot 'arguments.ps1'
    [IO.File]::WriteAllText($script,'[Console]::Out.Write((ConvertTo-Json -InputObject @($args) -Compress))')
    $values=@('one two','','a"b','trailing\','; & $(echo danger)')
    $result=Invoke-TestStep process.run @{FilePath=$hostExecutable;Arguments=(@('-NoProfile','-NonInteractive','-File',$script)+$values)} $operationsRoot
    Assert-Succeeded $result
    $actual=$result.Steps[0].Output.StandardOutput | ConvertFrom-Json
    Assert-Equal $actual.Count $values.Count
    for ($i=0;$i -lt $values.Count;$i++) { Assert-Equal $actual[$i] $values[$i] }
}
Test-Case 'Process drains large stdout and stderr concurrently' {
    $result=Invoke-TestProcess '[Console]::Out.Write(("x"*200000)); [Console]::Error.Write(("y"*200000))'
    Assert-Succeeded $result
    Assert-Equal $result.Steps[0].Output.StandardOutput.Length 200000
    Assert-Equal $result.Steps[0].Output.StandardError.Length 200000
}
Test-Case 'Process failures do not reveal arguments, environment or child error text' {
    $result=Invoke-TestProcess '[Console]::Error.Write("secret-value");exit 9' @{Environment=@{TOKEN='secret-value'}}
    Assert-Equal $result.Status 'Failed'
    Assert-True ($result.Steps[0].Error -like '*code 9*')
    Assert-True (($result | ConvertTo-Json -Depth 10) -notlike '*secret-value*')
}
Test-Case 'Process timeout terminates owned child and stops the plot' {
    $marker=Join-Path $operationsRoot 'late.txt'
    $script="Start-Sleep -Seconds 4; [IO.File]::WriteAllText('"+$marker.Replace("'","''")+"','late')"
    $timer=[Diagnostics.Stopwatch]::StartNew()
    $result=Invoke-TestProcess $script @{TimeoutSeconds=1}
    Assert-Equal $result.Status 'Failed'
    Assert-True ($result.Steps[0].Error -like '*timeout*')
    Assert-True ($timer.Elapsed.TotalSeconds -lt 7)
    Start-Sleep -Seconds 4
    Assert-True (-not [IO.File]::Exists($marker))
}
Test-Case 'Process rejects scripts without explicit interpreter and invalid argument types' {
    Assert-Equal (Invoke-TestStep process.run @{FilePath=(Join-Path $operationsRoot 'arguments.ps1')}).Status 'Failed'
    Assert-Equal (Invoke-TestStep process.run @{FilePath=$hostExecutable;Arguments=@(1)}).Status 'Failed'
}
Add-Type -Path (Join-Path $PSScriptRoot 'HttpFixture.cs')
$server=[PlotHttpFixture]::new()
$baseUrl='http://127.0.0.1:'+$server.Port
try {
    Test-Case 'HTTP download verifies SHA256 and requires explicit replacement' {
        $settings=@{Url="$baseUrl/auth";Headers=@{'X-Test-Key'='local-secret'};Destination='download.txt';Sha256='ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad';TimeoutSeconds=5}
        $result=Invoke-TestStep http.download $settings $operationsRoot
        Assert-Succeeded $result
        Assert-Equal $result.Steps[0].Output.Bytes 3
        Assert-Equal ([IO.File]::ReadAllText((Join-Path $operationsRoot 'download.txt'))) 'abc'
        Assert-Equal (Invoke-TestStep http.download $settings $operationsRoot).Status 'Failed'
        $settings.Overwrite=$true
        Assert-Succeeded (Invoke-TestStep http.download $settings $operationsRoot)
    }
    Test-Case 'Failed checksum and byte limits preserve original destination and clean temporary files' {
        $path=Join-Path $operationsRoot 'protected.txt'; [IO.File]::WriteAllText($path,'original')
        foreach ($override in @(@{Sha256=('0'*64)},@{MaxBytes=2},@{MaxBytes=2;Url="$baseUrl/stream"})) {
            $settings=@{Url="$baseUrl/ok";Destination=$path;Overwrite=$true;TimeoutSeconds=5}
            foreach ($key in $override.Keys) { $settings[$key]=$override[$key] }
            Assert-Equal (Invoke-TestStep http.download $settings $operationsRoot).Status 'Failed'
            Assert-Equal ([IO.File]::ReadAllText($path)) 'original'
            Assert-Equal @(Get-ChildItem -LiteralPath $operationsRoot -Filter '.plot-download-*').Count 0
        }
    }
    Test-Case 'HTTP redirects and embedded URL credentials are not followed' {
        $before=$server.Requests
        Assert-Equal (Invoke-TestStep http.download @{Url="$baseUrl/redirect";Destination='redirect.txt'} $operationsRoot).Status 'Failed'
        Assert-Equal ($server.Requests-$before) 1
        Assert-Equal (Invoke-TestStep http.download @{Url='http://user:password@127.0.0.1/';Destination='credentials.txt'} $operationsRoot).Status 'Failed'
    }
    Test-Case 'HTTP readiness retries transient status and reports attempts' {
        $result=Invoke-TestStep http.wait @{Url="$baseUrl/retry";TimeoutSeconds=5;IntervalMilliseconds=10}
        Assert-Succeeded $result
        Assert-Equal $result.Steps[0].Output.Attempts 3
        Assert-Equal $result.Steps[0].Output.StatusCode 200
    }
    Test-Case 'HTTP overall deadline bounds slow headers and slow download bodies' {
        foreach ($step in @('http.wait','http.download')) {
            $settings=@{Url="$baseUrl/slow";TimeoutSeconds=1}
            if ($step -eq 'http.download') { $settings.Url="$baseUrl/slowbody"; $settings.Destination='slow.txt' }
            $timer=[Diagnostics.Stopwatch]::StartNew()
            $result=Invoke-TestStep $step $settings $operationsRoot
            Assert-Equal $result.Status 'Failed'
            Assert-True ($timer.Elapsed.TotalSeconds -lt 3)
        }
        Assert-True (-not [IO.File]::Exists((Join-Path $operationsRoot 'slow.txt')))
    }
    Test-Case 'HTTP WhatIf performs no requests and creates no files' {
        $before=$server.Requests
        $config=New-Config @(@{Step='http.download';With=@{Url="$baseUrl/ok";Destination='preview-download.txt'}})
        $result=Invoke-Plot $registry $config demo -WorkDirectory $operationsRoot -WhatIf
        Assert-Equal $result.Status 'Skipped'; Assert-Equal $server.Requests $before
        Assert-True (-not [IO.File]::Exists((Join-Path $operationsRoot 'preview-download.txt')))
    }
    Test-Case 'TCP readiness succeeds on listening port' {
        Assert-Succeeded (Invoke-TestStep http.wait-tcp @{HostName='127.0.0.1';Port=$server.Port;TimeoutSeconds=2})
    }
} finally { $server.Dispose() }
Test-Case 'TCP readiness timeout is bounded on closed port' {
    $timer=[Diagnostics.Stopwatch]::StartNew()
    $result=Invoke-TestStep http.wait-tcp @{HostName='127.0.0.1';Port=$server.Port;TimeoutSeconds=1;IntervalMilliseconds=10}
    Assert-Equal $result.Status 'Failed'; Assert-True ($timer.Elapsed.TotalSeconds -lt 3)
}
Test-Case 'Git adapters clone fetch and checkout a real isolated local repository' {
    $source=Join-Path $operationsRoot 'source repository'; $null=[IO.Directory]::CreateDirectory($source)
    foreach ($arguments in @(@('init','--initial-branch=main'),@('-c','user.name=Fixture','-c','user.email=fixture@example.invalid','commit','--allow-empty','-m','fixture'))) {
        Assert-Succeeded (Invoke-TestStep process.run @{FilePath='git';WorkingDirectory=$source;Arguments=$arguments})
    }
    $target=Join-Path $operationsRoot 'cloned repository'
    Assert-Succeeded (Invoke-TestStep git.clone @{Repository=$source;Destination=$target;Branch='main'})
    Assert-Succeeded (Invoke-TestStep git.fetch @{Directory=$target})
    Assert-Succeeded (Invoke-TestStep git.checkout @{Directory=$target;Ref='HEAD'})
    [IO.File]::WriteAllText((Join-Path $target 'untracked.txt'),'retain')
    $result=Invoke-TestStep git.checkout @{Directory=$target;Ref='HEAD'}
    Assert-Equal $result.Status 'Failed'; Assert-True ($result.Steps[0].Error -like '*clean worktree*')
    Assert-Equal (Invoke-TestStep git.clone @{Repository=$source;Destination=$target}).Status 'Failed'
    Assert-Equal (Invoke-TestStep git.fetch @{Directory=$target;Remote='--all'}).Status 'Failed'
}
Test-Case 'Adapters use only their declared process dependency and preserve argument boundaries' {
    $module=New-Module -ScriptBlock {
        function Invoke-FixtureProcess { param($Settings,$Context) [pscustomobject]@{Settings=$Settings;Work=$Context.WorkDirectory} }
        Export-ModuleMember Invoke-FixtureProcess
    }
    $dependency=[pscustomobject]@{Command=$module.ExportedFunctions['Invoke-FixtureProcess'];Defaults=@{SuccessExitCodes=@(0)}}
    $context=[pscustomobject]@{WorkDirectory=$operationsRoot;Dependencies=@{'process.run'=$dependency}}
    $project=Join-Path $operationsRoot 'sample.csproj'; [IO.File]::WriteAllText($project,'<Project />')
    foreach ($case in @(
        @{Step='build.dotnet';With=@{Project=$project;Command='build';Arguments=@('-p:Label=two words')};Expected=@('build',$project,'-p:Label=two words');Executable='dotnet'},
        @{Step='build.nuget';With=@{Command='push';Arguments=@('artifact package.nupkg','--source','local-feed')};Expected=@('nuget','push','artifact package.nupkg','--source','local-feed');Executable='dotnet'},
        @{Step='docker.cli';With=@{Command='network-create';Arguments=@('test network')};Expected=@('network','create','test network');Executable='docker'},
        @{Step='docker.cli';With=@{Command='build';Arguments=@('--tag','example:test','.')};Expected=@('build','--tag','example:test','.');Executable='docker'}
    )) {
        $plan=Get-PlotPlan $registry (New-Config @(@{Step=$case.Step;With=$case.With})) demo
        $actual=& $plan[0].Step.Command -Settings $plan[0].Settings -Context $context
        Assert-Equal $actual.Settings.FilePath $case.Executable
        Assert-Equal ($actual.Settings.Arguments | ConvertTo-Json -Compress) ($case.Expected | ConvertTo-Json -Compress)
        Assert-Equal $actual.Settings.TimeoutSeconds 300
        Assert-Equal $actual.Settings.SuccessExitCodes[0] 0
    }
    foreach ($package in @('Git','Build','Docker')) {
        $folder=Join-Path $operationsRoot ('isolated-'+$package); $null=[IO.Directory]::CreateDirectory($folder)
        Copy-Item -LiteralPath (Join-Path $scriptsPath ('Auto/'+$package)) -Destination $folder -Recurse
        Assert-Throws { New-PlotRegistry $folder } '*requires missing package*'
        Copy-Item -LiteralPath (Join-Path $scriptsPath 'Auto/Process') -Destination (Join-Path $folder 'renamed-process-directory') -Recurse
        $single=New-PlotRegistry $folder
        try { Assert-Equal $single.Packages.Count 2 } finally { Remove-PlotRegistry $single }
    }
}
Test-Case 'Direct adapter WhatIf never invokes the process dependency' {
    $context=[pscustomobject]@{WorkDirectory=$operationsRoot;Dependencies=@{}}
    foreach ($case in @(
        @{Step='git.clone';With=@{Repository='example';Destination='not-cloned'}},
        @{Step='git.fetch';With=@{Directory='.'}},
        @{Step='git.checkout';With=@{Directory='.';Ref='HEAD'}},
        @{Step='build.dotnet';With=@{Project=(Join-Path $operationsRoot 'sample.csproj')}},
        @{Step='build.nuget';With=@{Command='push'}},
        @{Step='docker.cli';With=@{Command='run';Arguments=@('example')}}
    )) {
        $plan=Get-PlotPlan $registry (New-Config @(@{Step=$case.Step;With=$case.With})) demo
        $null=& $plan[0].Step.Command -Settings $plan[0].Settings -Context $context -WhatIf
    }
}

Test-Case 'Operational examples resolve their configuration without tools or network' {
    $config=Read-PlotConfiguration (Join-Path $scriptsPath 'Examples/operations.json')
    foreach ($name in $config.Plots.Keys) {
        $plan=Get-PlotPlan $registry $config $name
        Assert-True ($plan.Count -gt 0)
        Assert-Equal (Invoke-Plot $registry $config $name -WhatIf).Status 'Skipped'
    }
}
if ($PSVersionTable.PSVersion.Major -ge 6) {
    Test-Case 'Pre-DateKind JSON fallback preserves strings arrays and null' {
        $fixture=New-Module -ArgumentList (Join-Path $scriptsPath 'Core/JsonText.ps1') -ScriptBlock {
            param($HelperPath)
            . $HelperPath
            function Get-Command { param($Name) [pscustomobject]@{Parameters=@{}} }
            Export-ModuleMember ConvertFrom-PlotJsonText
        }
        $value=& $fixture.ExportedFunctions['ConvertFrom-PlotJsonText'] '{"stamp":"2026-09-16T10:20:30+05:00","list":[null,false,"x"],"empty":[]}'
        Assert-Equal $value.stamp '2026-09-16T10:20:30+05:00'
        Assert-Equal $value.list.Count 3
        Assert-True ($null -eq $value.list[0])
        Assert-Equal $value.list[1] $false
        Assert-Equal $value.empty.Count 0
    }
}
