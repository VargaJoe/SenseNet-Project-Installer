#requires -Version 5.1
[CmdletBinding()]
param()
$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest
$repoRoot = Split-Path $PSScriptRoot -Parent
$scriptsPath = Join-Path $repoRoot 'src/Deployment/Scripts'
Import-Module (Join-Path $scriptsPath 'Core/PlotManager.psm1') -Force
$testRoot = Join-Path ([IO.Path]::GetTempPath()) ('plot-manager-tests-' + [guid]::NewGuid().ToString('N'))
$null = [IO.Directory]::CreateDirectory($testRoot)
$results = [Collections.Generic.List[object]]::new()
$registry = $null
function Assert-Equal($Actual, $Expected) { if ($Actual -cne $Expected) { throw "Expected '$Expected', got '$Actual'." } }
function Assert-True($Actual) { if (-not $Actual) { throw 'Assertion failed.' } }
function Assert-Throws([scriptblock]$Action, [string]$Pattern) {
    $caught = $null
    try { & $Action | Out-Null } catch { $caught = $_.Exception.Message }
    if ($null -eq $caught -or $caught -notlike $Pattern) { throw "Expected error '$Pattern'; got '$caught'." }
}
function Test-Case([string]$Name, [scriptblock]$Action) {
    try { & $Action; $results.Add([pscustomobject]@{ Test=$Name; Status='PASS'; Error=$null }) }
    catch { $results.Add([pscustomobject]@{ Test=$Name; Status='FAIL'; Error=$_.Exception.Message }) }
}
function New-Config($Invocations) { return @{ Plots=@{ demo=@{ Steps=@($Invocations) } } } }
function New-TestPackage([string]$Root, [string]$Directory, [string]$Name, [string]$Alias = '', [string]$Dependencies = '@()') {
    $folder = Join-Path $Root $Directory
    $null = [IO.Directory]::CreateDirectory($folder)
    # Both packages deliberately export the same PowerShell function name.
    $manifest = '@{ Name=''NAME''; Version=''1.0.0''; RootModule=''Fixture.DIRECTORY.psm1''; Dependencies=DEPENDENCIES; Steps=@{ echo=@{ Command=''Invoke-Fixture''; Aliases=@(''ALIAS''); Parameters=@{Value=@{Type=''object'';Required=$true}; Fail=@{Type=''bool'';Default=$false}; Token=@{Type=''string'';Default='''';Secret=$true}} } } }'
    $manifest = $manifest.Replace('NAME',$Name).Replace('DIRECTORY',$Directory).Replace('DEPENDENCIES',$Dependencies).Replace('ALIAS',$Alias)
    if ($Alias -eq '') { $manifest = $manifest.Replace("Aliases=@(''); ", '') }
    $manifest | Set-Content -LiteralPath (Join-Path $folder 'package.psd1') -Encoding utf8
    $module = @'
function Invoke-Fixture {
    [CmdletBinding()]
    param([hashtable]$Settings, $Context)
    if ($Settings.Fail) { throw ("Fixture failure " + $Settings.Token) }
    $Settings.Value.Nested = 'changed in step'
    [pscustomobject]@{ Package='PACKAGE_NAME'; Value=$Settings.Value; Invocation=$Context.InvocationId }
}
Export-ModuleMember -Function Invoke-Fixture
'@
    $module.Replace('PACKAGE_NAME', $Name) | Set-Content -LiteralPath (Join-Path $folder "Fixture.$Directory.psm1") -Encoding utf8
    return $folder
}
try {
    Test-Case 'All PowerShell files parse' {
        $issues = @()
        foreach ($file in Get-ChildItem -LiteralPath $scriptsPath -Recurse -File | Where-Object Extension -in '.ps1','.psm1','.psd1') {
            $tokens=$null; $errors=$null
            $null = [Management.Automation.Language.Parser]::ParseFile($file.FullName,[ref]$tokens,[ref]$errors)
            foreach ($e in $errors) { $issues += "$($file.Name):$($e.Extent.StartLineNumber) $($e.Message)" }
        }
        if ($issues.Count) { throw ($issues -join '; ') }
    }
    Test-Case 'Deep merge copies input and retains false, zero, null and arrays' {
        $base = @{Nested=@{Keep=1; Change=2}; Array=@(1,2); Enabled=$true; Number=1; Value='x'}
        $merged = Merge-PlotSettings -Layers @($base, @{Nested=@{Change=3};Array=@(4);Enabled=$false;Number=0;Value=$null})
        Assert-Equal $merged.Nested.Keep 1
        Assert-Equal $merged.Nested.Change 3
        Assert-Equal $merged.Array.Count 1
        Assert-Equal $merged.Array[0] 4
        Assert-Equal $merged.Enabled $false
        Assert-Equal $merged.Number 0
        Assert-True ($null -eq $merged.Value)
        $merged.Nested.Keep = 99
        Assert-Equal $base.Nested.Keep 1
        $merged = Merge-PlotSettings -Layers @(('{"Nested":{"Keep":1}}' | ConvertFrom-Json), @{Nested=@{New=2}})
        Assert-Equal $merged.Nested.Keep 1
    }
    $registry = New-PlotRegistry -AutoPath (Join-Path $scriptsPath 'Auto')
    Test-Case 'Registry exposes canonical IDs and aliases' {
        Assert-Equal $registry.Steps.Count 26
        Assert-Equal $registry.Names['System-Start'].Id 'iis.start'
    }
    Test-Case 'Two packages and repeated invocations execute with output references' {
        $work = Join-Path $testRoot 'compose'
        $null = [IO.Directory]::CreateDirectory($work)
        $config = Read-PlotConfiguration (Join-Path $scriptsPath 'Examples/compose-files.json')
        $result = Invoke-Plot $registry $config 'compose-files' -WorkDirectory $work
        Assert-Equal $result.Status 'Succeeded'
        Assert-Equal $result.Steps.Count 4
        Assert-Equal ([IO.File]::ReadAllText((Join-Path $work 'greeting.txt'))) 'Hello, operator'
        Assert-Equal ([IO.File]::ReadAllText((Join-Path $work 'farewell.txt'))) 'Goodbye, operator'
        Assert-Equal $config.Message.Recipient 'operator'
    }
    Test-Case 'WhatIf skips operations and dependent steps' {
        $work = Join-Path $testRoot 'whatif'
        $null = [IO.Directory]::CreateDirectory($work)
        $config = Read-PlotConfiguration (Join-Path $scriptsPath 'Examples/compose-files.json')
        $result = Invoke-Plot $registry $config 'compose-files' -WorkDirectory $work -WhatIf
        Assert-Equal $result.Status 'Skipped'
        Assert-Equal @(Get-ChildItem -LiteralPath $work).Count 0
        Assert-Equal @($result.Steps | Where-Object Status -ne 'Skipped').Count 0
    }
    Test-Case 'Later unknown step fails preflight before earlier file write' {
        $path = Join-Path $testRoot 'should-not-exist.txt'
        $config = New-Config @(@{Step='filesystem.write';With=@{Path=$path}}, @{Step='missing.step'})
        Assert-Throws { Invoke-Plot $registry $config demo } "*not installed*"
        Assert-True (-not (Test-Path -LiteralPath $path))
    }
    Test-Case 'Missing parameters, unknown keys and duplicate invocation IDs rejected' {
        Assert-Throws { Get-PlotPlan $registry (New-Config @(@{Step='filesystem.write'})) demo } "*required parameter 'Path'*"
        Assert-Throws { Get-PlotPlan $registry (New-Config @(@{Step='text.join';With=@{Items=@();Typo=1}})) demo } "*unknown parameter 'Typo'*"
        Assert-Throws { Get-PlotPlan $registry (New-Config @(@{Id='same';Step='text.join';With=@{Items=@()}},@{Id='SAME';Step='text.join';With=@{Items=@()}})) demo } '*duplicate invocation*'
    }
    Test-Case 'Missing, forward and unsupported references rejected' {
        Assert-Throws { Get-PlotPlan $registry (New-Config @(@{Step='filesystem.write';With=@{Path=@{'$ref'='settings.missing'}}})) demo } '*cannot be resolved*'
        Assert-Throws { Get-PlotPlan $registry (New-Config @(@{Id='first';Step='filesystem.write';With=@{Path=@{'$ref'='steps.later.Output.Path'}}})) demo } '*earlier invocation*'
        Assert-Throws { Get-PlotPlan $registry (New-Config @(@{Step='filesystem.write';With=@{Path=@{'$ref'='process.command'}}})) demo } '*Unsupported reference*'
    }
    Test-Case 'All parameter layers and invocation-specific overrides' {
        $config = New-Config @(@{Id='join';Step='text.join';Section='Chosen';With=@{Items=@('a','b');Separator='invocation'}})
        $config.Defaults = @{Separator='global'}
        $config.StepDefaults = @{'text.join'=@{Separator='step-config'}}
        $config.Chosen = @{Separator='section'}
        $config.Plots.demo.Defaults = @{Separator='plot'}
        $plan = Get-PlotPlan $registry $config demo -Overrides @{join=@{Separator='override'}}
        Assert-Equal $plan[0].Settings.Separator 'override'
        Assert-Equal $plan[0].Sources.Separator 'override'
        $result = Invoke-Plot $registry $config demo -Overrides @{join=@{Separator='!'}}
        Assert-Equal $result.Steps[0].Output.Text 'a!b'
        Assert-Throws { Get-PlotPlan $registry $config demo -Overrides @{typo=@{Separator='x'}} } '*unknown invocation*'
    }
    Test-Case 'Section shorthand maps to native settings' {
        $config = @{Plots=@{demo=@('text.join:Chosen')}; Chosen=@{Items=@('a','b');Separator='-'}}
        Assert-Equal (Invoke-Plot $registry $config demo).Steps[0].Output.Text 'a-b'
    }
    Test-Case 'Environment references convert false and reject invalid bool' {
        $env:PLOTMANAGER_TEST_BOOL = 'false'
        try {
            $config = New-Config @(@{Step='filesystem.write';With=@{Path=(Join-Path $testRoot 'env.txt');Overwrite=@{'$env'='PLOTMANAGER_TEST_BOOL'}}})
            Assert-Equal (Invoke-Plot $registry $config demo).Status 'Succeeded'
            Assert-Equal (Invoke-Plot $registry $config demo).Status 'Failed'
            $env:PLOTMANAGER_TEST_BOOL = 'definitely'
            Assert-Throws { Get-PlotPlan $registry $config demo } '*must be bool*'
        } finally { Remove-Item Env:PLOTMANAGER_TEST_BOOL }
    }
    Test-Case 'Failure stops subsequent operations' {
        $path = Join-Path $testRoot 'not-written.txt'
        $config = New-Config @(@{Step='filesystem.copy';With=@{Source=(Join-Path $testRoot 'missing');Destination=(Join-Path $testRoot 'copy')}}, @{Step='filesystem.write';With=@{Path=$path}})
        $result = Invoke-Plot $registry $config demo
        Assert-Equal $result.Status 'Failed'
        Assert-Equal $result.Steps.Count 1
        Assert-True (-not (Test-Path -LiteralPath $path))
    }
    Test-Case 'Only the selected Text package is sufficient in another Auto folder' {
        $auto = Join-Path $testRoot 'text-only'
        $null = [IO.Directory]::CreateDirectory($auto)
        Copy-Item -LiteralPath (Join-Path $scriptsPath 'Auto/Text') -Destination $auto -Recurse
        $small = New-PlotRegistry $auto
        try {
            Assert-Equal $small.Packages.Count 1
            Assert-Equal (Invoke-Plot $small (New-Config @(@{Step='text.join';With=@{Items=@('portable','package')}})) demo).Steps[0].Output.Text 'portable package'
        } finally { Remove-PlotRegistry $small }
    }
    Test-Case 'Identically named module functions and invocation settings remain isolated' {
        $auto = Join-Path $testRoot 'isolated'
        $null = New-TestPackage $auto a first
        $null = New-TestPackage $auto b second
        $isolated = New-PlotRegistry $auto
        try {
            $config = New-Config @(@{Id='a';Step='first.echo';With=@{Value=@{Nested='original'}}},@{Id='b';Step='second.echo';With=@{Value=@{Nested='original'}}})
            $result = Invoke-Plot $isolated $config demo
            Assert-Equal $result.Status 'Succeeded'
            Assert-Equal $result.Steps[0].Output.Package 'first'
            Assert-Equal $result.Steps[1].Output.Package 'second'
            Assert-Equal $config.Plots.demo.Steps[0].With.Value.Nested 'original'
        } finally { Remove-PlotRegistry $isolated }
    }
    Test-Case 'Duplicate aliases rejected before either module is imported' {
        $auto = Join-Path $testRoot 'aliases'
        $a = New-TestPackage $auto a first shared
        $null = New-TestPackage $auto b second SHARED
        'throw "Imported before validation"' | Set-Content -LiteralPath (Join-Path $a 'Fixture.a.psm1')
        Assert-Throws { New-PlotRegistry $auto } '*Duplicate step name*'
    }
    Test-Case 'Package and canonical-vs-alias collisions rejected' {
        $auto = Join-Path $testRoot 'package-ids'
        $null = New-TestPackage $auto a first
        $null = New-TestPackage $auto b FIRST
        Assert-Throws { New-PlotRegistry $auto } '*Duplicate package*'
        $auto = Join-Path $testRoot 'canonical-alias'
        $null = New-TestPackage $auto a first second.echo
        $null = New-TestPackage $auto b second
        Assert-Throws { New-PlotRegistry $auto } '*Duplicate step name*'
    }
    Test-Case 'Missing dependency and dependency cycle rejected' {
        $auto = Join-Path $testRoot 'missing-dependency'
        $null = New-TestPackage $auto a first '' "@('missing')"
        Assert-Throws { New-PlotRegistry $auto } '*requires missing package*'
        $auto = Join-Path $testRoot 'cycle'
        $null = New-TestPackage $auto a first '' "@('second')"
        $null = New-TestPackage $auto b second '' "@('first')"
        Assert-Throws { New-PlotRegistry $auto } '*dependency cycle*'
    }
    Test-Case 'Valid dependencies load' {
        $auto = Join-Path $testRoot 'dependencies'
        $null = New-TestPackage $auto a first '' "@('second')"
        $null = New-TestPackage $auto b second
        $dependent = New-PlotRegistry $auto
        try { Assert-Equal $dependent.Packages.Count 2 } finally { Remove-PlotRegistry $dependent }
    }
    Test-Case 'Missing export and escaping module paths rejected' {
        $auto = Join-Path $testRoot 'bad-export'
        $folder = New-TestPackage $auto a first
        'Export-ModuleMember -Function @()' | Set-Content -LiteralPath (Join-Path $folder 'Fixture.a.psm1')
        Assert-Throws { New-PlotRegistry $auto } '*exports no function*'
        $path = Join-Path $folder 'package.psd1'
        (Get-Content -LiteralPath $path -Raw).Replace("RootModule='Fixture.a.psm1'", "RootModule='../elsewhere.psm1'") | Set-Content -LiteralPath $path
        Assert-Throws { New-PlotRegistry $auto } '*escapes its package*'
    }
    Test-Case 'Secret parameters are redacted from failure results' {
        $auto = Join-Path $testRoot 'secret'
        $null = New-TestPackage $auto a first
        $secretRegistry = New-PlotRegistry $auto
        try {
            $result = Invoke-Plot $secretRegistry (New-Config @(@{Step='first.echo';With=@{Value=@{};Fail=$true;Token='synthetic-test-secret'}})) demo
            Assert-Equal $result.Status 'Failed'
            Assert-True ($result.Steps[0].Error.Contains('[redacted]'))
            Assert-True (-not $result.Steps[0].Error.Contains('synthetic-test-secret'))
        } finally { Remove-PlotRegistry $secretRegistry }
    }
    Test-Case 'IIS mock transitions reread states and use correct order' {
        $iis = $registry.Packages.iis.Module
        & $iis {
            $script:fake = @{Site='Stopped';Pool='Stopped';Calls=[Collections.Generic.List[string]]::new()}
            function script:Import-Module { [CmdletBinding()]param($Name) }
            function script:Get-Website { [CmdletBinding()]param($Name) [pscustomobject]@{Name=$Name;State=$script:fake.Site} }
            function script:Get-WebAppPoolState { [CmdletBinding()]param($Name) [pscustomobject]@{Name=$Name;Value=$script:fake.Pool} }
            function script:Start-Website { [CmdletBinding()]param($Name) $script:fake.Site='Started';$script:fake.Calls.Add('start-site') }
            function script:Stop-Website { [CmdletBinding()]param($Name) $script:fake.Site='Stopped';$script:fake.Calls.Add('stop-site') }
            function script:Start-WebAppPool { [CmdletBinding()]param($Name) $script:fake.Pool='Started';$script:fake.Calls.Add('start-pool') }
            function script:Stop-WebAppPool { [CmdletBinding()]param($Name) $script:fake.Pool='Stopped';$script:fake.Calls.Add('stop-pool') }
        }
        $result = Invoke-Plot $registry (New-Config @(@{Step='iis.start';With=@{WebsiteName='demo'}},@{Step='iis.stop';With=@{WebsiteName='demo'}})) demo
        Assert-Equal $result.Status 'Succeeded'
        Assert-Equal (& $iis { $script:fake.Calls -join ',' }) 'start-pool,start-site,stop-site,stop-pool'
    }
    Test-Case 'Direct IIS WhatIf performs no operations' {
        $iis = $registry.Packages.iis.Module
        & $iis { $script:fake.Calls.Clear() }
        & $registry.Steps['iis.start'].Command -Settings @{WebsiteName='demo'} -Context @{} -WhatIf
        Assert-Equal (& $iis { $script:fake.Calls.Count }) 0
    }
    Test-Case 'Missing IIS website fails explicitly' {
        $iis = $registry.Packages.iis.Module
        & $iis { function script:Get-Website { [CmdletBinding()]param($Name) return $null } }
        $result = Invoke-Plot $registry (New-Config @(@{Step='iis.start';With=@{WebsiteName='missing'}})) demo
        Assert-Equal $result.Status 'Failed'
        Assert-True ($result.Steps[0].Error -like '*does not exist*')
    }
    Test-Case 'Reference objects replace maps and maps replace references' {
        $merged = Merge-PlotSettings -Layers @(@{Value=@{'$ref'='settings.Old'}}, @{Value=@{Nested=2}})
        Assert-True (-not $merged.Value.ContainsKey('$ref'))
        Assert-Equal $merged.Value.Nested 2
        $merged = Merge-PlotSettings -Layers @(@{Value=@{Nested=2}}, @{Value=@{'$ref'='settings.New'}})
        Assert-Equal $merged.Value.Count 1
        Assert-Equal $merged.Value['$ref'] 'settings.New'
    }
    Test-Case 'Nested source labels preserve fallback fields' {
        $auto = Join-Path $testRoot 'sources'
        $null = New-TestPackage $auto a source
        $sourceRegistry = New-PlotRegistry $auto
        try {
            $config = New-Config @(@{Id='probe';Step='source.echo';With=@{Value=@{Changed=2}}})
            $config.Defaults = @{Value=@{Keep=1;Changed=1}}
            $plan = Get-PlotPlan $sourceRegistry $config demo
            Assert-Equal $plan[0].Sources['Value.Keep'] 'configuration default'
            Assert-Equal $plan[0].Sources['Value.Changed'] 'invocation'
            $config.Plots.demo.Steps[0].With.Value = @{}
            $plan = Get-PlotPlan $sourceRegistry $config demo
            Assert-Equal $plan[0].Sources['Value.Keep'] 'configuration default'
            Assert-Equal $plan[0].Sources['Value.Changed'] 'configuration default'
        } finally { Remove-PlotRegistry $sourceRegistry }
    }
    Test-Case 'Same module basenames in different package folders remain isolated' {
        $auto = Join-Path $testRoot 'same-basename'
        $a = New-TestPackage $auto a first
        $b = New-TestPackage $auto b second
        foreach ($pair in @(@($a,'a'),@($b,'b'))) {
            $manifestPath = Join-Path $pair[0] 'package.psd1'
            (Get-Content -LiteralPath $manifestPath -Raw).Replace("Fixture.$($pair[1]).psm1",'Package.psm1') | Set-Content -LiteralPath $manifestPath
            Copy-Item -LiteralPath (Join-Path $pair[0] "Fixture.$($pair[1]).psm1") -Destination (Join-Path $pair[0] 'Package.psm1')
        }
        $same = New-PlotRegistry $auto
        try {
            $result = Invoke-Plot $same (New-Config @(@{Step='first.echo';With=@{Value=@{}}},@{Step='second.echo';With=@{Value=@{}}})) demo
            Assert-Equal $result.Status 'Succeeded'
            Assert-Equal $result.Steps[0].Output.Package 'first'
            Assert-Equal $result.Steps[1].Output.Package 'second'
        } finally { Remove-PlotRegistry $same }
    }
    Test-Case 'Missing environment reference and invalid package platform rejected' {
        $config = New-Config @(@{Step='filesystem.write';With=@{Path=@{'$env'='PLOTMANAGER_TEST_ABSENT_43DA221'}}})
        Assert-Throws { Get-PlotPlan $registry $config demo } '*Environment variable*missing*'
        $auto = Join-Path $testRoot 'platform'
        $folder = New-TestPackage $auto a first
        $manifest = Join-Path $folder 'package.psd1'
        (Get-Content -LiteralPath $manifest -Raw).Replace("Version='1.0.0';","Version='1.0.0'; Platform='typo';") | Set-Content -LiteralPath $manifest
        Assert-Throws { New-PlotRegistry $auto } '*Unsupported Platform*'
    }
    Test-Case 'Invalid later static parameter prevents earlier operation' {
        $path = Join-Path $testRoot 'no-early-write.txt'
        $config = New-Config @(@{Step='filesystem.write';With=@{Path=$path}},@{Step='text.join';With=@{Items='not-an-array'}})
        Assert-Throws { Invoke-Plot $registry $config demo } '*must be array*'
        Assert-True (-not (Test-Path -LiteralPath $path))
    }
    Test-Case 'IIS timeout is bounded and reports the target' {
        $iis = $registry.Packages.iis.Module
        & $iis {
            function script:Get-Website { [CmdletBinding()]param($Name) [pscustomobject]@{Name=$Name;State='Stopped'} }
            function script:Get-WebAppPoolState { [CmdletBinding()]param($Name) [pscustomobject]@{Name=$Name;Value='Stopped'} }
        }
        $timer = [Diagnostics.Stopwatch]::StartNew()
        $result = Invoke-Plot $registry (New-Config @(@{Step='iis.start';With=@{WebsiteName='timeout-demo';TimeoutSeconds=1;PollMilliseconds=5}})) demo
        $timer.Stop()
        Assert-Equal $result.Status 'Failed'
        Assert-True ($result.Steps[0].Error -like "*Timeout*pool 'timeout-demo'*")
        Assert-True ($timer.Elapsed.TotalSeconds -lt 5)
    }
    Test-Case 'Legacy env override recognizes false' {
        $tokens=$null; $errors=$null
        $ast = [Management.Automation.Language.Parser]::ParseFile((Join-Path $scriptsPath 'AutoExt/init-functions.ps1'),[ref]$tokens,[ref]$errors)
        $fn = $ast.Find({param($n) $n -is [Management.Automation.Language.FunctionDefinitionAst] -and $n.Name -eq 'Set-Environments'},$true)
        . ([scriptblock]::Create($fn.Extent.Text))
        $env:PLOTMANAGER_TestFalse = 'true'
        try {
            $updated = Set-Environments -prior ([pscustomobject]@{Project=[pscustomobject]@{TestFalse=$false}}) -sctn Project
            Assert-Equal $updated.Project.TestFalse 'true'
        } finally { Remove-Item Env:PLOTMANAGER_TestFalse }
    }
    Test-Case 'CLI returns JSON success with real temporary files' {
        $work = Join-Path $testRoot 'cli'
        $null = [IO.Directory]::CreateDirectory($work)
        $output = & (Get-Process -Id $PID).Path -NoProfile -NonInteractive -File (Join-Path $scriptsPath 'Run.ps1') compose-files -ConfigPath (Join-Path $scriptsPath 'Examples/compose-files.json') -WorkDirectory $work
        Assert-Equal $LASTEXITCODE 0
        Assert-Equal (($output -join [Environment]::NewLine)|ConvertFrom-Json).Status 'Succeeded'
        Assert-True (Test-Path -LiteralPath (Join-Path $work 'greeting.txt'))
    }
    Test-Case 'CLI returns nonzero exit and JSON failure on existing files' {
        $output = & (Get-Process -Id $PID).Path -NoProfile -NonInteractive -File (Join-Path $scriptsPath 'Run.ps1') compose-files -ConfigPath (Join-Path $scriptsPath 'Examples/compose-files.json') -WorkDirectory (Join-Path $testRoot 'cli')
        Assert-Equal $LASTEXITCODE 1
        Assert-Equal (($output -join [Environment]::NewLine)|ConvertFrom-Json).Status 'Failed'
    }
    Test-Case 'Legacy help lists historical steps without running them' {
        $output = & (Get-Process -Id $PID).Path -NoProfile -NonInteractive -File (Join-Path $scriptsPath 'Run.ps1') -Legacy -Help steps
        Assert-Equal $LASTEXITCODE 0
        Assert-True (($output -join ' ') -like '*backupdb*')
    }
    . (Join-Path $PSScriptRoot 'Configuration.Tests.ps1')
    . (Join-Path $PSScriptRoot 'GenericPackages.Tests.ps1')
    . (Join-Path $PSScriptRoot 'Operations.Tests.ps1')
    . (Join-Path $PSScriptRoot 'References.Tests.ps1')
} finally {
    if ($null -ne $registry) { Remove-PlotRegistry $registry }
    $resolved = [IO.Path]::GetFullPath($testRoot)
    $tempRoot = [IO.Path]::GetFullPath([IO.Path]::GetTempPath()).TrimEnd('\','/') + [IO.Path]::DirectorySeparatorChar
    if (-not $resolved.StartsWith($tempRoot,[StringComparison]::OrdinalIgnoreCase) -or (Split-Path $resolved -Leaf) -notlike 'plot-manager-tests-*') { throw "Refusing unsafe test cleanup: $resolved" }
    Remove-Item -LiteralPath $resolved -Recurse -Force
}
$results | Format-Table -AutoSize -Wrap
$failed = @($results | Where-Object Status -eq 'FAIL')
Write-Output "PowerShell $($PSVersionTable.PSVersion): $($results.Count - $failed.Count)/$($results.Count) tests passed."
if ($failed.Count) { exit 1 }
exit 0
