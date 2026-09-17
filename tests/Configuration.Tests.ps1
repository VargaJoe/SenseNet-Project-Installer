# Dot-sourced by Run-Tests.ps1; fixtures stay inside its isolated test directory.
function Write-TestJson($Path, $Value) {
    [IO.File]::WriteAllText($Path, ($Value | ConvertTo-Json -Depth 30), [Text.UTF8Encoding]::new($false))
}
function Invoke-TestCli([string[]]$Arguments) {
    $errorFile = Join-Path $testRoot ('cli-' + [guid]::NewGuid().ToString('N') + '.err')
    $ErrorActionPreference = 'Continue'
    # Encode a PowerShell invocation so PS5.1 native argument marshalling cannot strip JSON quotes.
    $command = "& '" + (Join-Path $scriptsPath 'Run.ps1').Replace("'", "''") + "'"
    foreach ($argument in $Arguments) {
        if ($argument -match '^-(Plot|Step|ConfigPath|DefaultConfigPath|EnvironmentConfigPath|Settings|Params|AutoPath|WorkDirectory|Help|Explain|Legacy|WhatIf)$') { $command += ' ' + $argument }
        else { $command += " '" + $argument.Replace("'", "''") + "'" }
    }
    $encoded = [Convert]::ToBase64String([Text.Encoding]::Unicode.GetBytes($command))
    $output = & (Get-Process -Id $PID).Path -NoProfile -NonInteractive -OutputFormat Text -EncodedCommand $encoded 2> $errorFile
    $code = $LASTEXITCODE
    [pscustomobject]@{ Code=$code; Text=($output -join [Environment]::NewLine); ErrorText=[IO.File]::ReadAllText($errorFile) }
}
$layersRoot = Join-Path $testRoot 'configuration layers'
$null = [IO.Directory]::CreateDirectory($layersRoot)
$defaultFile = Join-Path $layersRoot 'default.json'
$projectFile = Join-Path $layersRoot 'project.json'
$environmentFile = Join-Path $layersRoot 'environment.json'
Write-TestJson $defaultFile @{
    Values=@{Nested=@{Keep='default';Change='default'};Enabled=$true;Number=5;Optional='present';Items=@('default');Separator=' / ';Path='layered.txt'}
    Plots=@{layered=@{Steps=@(
        @{Id='compose';Step='text.join';With=@{Items=@{'$ref'='settings.Values.Items'};Separator=@{'$ref'='settings.Values.Separator'}}},
        @{Id='save';Step='filesystem.write';With=@{Path=@{'$ref'='settings.Values.Path'};Content=@{'$ref'='steps.compose.Output.Text'}}}
    )}}
}
Write-TestJson $projectFile @{Values=@{Nested=@{Change='project'};Items=@('project','value');Optional=$null}}
Write-TestJson $environmentFile @{Values=@{Nested=@{Change='environment'};Enabled=$false;Number=0;Items=@('environment','final')}}
Test-Case 'Configuration files merge in order and retain nested fallback, null, false and zero' {
    $config = Read-PlotConfiguration -Path @($defaultFile,$projectFile,$environmentFile)
    Assert-Equal $config.Values.Nested.Keep 'default'
    Assert-Equal $config.Values.Nested.Change 'environment'
    Assert-Equal $config.Values.Enabled $false
    Assert-Equal $config.Values.Number 0
    Assert-True ($null -eq $config.Values.Optional)
    Assert-Equal ($config.Values.Items -join ',') 'environment,final'
    $config.Values.Nested.Keep='changed'
    Assert-Equal (Read-PlotConfiguration $defaultFile).Values.Nested.Keep 'default'
}
Test-Case 'Configuration loader rejects missing, malformed and non-object layers' {
    Assert-Throws { Read-PlotConfiguration @($defaultFile,(Join-Path $layersRoot 'missing.json')) } '*'
    $invalidFile = Join-Path $layersRoot 'invalid.json'
    [IO.File]::WriteAllText($invalidFile, '{')
    Assert-Throws { Read-PlotConfiguration @($defaultFile,$invalidFile) } '*'
    [IO.File]::WriteAllText($invalidFile, '[{}]')
    Assert-Throws { Read-PlotConfiguration @($defaultFile,$invalidFile) } '*JSON object*'
    [IO.File]::WriteAllText($invalidFile, 'null')
    Assert-Throws { Read-PlotConfiguration @($defaultFile,$invalidFile) } '*JSON object*'
}
Test-Case 'CLI composes default project environment files and invocation overrides' {
    $cli = Invoke-TestCli @('layered','-DefaultConfigPath',$defaultFile,'-ConfigPath',$projectFile,'-EnvironmentConfigPath',$environmentFile,'-WorkDirectory',$layersRoot)
    Assert-Equal $cli.Code 0
    Assert-Equal ($cli.Text | ConvertFrom-Json).Status 'Succeeded'
    Assert-Equal ([IO.File]::ReadAllText((Join-Path $layersRoot 'layered.txt'))) 'environment / final'
    $cli = Invoke-TestCli @('layered','-DefaultConfigPath',$defaultFile,'-ConfigPath',$projectFile,'-EnvironmentConfigPath',$environmentFile,'-WorkDirectory',$layersRoot,'-Params','{"compose":{"Items":["run","override"]},"save":{"Path":"override.txt"}}')
    Assert-Equal $cli.Code 0
    Assert-Equal ([IO.File]::ReadAllText((Join-Path $layersRoot 'override.txt'))) 'run / override'
}
Test-Case 'Explain lists configuration files in precedence order without executing' {
    $cli = Invoke-TestCli @('layered','-DefaultConfigPath',$defaultFile,'-ConfigPath',$projectFile,'-EnvironmentConfigPath',$environmentFile,'-Explain')
    Assert-Equal $cli.Code 0
    $plan = $cli.Text | ConvertFrom-Json
    Assert-Equal $plan[0].ConfigurationFiles.Count 3
    Assert-Equal $plan[0].ConfigurationFiles[2] $environmentFile
    Assert-Equal $plan[0].Step 'text.join'
}
Test-Case 'CLI missing environment fails before writes and legacy rejects native layers' {
    $work = Join-Path $layersRoot 'not-written'
    $null = [IO.Directory]::CreateDirectory($work)
    $cli = Invoke-TestCli @('layered','-DefaultConfigPath',$defaultFile,'-EnvironmentConfigPath',(Join-Path $work 'missing.json'),'-WorkDirectory',$work)
    Assert-Equal $cli.Code 1
    Assert-Equal @(Get-ChildItem -LiteralPath $work).Count 0
    $cli = Invoke-TestCli @('-Legacy','-Help','steps','-DefaultConfigPath',$defaultFile)
    Assert-Equal $cli.Code 1
    Assert-True ($cli.ErrorText -like '*Legacy mode accepts*')
}
Test-Case 'CLI default-only and project-only layers remain usable' {
    $cli = Invoke-TestCli @('-DefaultConfigPath',$defaultFile,'-Help','plots')
    Assert-Equal $cli.Code 0
    Assert-True ($cli.Text -like '*layered*')
    $cli = Invoke-TestCli @('layered','-ConfigPath',$defaultFile,'-Explain')
    Assert-Equal $cli.Code 0
    $plan = $cli.Text | ConvertFrom-Json
    Assert-Equal $plan[0].ConfigurationFiles.Count 1
}
