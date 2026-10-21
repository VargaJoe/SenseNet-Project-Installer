# Recursive configuration references; previous step outputs remain terminal data.
$referenceRoot=Join-Path $testRoot 'references'
$null=[IO.Directory]::CreateDirectory($referenceRoot)
Test-Case 'CLI resolves indirect environment values through layered settings' {
    $variable='PLOT_REFERENCE_'+[guid]::NewGuid().ToString('N')
    [Environment]::SetEnvironmentVariable($variable,'resolved-value')
    try {
        $baseline=Join-Path $referenceRoot 'default.json'; $overlay=Join-Path $referenceRoot 'environment.json'
        $config=New-Config @(@{Step='filesystem.write';With=@{Path='env.txt';Content=@{'$ref'='settings.Values.Message'}}})
        $config.Values=@{Message='baseline'}
        Write-TestJson $baseline $config
        Write-TestJson $overlay @{Values=@{Message=@{'$env'=$variable}}}
        $cli=Invoke-TestCli @('demo','-DefaultConfigPath',$baseline,'-EnvironmentConfigPath',$overlay,'-WorkDirectory',$referenceRoot)
        Assert-Equal $cli.Code 0
        Assert-Equal ([IO.File]::ReadAllText((Join-Path $referenceRoot 'env.txt'))) 'resolved-value'
    } finally { [Environment]::SetEnvironmentVariable($variable,$null) }
}
Test-Case 'References resolve nested maps arrays null false zero and repeated siblings without mutation' {
    $config=New-Config @(@{Step='json.write';With=@{Path='values.json';Value=@{'$ref'='settings.Values.Report'}}})
    $config.Values=@{
        Name='shared'; Empty=@(); Nil=$null; Disabled=$false; Zero=0
        Report=@{First=@{'$ref'='settings.Values.Name'};Second=@{'$ref'='settings.Values.Name'}
            Nested=@{Items=@(@{'$ref'='settings.Values.Disabled'},@{'$ref'='settings.Values.Zero'},@{'$ref'='settings.Values.Nil'})}
            Empty=@{'$ref'='settings.Values.Empty'}}
    }
    Assert-Succeeded (Invoke-Plot $registry $config demo -WorkDirectory $referenceRoot)
    $value=Read-PlotConfiguration (Join-Path $referenceRoot 'values.json')
    Assert-Equal $value.First 'shared'; Assert-Equal $value.Second 'shared'
    Assert-Equal $value.Nested.Items.Count 3
    Assert-Equal $value.Nested.Items[0] $false; Assert-Equal $value.Nested.Items[1] 0
    Assert-True ($null -eq $value.Nested.Items[2]); Assert-Equal $value.Empty.Count 0
    Assert-Equal $config.Values.Report.First['$ref'] 'settings.Values.Name'
}
Test-Case 'Long acyclic reference chains resolve while excessive expansion fails clearly' {
    $config=New-Config @(@{Step='filesystem.write';With=@{Path='chain.txt';Content=@{'$ref'='settings.Values.Key0'}}})
    $config.Values=@{Key63='chain-value'}
    for ($i=0;$i -lt 63;$i++) { $config.Values['Key'+$i]=@{'$ref'=('settings.Values.Key'+($i+1))} }
    Assert-Succeeded (Invoke-Plot $registry $config demo -WorkDirectory $referenceRoot)
    Assert-Equal ([IO.File]::ReadAllText((Join-Path $referenceRoot 'chain.txt'))) 'chain-value'
    $config.Values.Key63=@{'$ref'='settings.Values.Key64'}; $config.Values.Key64='too-deep'
    Assert-Throws { Get-PlotPlan $registry $config demo } '*limit of 64*'
}
function Assert-ReferencePreflightFailure($Values,$Reference,[string]$Pattern) {
    $marker=Join-Path $referenceRoot ('forbidden-'+[guid]::NewGuid().ToString('N'))
    $config=New-Config @(@{Step='filesystem.write';With=@{Path=$marker;Content='must not run'}},
        @{Step='filesystem.write';With=@{Path='unreachable.txt';Content=@{'$ref'=$Reference}}})
    $config.Values=$Values
    Assert-Throws { Invoke-Plot $registry $config demo -WorkDirectory $referenceRoot } $Pattern
    Assert-True (-not [IO.File]::Exists($marker))
}
Test-Case 'Self mutual mixed-case and object-contained cycles fail before any operation' {
    foreach ($values in @(
        @{A=@{'$ref'='settings.Values.A'}},
        @{A=@{'$ref'='settings.Values.B'};B=@{'$ref'='SETTINGS.values.a'}},
        @{A=@{Nested=@{'$ref'='settings.Values.A'}}}
    )) { Assert-ReferencePreflightFailure $values 'settings.Values.A' '*Circular settings reference*' }
}
Test-Case 'Missing indirect environment and settings values fail before earlier writes' {
    Assert-ReferencePreflightFailure @{A=@{'$env'= ('PLOT_MISSING_'+[guid]::NewGuid().ToString('N'))}} 'settings.Values.A' '*Environment variable*missing*'
    Assert-ReferencePreflightFailure @{A=@{'$ref'='settings.Values.Absent'}} 'settings.Values.A' '*cannot be resolved*'
}
Test-Case 'Indirect invalid scalar types and malformed directives fail during preflight' {
    Assert-ReferencePreflightFailure @{A=@{'$ref'='settings.Values.B'};B=42} 'settings.Values.A' '*must be string*'
    Assert-ReferencePreflightFailure @{A=@{'$ref'='settings.Values.B';Extra='invalid'};B='value'} 'settings.Values.A' '*only a string $ref*'
    Assert-ReferencePreflightFailure @{A=@{'$env'='missing';Extra='invalid'}} 'settings.Values.A' '*only a string $env*'
}
Test-Case 'Settings aliases defer earlier output references and preserve case-insensitive paths' {
    $config=New-Config @(
        @{Id='produce';Step='text.join';With=@{Items=@('earlier','output');Separator='-'}},
        @{Id='save';Step='filesystem.write';With=@{Path='deferred.txt';Content=@{'$ref'='settings.Values.A'}}})
    $config.Values=@{A=@{'$ref'='settings.Values.B'};B=@{'$ref'='STEPS.PRODUCE.Output.Text'}}
    $plan=Get-PlotPlan $registry $config demo
    Assert-Equal $plan[1].Settings.Content['$ref'] 'STEPS.PRODUCE.Output.Text'
    Assert-Succeeded (Invoke-Plot $registry $config demo -WorkDirectory $referenceRoot)
    Assert-Equal ([IO.File]::ReadAllText((Join-Path $referenceRoot 'deferred.txt'))) 'earlier-output'
}
Test-Case 'Indirect forward and self output references are rejected before execution' {
    foreach ($path in @('steps.later.Output.Text','STEPS.step2.Output.Text')) {
        Assert-ReferencePreflightFailure @{A=@{'$ref'=$path}} 'settings.Values.A' '*earlier invocation*'
    }
}
Test-Case 'Missing deferred output properties fail at the consumer and stop subsequent steps' {
    $marker=Join-Path $referenceRoot 'after-failed-output.txt'
    $config=New-Config @(
        @{Id='produce';Step='text.join';With=@{Items=@('done')}},
        @{Id='consume';Step='filesystem.write';With=@{Path='never.txt';Content=@{'$ref'='settings.Values.A'}}},
        @{Step='filesystem.write';With=@{Path=$marker}})
    $config.Values=@{A=@{'$ref'='steps.produce.Output.Absent'}}
    $result=Invoke-Plot $registry $config demo -WorkDirectory $referenceRoot
    Assert-Equal $result.Status 'Failed'; Assert-Equal $result.Steps.Count 2
    Assert-Equal $result.Steps[0].Status 'Succeeded'; Assert-Equal $result.Steps[1].Id 'consume'
    Assert-True ($result.Steps[1].Error -like '*cannot be resolved*')
    Assert-True (-not [IO.File]::Exists($marker))
}
Test-Case 'Step output containing directive-shaped JSON stays literal data through settings aliases' {
    foreach ($directive in @('$env','$ref')) {
        $source=Join-Path $referenceRoot ('literal-'+$directive.Substring(1)+'.json')
        $destination=$source+'.copy'
        Write-TestJson $source @{$directive='must-stay-literal'}
        $config=New-Config @(
            @{Id='read';Step='json.read';With=@{Path=$source}},
            @{Step='json.write';With=@{Path=$destination;Value=@{'$ref'='settings.Values.A'}}})
        $config.Values=@{A=@{'$ref'='steps.read.Output.Value'}}
        Assert-Succeeded (Invoke-Plot $registry $config demo -WorkDirectory $referenceRoot)
        Assert-Equal (Read-PlotConfiguration $destination)[$directive] 'must-stay-literal'
    }
}
