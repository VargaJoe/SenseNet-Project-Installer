#requires -Version 5.1
# Local Windows desktop host for the same structured protocol as Invoke-Request.ps1.
[CmdletBinding()] param([string[]]$ConfigurationFiles=@(),[string]$WorkDirectory=(Get-Location).Path)
$ErrorActionPreference='Stop'
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing
Import-Module (Join-Path $PSScriptRoot 'Core/PlotIntegration.psm1') -ErrorAction Stop
$form=New-Object Windows.Forms.Form
$form.Text='Plot Runner'; $form.Width=960; $form.Height=700
$form.StartPosition='CenterScreen'
$layout=New-Object Windows.Forms.TableLayoutPanel
$layout.Dock='Fill'; $layout.ColumnCount=1; $layout.RowCount=7
$null=$form.Controls.Add($layout)
$label=New-Object Windows.Forms.Label; $label.Text='Configuration files in order: default, project, environment (one absolute path per line)'; $label.AutoSize=$true
$null=$layout.Controls.Add($label)
$files=New-Object Windows.Forms.TextBox; $files.Multiline=$true; $files.Height=65; $files.Dock='Fill'; $files.Text=$ConfigurationFiles -join [Environment]::NewLine
$null=$layout.Controls.Add($files)
$work=New-Object Windows.Forms.TextBox; $work.Dock='Fill'; $work.Text=[IO.Path]::GetFullPath($WorkDirectory)
$null=$layout.Controls.Add($work)
$plots=New-Object Windows.Forms.ComboBox; $plots.DropDownStyle='DropDownList'; $plots.Dock='Fill'
$null=$layout.Controls.Add($plots)
$buttons=New-Object Windows.Forms.FlowLayoutPanel; $buttons.AutoSize=$true
$load=New-Object Windows.Forms.Button; $load.Text='Load plots'
$preview=New-Object Windows.Forms.Button; $preview.Text='Preview'
$run=New-Object Windows.Forms.Button; $run.Text='Run'
$null=$buttons.Controls.AddRange(@($load,$preview,$run)); $null=$layout.Controls.Add($buttons)
$notice=New-Object Windows.Forms.Label; $notice.AutoSize=$true; $notice.Text='Run applies the selected plot. Failed runs stop at the first error; inspect output before recovery.'
$null=$layout.Controls.Add($notice)
$output=New-Object Windows.Forms.TextBox; $output.Multiline=$true; $output.ReadOnly=$true; $output.ScrollBars='Both'; $output.Dock='Fill'; $output.Font=New-Object Drawing.Font('Consolas',10)
$null=$layout.Controls.Add($output)
for ($i=0;$i -lt 6;$i++) { $null=$layout.RowStyles.Add((New-Object Windows.Forms.RowStyle([Windows.Forms.SizeType]::AutoSize))) }
$null=$layout.RowStyles.Add((New-Object Windows.Forms.RowStyle([Windows.Forms.SizeType]::Percent,100)))
$script:active=$null
function Get-UiFiles { @($files.Lines | Where-Object { -not [string]::IsNullOrWhiteSpace($_) } | ForEach-Object { [IO.Path]::GetFullPath($_.Trim()) }) }
$load.Add_Click({
    try {
        $catalog=Invoke-PlotRequest @{Operation='catalog';ConfigurationFiles=@(Get-UiFiles)}
        $plots.Items.Clear(); foreach ($name in $catalog.Plots) { $null=$plots.Items.Add($name) }
        if ($plots.Items.Count) { $plots.SelectedIndex=0 }
        $output.Text=($catalog | ConvertTo-Json -Depth 20)
    } catch { $output.Text=$_.Exception.Message }
})
function Start-UiRequest([bool]$Preview) {
    if ($null -ne $script:active) { return }
    $requestPath=$null; $process=$null
    try {
        if ($null -eq $plots.SelectedItem) { throw 'Load configuration and select a plot first.' }
        $request=@{Operation='run';Plot=[string]$plots.SelectedItem;ConfigurationFiles=@(Get-UiFiles);WorkDirectory=[IO.Path]::GetFullPath($work.Text);WhatIf=$Preview}
        $requestPath=Join-Path ([IO.Path]::GetTempPath()) ('plot-request-'+[guid]::NewGuid().ToString('N')+'.json')
        [IO.File]::WriteAllText($requestPath,($request | ConvertTo-Json -Depth 20))
        $start=New-Object Diagnostics.ProcessStartInfo
        $start.FileName=(Get-Process -Id $PID).Path
        $start.Arguments='-NoProfile -NonInteractive -File "'+(Join-Path $PSScriptRoot 'Invoke-Request.ps1')+'" -RequestPath "'+$requestPath+'"'
        $start.UseShellExecute=$false; $start.CreateNoWindow=$true; $start.RedirectStandardOutput=$true; $start.RedirectStandardError=$true
        $start.StandardOutputEncoding=[Text.Encoding]::UTF8; $start.StandardErrorEncoding=[Text.Encoding]::UTF8
        $process=New-Object Diagnostics.Process; $process.StartInfo=$start; $null=$process.Start()
        $script:active=@{Process=$process;Out=$process.StandardOutput.ReadToEndAsync();Err=$process.StandardError.ReadToEndAsync();Path=$requestPath}
        $buttons.Enabled=$false; $files.Enabled=$false; $work.Enabled=$false; $plots.Enabled=$false
        $output.Text='Running...'; $timer.Start()
    } catch { if ($null -ne $process) { $process.Dispose() }; if ($requestPath) { [IO.File]::Delete($requestPath) }; $output.Text=$_.Exception.Message }
}
$preview.Add_Click({ Start-UiRequest $true }); $run.Add_Click({ Start-UiRequest $false })
$timer=New-Object Windows.Forms.Timer; $timer.Interval=200
$timer.Add_Tick({
    if ($null -eq $script:active) { return }
    $active=$script:active
    if ($active.Process.HasExited -and $active.Out.IsCompleted -and $active.Err.IsCompleted) {
        $timer.Stop()
        try { $output.Text='Exit code: '+$active.Process.ExitCode+[Environment]::NewLine+$active.Out.Result+[Environment]::NewLine+$active.Err.Result }
        finally { $active.Process.Dispose(); [IO.File]::Delete($active.Path); $script:active=$null; $buttons.Enabled=$true; $files.Enabled=$true; $work.Enabled=$true; $plots.Enabled=$true }
    }
})
$form.Add_FormClosing({ param($sender,$eventArgs)
    if ($null -ne $script:active) { $eventArgs.Cancel=$true; $notice.Text='A plot is still running. Wait for its result before closing.' }
})
try { $null=$form.ShowDialog() } finally { $timer.Dispose(); $form.Dispose() }
