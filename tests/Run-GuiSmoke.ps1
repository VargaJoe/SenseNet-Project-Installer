#requires -Version 5.1
# Instantiate the real controls and run their asynchronous bridge without displaying a window.
[CmdletBinding()] param()
$ErrorActionPreference='Stop'
$scriptsPath=Join-Path (Split-Path $PSScriptRoot -Parent) 'src/Deployment/Scripts'
$guiPath=Join-Path $scriptsPath 'Show-PlotRunner.ps1'
$text=[IO.File]::ReadAllText($guiPath).Replace('$PSScriptRoot',("'"+$scriptsPath.Replace("'","''")+"'"))
$fixture=Join-Path ([IO.Path]::GetTempPath()) ('plot-gui-host-'+[guid]::NewGuid().ToString('N')+'.ps1')
$exercise=@'
$root=Join-Path ([IO.Path]::GetTempPath()) ('plot-gui-smoke-'+[guid]::NewGuid().ToString('N'))
$null=[IO.Directory]::CreateDirectory($root)
try {
    $files.Text=Join-Path $ConfigurationFiles[0] 'Examples/compose-files.json'
    $work.Text=$root
    $catalog=Invoke-PlotRequest @{Operation='catalog';ConfigurationFiles=@(Get-UiFiles)}
    foreach ($name in $catalog.Plots) { $null=$plots.Items.Add($name) }
    $plots.SelectedIndex=0
    foreach ($previewOnly in @($true,$false)) {
        Start-UiRequest $previewOnly
        if ($null -eq $script:active) { throw ('GUI failed to start child: '+$output.Text) }
        $deadline=[DateTime]::UtcNow.AddSeconds(30)
        while ($null -ne $script:active -and [DateTime]::UtcNow -lt $deadline) { [Windows.Forms.Application]::DoEvents(); Start-Sleep -Milliseconds 50 }
        if ($null -ne $script:active) { throw 'GUI child result deadline exceeded.' }
        $expected=if ($previewOnly) { 'Skipped' } else { 'Succeeded' }
        if ($output.Text -notlike ('*"Status":*"'+$expected+'"*')) { throw ('GUI unexpected output: '+$output.Text) }
        if ($previewOnly -and [IO.File]::Exists((Join-Path $root 'greeting.txt'))) { throw 'GUI preview wrote an artifact.' }
    }
    if (-not [IO.File]::Exists((Join-Path $root 'greeting.txt'))) { throw 'GUI run did not write artifact.' }
    Write-Output ('Hidden GUI construction + asynchronous preview/run PASS on '+$PSVersionTable.PSVersion)
} finally {
    if ($null -ne $script:active) { $script:active.Process.Kill(); $script:active.Process.WaitForExit(); $script:active.Process.Dispose(); [IO.File]::Delete($script:active.Path); $script:active=$null }
    $resolved=[IO.Path]::GetFullPath($root)
    $temp=[IO.Path]::GetFullPath([IO.Path]::GetTempPath()).TrimEnd('\','/')+[IO.Path]::DirectorySeparatorChar
    if ((Split-Path $resolved -Leaf) -notlike 'plot-gui-smoke-*' -or -not $resolved.StartsWith($temp,[StringComparison]::OrdinalIgnoreCase)) { throw 'Unsafe test cleanup.' }
    Remove-Item -LiteralPath $resolved -Recurse -Force
}
'@
try {
    if (-not $text.Contains('$null=$form.ShowDialog()')) { throw 'GUI entry point changed; update the smoke harness.' }
    [IO.File]::WriteAllText($fixture,$text.Replace('$null=$form.ShowDialog()',$exercise))
    & (Get-Process -Id $PID).Path -NoProfile -STA -File $fixture -ConfigurationFiles $scriptsPath
    if ($LASTEXITCODE -ne 0) { throw 'GUI smoke test failed.' }
} finally { [IO.File]::Delete($fixture) }
