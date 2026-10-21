#requires -Version 5.1
Set-StrictMode -Version Latest
function Convert-ProcessArgument([AllowEmptyString()][string]$Value) {
    # Windows CRT quoting, used only when .NET Framework lacks ArgumentList.
    '"' + ([regex]::Replace(([regex]::Replace($Value, '(\\*)"', '$1$1\"')), '(\\+)$', '$1$1')) + '"'
}
function Stop-OwnedProcess($Process) {
    if ($Process.HasExited) { return }
    try {
        if ($PSVersionTable.PSVersion.Major -ge 7) { $Process.Kill($true) }
        elseif ([Environment]::OSVersion.Platform -eq [PlatformID]::Win32NT) {
            $stop=[Diagnostics.ProcessStartInfo]::new()
            $stop.FileName=Join-Path $env:SystemRoot 'System32/taskkill.exe'
            $stop.Arguments="/PID $($Process.Id) /T /F"
            $stop.UseShellExecute=$false; $stop.CreateNoWindow=$true
            $stop.RedirectStandardOutput=$true; $stop.RedirectStandardError=$true
            $killer=[Diagnostics.Process]::Start($stop)
            try { if (-not $killer.WaitForExit(5000)) { $killer.Kill() } } finally { $killer.Dispose() }
        } else { $Process.Kill() }
    } catch { if (-not $Process.HasExited) { $Process.Kill() } }
}
function Invoke-PlotProcess {
    [CmdletBinding(SupportsShouldProcess)]
    param([Parameter(Mandatory)][hashtable]$Settings,[Parameter(Mandatory)]$Context)
    $file=[string]$Settings.FilePath
    if ([string]::IsNullOrWhiteSpace($file)) { throw 'FilePath must not be empty.' }
    $timeout=[int]$Settings.TimeoutSeconds
    if ($timeout -lt 1 -or $timeout -gt 86400) { throw 'TimeoutSeconds must be between 1 and 86400.' }
    $directory=[string]$Settings.WorkingDirectory
    if (-not $directory) { $directory=$Context.WorkDirectory }
    if (-not [IO.Path]::IsPathRooted($directory)) { $directory=Join-Path $Context.WorkDirectory $directory }
    $directory=[IO.Path]::GetFullPath($directory)
    if (-not [IO.Directory]::Exists($directory)) { throw 'WorkingDirectory must exist.' }
    $arguments=@($Settings.Arguments)
    foreach ($argument in $arguments) {
        if ($null -eq $argument -or $argument -isnot [string] -or $argument.Contains([char]0)) { throw 'Arguments must contain strings without NUL characters.' }
    }
    if (-not @($Settings.SuccessExitCodes).Count) { throw 'SuccessExitCodes must not be empty.' }
    $codes=@($Settings.SuccessExitCodes | ForEach-Object { [int]$_ })
    if ([IO.Path]::IsPathRooted($file) -or $file.Contains('/') -or $file.Contains('\')) {
        if (-not [IO.Path]::IsPathRooted($file)) { $file=Join-Path $Context.WorkDirectory $file }
        $file=[IO.Path]::GetFullPath($file)
        if (-not [IO.File]::Exists($file)) { throw 'Executable file does not exist.' }
    } else {
        $command=Get-Command -Name $file -CommandType Application -ErrorAction SilentlyContinue | Select-Object -First 1
        if ($null -eq $command) { throw 'Executable was not found on PATH.' }
        $file=$command.Source
    }
    if ([IO.Path]::GetExtension($file) -in '.cmd','.bat','.ps1') { throw 'Use an explicit interpreter executable for scripts; shell execution is disabled.' }
    if (-not $PSCmdlet.ShouldProcess($file,'Run executable')) { return }
    $start=[Diagnostics.ProcessStartInfo]::new()
    $start.FileName=$file; $start.WorkingDirectory=$directory
    $start.UseShellExecute=$false; $start.CreateNoWindow=$true
    $start.RedirectStandardInput=$true; $start.RedirectStandardOutput=$true; $start.RedirectStandardError=$true
    $start.StandardOutputEncoding=[Text.Encoding]::UTF8; $start.StandardErrorEncoding=[Text.Encoding]::UTF8
    if ($null -ne $start.PSObject.Properties['ArgumentList']) {
        foreach ($argument in $arguments) { $start.ArgumentList.Add($argument) }
    } else { $start.Arguments=(@($arguments | ForEach-Object { Convert-ProcessArgument $_ }) -join ' ') }
    foreach ($key in $Settings.Environment.Keys) {
        if ([string]::IsNullOrWhiteSpace([string]$key) -or ([string]$key).Contains('=') -or ([string]$key).Contains([char]0)) { throw 'Invalid environment variable name.' }
        if ($null -eq $Settings.Environment[$key]) { $start.EnvironmentVariables.Remove([string]$key) }
        else { $start.EnvironmentVariables[[string]$key]=[string]$Settings.Environment[$key] }
    }
    $process=[Diagnostics.Process]::new(); $process.StartInfo=$start
    $timer=[Diagnostics.Stopwatch]::StartNew(); $started=$false
    try {
        try { $started=$process.Start() } catch { throw 'Unable to start executable.' }
        $process.StandardInput.Close()
        $stdout=$process.StandardOutput.ReadToEndAsync(); $stderr=$process.StandardError.ReadToEndAsync()
        if (-not $process.WaitForExit($timeout * 1000)) { throw 'Process timeout exceeded.' }
        $remaining=[Math]::Max(0,($timeout*1000)-[int]$timer.ElapsedMilliseconds)
        if (-not [Threading.Tasks.Task]::WaitAll([Threading.Tasks.Task[]]@($stdout,$stderr),$remaining)) { throw 'Process output timeout exceeded (an inherited pipe may still be open).' }
        $exitCode=$process.ExitCode
        if ($exitCode -notin $codes) { throw "Process exited with code $exitCode." }
        [pscustomobject]@{FilePath=$file;ExitCode=$exitCode;StandardOutput=$stdout.Result;StandardError=$stderr.Result;DurationMilliseconds=$timer.ElapsedMilliseconds}
    } finally {
        if ($started) { Stop-OwnedProcess $process }
        $process.Dispose()
    }
}
Export-ModuleMember -Function Invoke-PlotProcess
