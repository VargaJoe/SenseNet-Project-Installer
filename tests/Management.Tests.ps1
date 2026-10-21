# Runs within the common isolated test harness on Windows PowerShell 5.1 and PowerShell 7.
Import-Module (Join-Path $scriptsPath 'Core/PlotManagement.psm1') -Force
$managementRoot=Join-Path $testRoot 'management'
$null=[IO.Directory]::CreateDirectory($managementRoot)
$managedDefault=Join-Path $managementRoot 'default.json'
$managedProject=Join-Path $managementRoot 'project.json'
$managedEnvironment=Join-Path $managementRoot 'environment.json'
$managedConfig=@{
    Message=@{Keep=1;Value='default';Nullable='value';Enabled=$true;Number=1;Items=@(1,2)}
    Unknown=@{Preserved='extension'}
    Plots=@{demo=@{Steps=@(
        @{Id='first';Step='text.join';With=@{Items=@('hello','world');Separator=@{'$ref'='settings.Message.Value'}}}
        @{Id='second';Step='filesystem.write';With=@{Path='result.txt';Content=@{'$ref'='steps.first.Output.Text'}}}
    )}}
}
$managedConfig | ConvertTo-Json -Depth 20 | Set-Content -LiteralPath $managedDefault -Encoding utf8
@{Message=@{Value='project';Nullable=$null;Enabled=$false;Number=0;Items=@()}} | ConvertTo-Json -Depth 10 | Set-Content -LiteralPath $managedProject -Encoding utf8
@{Message=@{Value='!'}} | ConvertTo-Json -Depth 10 | Set-Content -LiteralPath $managedEnvironment -Encoding utf8
$managedFiles=@($managedDefault,$managedProject,$managedEnvironment)

Test-Case 'Management inspector shares engine merge while retaining raw layers, types and exact files' {
    $info=Invoke-ManagedPlotRequest @{Operation='inspect';ConfigurationFiles=$managedFiles}
    Assert-Equal $info.Configuration.Message.Keep 1
    Assert-Equal $info.Configuration.Message.Value '!'
    Assert-True ($null -eq $info.Configuration.Message.Nullable)
    Assert-Equal $info.Configuration.Message.Enabled $false
    Assert-Equal $info.Configuration.Message.Number 0
    Assert-Equal $info.Configuration.Message.Items.Count 0
    Assert-Equal $info.Configuration.Unknown.Preserved 'extension'
    Assert-Equal $info.Sources['Message.Value'] $managedEnvironment
    Assert-Equal $info.Sources['Message.Keep'] $managedDefault
    Assert-Equal $info.Layers[0].Data.Message.Value 'default'
    Assert-Equal $info.Layers[1].Data.Message.Value 'project'
    $cli=Read-PlotConfiguration $managedFiles
    Assert-Equal $cli.Message.Value $info.Configuration.Message.Value
}
Test-Case 'Managed plan reports invocation and schema-default origins, resolved types and immutable configuration' {
    $plan=Invoke-ManagedPlotRequest @{Operation='plan';ConfigurationFiles=$managedFiles;Plot='demo'}
    Assert-Equal $plan.Steps[0].Settings.Separator '!'
    Assert-Equal $plan.Steps[0].Origins.Separator.Layer 'invocation'
    Assert-Equal $plan.Steps[0].Origins.Separator.File $managedDefault
    Assert-Equal $plan.Steps[0].Origins.Separator.References[0].File $managedEnvironment
    Assert-Equal $plan.Steps[0].Origins.Separator.References[0].Path 'Message.Value'
    Assert-Equal $plan.Steps[1].Origins.Overwrite.Layer 'step default'
    Assert-True ($plan.Steps[1].Origins.Overwrite.File -like '*package.psd1')
    Assert-Equal $plan.Configuration.Message.Value '!'
}
Test-Case 'Managed single invocation runs only selected invocation; output-dependent invocation is rejected' {
    $result=Invoke-ManagedPlotRequest @{Operation='run';ConfigurationFiles=$managedFiles;Plot='demo';InvocationId='first';WorkDirectory=$managementRoot}
    Assert-Equal $result.Status 'Succeeded'
    Assert-Equal $result.Steps.Count 1
    Assert-Equal $result.Steps[0].Output.Text 'hello!world'
    Assert-True (-not (Test-Path -LiteralPath (Join-Path $managementRoot 'result.txt')))
    Assert-Throws { Invoke-ManagedPlotRequest @{Operation='run';ConfigurationFiles=$managedFiles;Plot='demo';InvocationId='second';WorkDirectory=$managementRoot} } '*earlier outputs*'
}
Test-Case 'Management events describe real step lifetime and do not include settings or outputs' {
    $events=[Collections.Generic.List[object]]::new()
    $callback={param($event) $events.Add($event)}.GetNewClosure()
    $result=Invoke-ManagedPlotRequest @{Operation='run';ConfigurationFiles=$managedFiles;Plot='demo';WorkDirectory=$managementRoot} -OnEvent $callback
    Assert-Equal $result.Status 'Succeeded'
    Assert-Equal $events.Count 4
    Assert-Equal $events[0].Type 'StepStarted'
    Assert-Equal $events[3].Type 'StepCompleted'
    Assert-Equal $events[3].Status 'Succeeded'
    Assert-True (-not (($events | ConvertTo-Json -Depth 8) -like '*hello*'))
    Assert-Equal ([IO.File]::ReadAllText((Join-Path $managementRoot 'result.txt'))) 'hello!world'
}
Test-Case 'Managed preview performs no active operations; reordering and later static errors fail before writes' {
    $result=Invoke-ManagedPlotRequest @{Operation='run';ConfigurationFiles=$managedFiles;Plot='demo';WorkDirectory=$managementRoot;WhatIf=$true}
    Assert-Equal $result.Status 'Skipped'
    $reordered=Copy-PlotValue $managedConfig
    $reordered.Plots.demo.Steps=@($reordered.Plots.demo.Steps[1],$reordered.Plots.demo.Steps[0])
    $file=Join-Path $managementRoot 'invalid.json'
    $reordered | ConvertTo-Json -Depth 20 | Set-Content -LiteralPath $file -Encoding utf8
    Assert-Throws { Invoke-ManagedPlotRequest @{Operation='plan';ConfigurationFiles=@($file);Plot='demo'} } '*earlier invocation*'
    $reordered.Plots.demo.Steps=@(@{Id='write';Step='filesystem.write';With=@{Path='must-not-exist.txt'}},@{Id='later';Step='text.join';With=@{Items='invalid type'}})
    $reordered | ConvertTo-Json -Depth 20 | Set-Content -LiteralPath $file -Encoding utf8
    Assert-Throws { Invoke-ManagedPlotRequest @{Operation='run';ConfigurationFiles=@($file);Plot='demo';WorkDirectory=$managementRoot} } '*must be array*'
    Assert-True (-not (Test-Path -LiteralPath (Join-Path $managementRoot 'must-not-exist.txt')))
}
Test-Case 'Managed worker redacts environment-derived inputs from plans outputs and file responses' {
    $env:PLOTMANAGER_MANAGEMENT_TEST_SECRET='synthetic-management-secret'
    try {
        $config=@{Plots=@{secret=@(@{Id='echo';Step='text.join';With=@{Items=@(@{'$env'='PLOTMANAGER_MANAGEMENT_TEST_SECRET'})}})}}
        $file=Join-Path $managementRoot 'secret.json'
        $config | ConvertTo-Json -Depth 12 | Set-Content -LiteralPath $file -Encoding utf8
        $request=@{Operation='run';ConfigurationFiles=@($file);Plot='secret';WorkDirectory=$managementRoot}
        $result=Invoke-ManagedPlotRequest $request
        Assert-Equal $result.Steps[0].Output.Text '[redacted]'
        $plan=Invoke-ManagedPlotRequest @{Operation='plan';ConfigurationFiles=@($file);Plot='secret'}
        Assert-Equal $plan.Steps[0].Settings.Items[0] '[redacted]'
        $requestFile=Join-Path $managementRoot 'request.json'; $responseFile=Join-Path $managementRoot 'response.json'; $eventFile=Join-Path $managementRoot 'events.jsonl'
        $request | ConvertTo-Json -Depth 12 | Set-Content -LiteralPath $requestFile -Encoding utf8
        & (Get-Process -Id $PID).Path -NoProfile -File (Join-Path $scriptsPath 'Invoke-ManagedRequest.ps1') -RequestPath $requestFile -ResponsePath $responseFile -EventPath $eventFile
        Assert-Equal $LASTEXITCODE 0
        Assert-True (-not ([IO.File]::ReadAllText($responseFile).Contains($env:PLOTMANAGER_MANAGEMENT_TEST_SECRET)))
        Assert-Equal @(Get-Content -LiteralPath $eventFile).Count 2
    } finally { Remove-Item Env:PLOTMANAGER_MANAGEMENT_TEST_SECRET }
}
Test-Case 'Managed catalog contains all native schemas platforms and output metadata' {
    $catalog=Invoke-ManagedPlotRequest @{Operation='catalog'}
    Assert-Equal $catalog.Steps.Count 49
    $text=@($catalog.Steps | Where-Object Id -eq 'text.join')[0]
    Assert-True ($text.Parameters.ContainsKey('Items'))
    Assert-True ($text.Outputs.ContainsKey('Text'))
    Assert-True ($null -ne $text.Description)
}
