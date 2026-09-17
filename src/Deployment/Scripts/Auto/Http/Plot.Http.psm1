#requires -Version 5.1
Set-StrictMode -Version Latest
Add-Type -AssemblyName System.Net.Http
function New-HttpClient($Settings) {
    $uri=$null
    if (-not [Uri]::TryCreate($Settings.Url,[UriKind]::Absolute,[ref]$uri) -or $uri.Scheme -notin @('http','https') -or $uri.UserInfo) { throw 'Url must be HTTP(S) without embedded credentials.' }
    $handler=[Net.Http.HttpClientHandler]::new()
    $handler.AllowAutoRedirect=$false; $handler.UseCookies=$false
    $client=[Net.Http.HttpClient]::new($handler)
    $client.Timeout=[Threading.Timeout]::InfiniteTimeSpan
    try {
        foreach ($key in $Settings.Headers.Keys) {
            $value=[string]$Settings.Headers[$key]
            if ($value.Contains("`r") -or $value.Contains("`n")) { throw 'Invalid HTTP header.' }
            $client.DefaultRequestHeaders.Add([string]$key,$value)
        }
        return $client
    } catch { $client.Dispose(); throw 'Invalid HTTP headers.' }
}
function Assert-HttpTimeout($Settings) {
    if ($Settings.TimeoutSeconds -lt 1 -or $Settings.TimeoutSeconds -gt 86400) { throw 'TimeoutSeconds must be between 1 and 86400.' }
}
function Wait-HttpTask($Task,$Timer,[int]$TimeoutMilliseconds) {
    $remaining=[Math]::Max(0,$TimeoutMilliseconds-[int]$Timer.ElapsedMilliseconds)
    if (-not $Task.Wait($remaining)) { throw 'HTTP operation deadline exceeded.' }
    return $Task.GetAwaiter().GetResult()
}
function Save-PlotDownload {
    [CmdletBinding(SupportsShouldProcess)] param([hashtable]$Settings,$Context)
    Assert-HttpTimeout $Settings
    if ([string]::IsNullOrWhiteSpace($Settings.Destination)) { throw 'Destination must not be empty.' }
    $path=$Settings.Destination
    if (-not [IO.Path]::IsPathRooted($path)) { $path=Join-Path $Context.WorkDirectory $path }
    $path=[IO.Path]::GetFullPath($path)
    if ([IO.Directory]::Exists($path) -or ([IO.File]::Exists($path) -and -not $Settings.Overwrite)) { throw 'Download destination already exists.' }
    if ($Settings.Sha256 -and $Settings.Sha256 -notmatch '^[a-fA-F0-9]{64}$') { throw 'Sha256 must contain 64 hexadecimal characters.' }
    if ($Settings.MaxBytes -lt 1) { throw 'MaxBytes must be positive.' }
    $client=New-HttpClient $Settings
    $response=$null; $inputStream=$null; $outputStream=$null; $cancel=$null; $temporary=$null
    try {
        if (-not $PSCmdlet.ShouldProcess($path,'Download HTTP resource')) { return }
        $timer=[Diagnostics.Stopwatch]::StartNew()
        $cancel=[Threading.CancellationTokenSource]::new($Settings.TimeoutSeconds*1000)
        $response=Wait-HttpTask ($client.GetAsync($Settings.Url,[Net.Http.HttpCompletionOption]::ResponseHeadersRead,$cancel.Token)) $timer ($Settings.TimeoutSeconds*1000)
        if (-not $response.IsSuccessStatusCode) { throw 'HTTP status is not successful.' }
        if ($null -ne $response.Content.Headers.ContentLength -and $response.Content.Headers.ContentLength -gt $Settings.MaxBytes) { throw 'Download exceeds MaxBytes.' }
        $temporary=Join-Path ([IO.Path]::GetDirectoryName($path)) ('.plot-download-'+[guid]::NewGuid().ToString('N'))
        $outputStream=[IO.File]::Open($temporary,[IO.FileMode]::CreateNew,[IO.FileAccess]::Write,[IO.FileShare]::None)
        $inputStream=Wait-HttpTask ($response.Content.ReadAsStreamAsync()) $timer ($Settings.TimeoutSeconds*1000)
        $buffer=New-Object byte[] 65536; $total=0L
        while (($count=Wait-HttpTask ($inputStream.ReadAsync($buffer,0,$buffer.Length,$cancel.Token)) $timer ($Settings.TimeoutSeconds*1000)) -gt 0) {
            $total+=$count
            if ($total -gt $Settings.MaxBytes) { throw 'Download exceeds MaxBytes.' }
            $outputStream.Write($buffer,0,$count)
        }
        $outputStream.Dispose(); $outputStream=$null
        $hash=(Get-FileHash -LiteralPath $temporary -Algorithm SHA256).Hash.ToLowerInvariant()
        if ($Settings.Sha256 -and $hash -ne $Settings.Sha256) { throw 'Download checksum mismatch.' }
        $cancel.Token.ThrowIfCancellationRequested()
        if ($Settings.Overwrite -and [IO.File]::Exists($path)) { [IO.File]::Replace($temporary,$path,[NullString]::Value) }
        else { [IO.File]::Move($temporary,$path) }
        [pscustomobject]@{Path=$path;Bytes=$total;Sha256=$hash;StatusCode=[int]$response.StatusCode}
    } catch {
        # Do not include URLs, query strings, headers or server response bodies in failures.
        $known=@('HTTP status is not successful.','Download exceeds MaxBytes.','Download checksum mismatch.')
        if ($_.Exception.Message -in $known) { throw $_.Exception.Message }
        throw 'Download failed or timed out.'
    } finally {
        if ($null -ne $outputStream) { $outputStream.Dispose() }
        if ($null -ne $inputStream) { $inputStream.Dispose() }
        if ($null -ne $response) { $response.Dispose() }
        if ($null -ne $cancel) { $cancel.Dispose() }
        $client.Dispose()
        if ($temporary -and [IO.File]::Exists($temporary)) { [IO.File]::Delete($temporary) }
    }
}
function Wait-PlotHttp {
    [CmdletBinding(SupportsShouldProcess)] param([hashtable]$Settings,$Context)
    Assert-HttpTimeout $Settings
    if ($Settings.IntervalMilliseconds -lt 1 -or $Settings.RequestTimeoutSeconds -lt 1) { throw 'Wait intervals and request timeout must be positive.' }
    $codes=@($Settings.StatusCodes)
    if (-not $codes.Count -or @($codes | Where-Object { $_ -isnot [int] -and $_ -isnot [long] -or $_ -lt 100 -or $_ -gt 599 }).Count) { throw 'StatusCodes must contain HTTP status integers.' }
    $client=New-HttpClient $Settings
    try {
        if (-not $PSCmdlet.ShouldProcess('HTTP endpoint','Wait for expected HTTP status')) { return }
        $timer=[Diagnostics.Stopwatch]::StartNew(); $attempts=0
        while ($timer.ElapsedMilliseconds -lt $Settings.TimeoutSeconds*1000) {
            $remaining=[int]($Settings.TimeoutSeconds*1000-$timer.ElapsedMilliseconds)
            if ($remaining -le 0) { break }
            $cancel=[Threading.CancellationTokenSource]::new([Math]::Min($remaining,$Settings.RequestTimeoutSeconds*1000))
            $response=$null; $attempts++
            try {
                $attemptTimer=[Diagnostics.Stopwatch]::StartNew()
                $response=Wait-HttpTask ($client.GetAsync($Settings.Url,[Net.Http.HttpCompletionOption]::ResponseHeadersRead,$cancel.Token)) $attemptTimer ([Math]::Min($remaining,$Settings.RequestTimeoutSeconds*1000))
                if ([int]$response.StatusCode -in $codes) { return [pscustomobject]@{StatusCode=[int]$response.StatusCode;Attempts=$attempts;DurationMilliseconds=$timer.ElapsedMilliseconds} }
            } catch { # Transport failures are retried only within the overall deadline.
            } finally { if ($null -ne $response) { $response.Dispose() }; $cancel.Dispose() }
            $remaining=[int]($Settings.TimeoutSeconds*1000-$timer.ElapsedMilliseconds)
            if ($remaining -gt 0) { Start-Sleep -Milliseconds ([Math]::Min($remaining,$Settings.IntervalMilliseconds)) }
        }
        throw 'HTTP readiness timeout exceeded.'
    } finally { $client.Dispose() }
}
function Wait-PlotTcp {
    [CmdletBinding(SupportsShouldProcess)] param([hashtable]$Settings,$Context)
    Assert-HttpTimeout $Settings
    if ([string]::IsNullOrWhiteSpace($Settings.HostName) -or $Settings.Port -lt 1 -or $Settings.Port -gt 65535 -or $Settings.IntervalMilliseconds -lt 1) { throw 'Invalid TCP endpoint or interval.' }
    if (-not $PSCmdlet.ShouldProcess('TCP endpoint','Wait for connection')) { return }
    $timer=[Diagnostics.Stopwatch]::StartNew(); $attempts=0
    while ($timer.ElapsedMilliseconds -lt $Settings.TimeoutSeconds*1000) {
        $client=[Net.Sockets.TcpClient]::new(); $attempts++
        try {
            $task=$client.ConnectAsync($Settings.HostName,$Settings.Port)
            $remaining=[Math]::Max(1,[int]($Settings.TimeoutSeconds*1000-$timer.ElapsedMilliseconds))
            if ($task.Wait([Math]::Min($remaining,1000)) -and $client.Connected) { return [pscustomobject]@{HostName=$Settings.HostName;Port=$Settings.Port;Attempts=$attempts;DurationMilliseconds=$timer.ElapsedMilliseconds} }
        } catch { # Retry refused connections within the deadline.
        } finally { $client.Dispose() }
        $remaining=[int]($Settings.TimeoutSeconds*1000-$timer.ElapsedMilliseconds)
        if ($remaining -gt 0) { Start-Sleep -Milliseconds ([Math]::Min($remaining,$Settings.IntervalMilliseconds)) }
    }
    throw 'TCP readiness timeout exceeded.'
}
Export-ModuleMember -Function Save-PlotDownload,Wait-PlotHttp,Wait-PlotTcp
