#requires -Version 7.2
[CmdletBinding()]
param(
    [Parameter(Mandatory)][ValidateSet('prepare', 'verify', 'demo-content', 'backup', 'restore')][string]$Action,
    [string]$Configuration = '.local/settings.json',
    [string]$BackupPath = '',
    [string]$ConfirmRestore = '',
    [string]$ExpectedContentPath = '',
    [ValidateRange(10, 1800)][int]$TimeoutSeconds = 600
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest
$ProjectDirectory = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..'))
$LocalDirectory = Join-Path $ProjectDirectory '.local'
$PreparedPath = Join-Path $LocalDirectory 'prepared.json'
$EnvironmentPath = Join-Path $LocalDirectory 'runtime.env'
$CertificatePath = Join-Path $LocalDirectory 'snapp.pfx'
$ComposePath = Join-Path $ProjectDirectory 'compose.yaml'
$PathComparison = if ($IsWindows) { [StringComparison]::OrdinalIgnoreCase } else { [StringComparison]::Ordinal }

function Assert-PlainPath([string]$Path) {
    $current = [IO.Path]::GetFullPath($Path)
    while ($current -and $current.StartsWith($ProjectDirectory, $PathComparison)) {
        if (Test-Path -LiteralPath $current) {
            if ((Get-Item -LiteralPath $current -Force).Attributes -band [IO.FileAttributes]::ReparsePoint) {
                throw 'Project runtime paths must not be symbolic links or junctions.'
            }
        }
        if ($current.Equals($ProjectDirectory, $PathComparison)) { break }
        $current = [IO.Path]::GetDirectoryName($current)
    }
}

function Protect-Directory([string]$Path) {
    Assert-PlainPath $Path
    $null = [IO.Directory]::CreateDirectory($Path)
    if ($IsWindows) {
        $identity = [Security.Principal.WindowsIdentity]::GetCurrent().User
        $existing = Get-Acl -LiteralPath $Path
        if ($existing.GetOwner([Security.Principal.SecurityIdentifier]) -ne $identity) {
            throw 'The local runtime directory must already belong to the current user.'
        }
        $acl = [Security.AccessControl.DirectorySecurity]::new()
        $acl.SetAccessRuleProtection($true, $false)
        $rule = [Security.AccessControl.FileSystemAccessRule]::new($identity, 'FullControl', 'ContainerInherit,ObjectInherit', 'None', 'Allow')
        $acl.AddAccessRule($rule)
        [IO.FileSystemAclExtensions]::SetAccessControl([IO.DirectoryInfo]::new($Path), $acl)
    } else {
        & chmod 700 -- $Path
        if ($LASTEXITCODE -ne 0) { throw 'Could not protect the local runtime directory.' }
    }
}

function Write-PrivateFile([string]$Path, [byte[]]$Bytes) {
    Assert-PlainPath $Path
    [IO.File]::WriteAllBytes($Path, $Bytes)
    if (-not $IsWindows) {
        & chmod 600 -- $Path
        if ($LASTEXITCODE -ne 0) { throw 'Could not protect a local runtime file.' }
    }
}

function Write-PrivateText([string]$Path, [string]$Text) {
    Write-PrivateFile $Path ([Text.UTF8Encoding]::new($false).GetBytes($Text))
}

function Get-PublicConfiguration {
    $path = if ([IO.Path]::IsPathFullyQualified($Configuration)) { $Configuration } else { Join-Path $ProjectDirectory $Configuration }
    $inputSettings = Get-Content -LiteralPath $path -Raw | ConvertFrom-Json -AsHashtable
    $settings = if ($inputSettings.ContainsKey('SenseNet')) { $inputSettings.SenseNet } else { $inputSettings }
    if ($settings.StackName -notmatch '^pm-sensenet-[a-z0-9]+(?:-[a-z0-9]+)*$' -or $settings.StackName.Length -gt 60) {
        throw 'StackName must start with pm-sensenet- and contain lowercase letters, digits and single hyphens (maximum 60 characters).'
    }
    $apiPort = 0; $identityPort = 0
    if (-not [int]::TryParse([string]$settings.ApiPort, [ref]$apiPort) -or $apiPort -lt 1024 -or $apiPort -gt 65535 -or
        -not [int]::TryParse([string]$settings.IdentityPort, [ref]$identityPort) -or $identityPort -lt 1024 -or $identityPort -gt 65535 -or $apiPort -eq $identityPort) {
        throw 'API and identity ports must be different integers between 1024 and 65535.'
    }
    if ($settings.AcceptSqlLicense -isnot [bool] -or -not $settings.AcceptSqlLicense) {
        throw 'Review the SQL Server Developer license and set AcceptSqlLicense to true for this local development installation.'
    }
    foreach ($imageName in 'Api', 'Identity', 'Sql') {
        if ($settings.Images[$imageName] -notmatch '^[a-z0-9][a-z0-9._:/-]*@sha256:[0-9a-f]{64}$') {
            throw "The $imageName image must use an immutable sha256 digest."
        }
    }
    return [ordered]@{
        StackName = [string]$settings.StackName; ApiPort = $apiPort; IdentityPort = $identityPort
        Images = [ordered]@{ Api = [string]$settings.Images.Api; Identity = [string]$settings.Images.Identity; Sql = [string]$settings.Images.Sql }
    }
}

function Get-BindingJson($Settings) {
    [ordered]@{ StackName = $Settings.StackName; ApiPort = $Settings.ApiPort; IdentityPort = $Settings.IdentityPort
        Images = [ordered]@{ Api = $Settings.Images.Api; Identity = $Settings.Images.Identity; Sql = $Settings.Images.Sql } } |
        ConvertTo-Json -Depth 10 -Compress
}

function Get-ProjectIdentity {
    $path = if ($IsWindows) { $ProjectDirectory.ToLowerInvariant() } else { $ProjectDirectory }
    return [Convert]::ToHexString([Security.Cryptography.SHA256]::HashData([Text.Encoding]::UTF8.GetBytes($path)))
}

function Get-Prepared($Settings) {
    Assert-PlainPath $LocalDirectory
    if (-not (Test-Path -LiteralPath $PreparedPath -PathType Leaf)) { throw 'Run prepare before this operation.' }
    $prepared = Get-Content -LiteralPath $PreparedPath -Raw | ConvertFrom-Json -AsHashtable
    if ($prepared.FormatVersion -ne 1 -or (Get-BindingJson $prepared.Binding) -cne (Get-BindingJson $Settings)) {
        throw 'Stack name, ports and image digests are immutable after prepare. Use a new project and unique stack for a different installation.'
    }
    foreach ($path in $EnvironmentPath, $CertificatePath) {
        Assert-PlainPath $path
        if (-not (Test-Path -LiteralPath $path -PathType Leaf)) { throw 'The prepared runtime is incomplete; restore its private local files from backup.' }
    }
    if ((Get-FileHash -LiteralPath $CertificatePath -Algorithm SHA256).Hash -ne $prepared.CertificateFileSha256) {
        throw 'The prepared certificate file changed. Restore its original private files before continuing.'
    }
    if ((Get-FileHash -LiteralPath $EnvironmentPath -Algorithm SHA256).Hash -ne $prepared.EnvironmentFileSha256) {
        throw 'The prepared environment file changed. Restore its original private files before continuing.'
    }
    return $prepared
}

function Invoke-Docker([string[]]$Arguments, [string]$Label = 'request') {
    $info = [Diagnostics.ProcessStartInfo]::new('docker')
    $info.UseShellExecute = $false; $info.CreateNoWindow = $true
    $info.RedirectStandardOutput = $true; $info.RedirectStandardError = $true
    $info.WorkingDirectory = $ProjectDirectory
    foreach ($argument in $Arguments) { $info.ArgumentList.Add($argument) }
    $process = [Diagnostics.Process]::new(); $process.StartInfo = $info
    try {
        if (-not $process.Start()) { throw 'Docker could not be started.' }
        $stdout = $process.StandardOutput.ReadToEndAsync()
        $stderr = $process.StandardError.ReadToEndAsync()
        $process.WaitForExit()
        $result = $stdout.GetAwaiter().GetResult()
        $null = $stderr.GetAwaiter().GetResult()
        if ($process.ExitCode -ne 0) { throw "Docker $Label failed (exit $($process.ExitCode)); inspect only this project's Docker status locally." }
        return $result.Trim()
    } finally { $process.Dispose() }
}

function Invoke-Compose([string[]]$Arguments, [string]$Label) {
    Invoke-Docker (@('compose', '--project-name', $script:Settings.StackName, '--env-file', $EnvironmentPath, '--file', $ComposePath) + $Arguments) $Label
}

function Assert-ProjectNamespace {
    $ids = Invoke-Docker @('container', 'ls', '--all', '--quiet', '--filter', "label=com.docker.compose.project=$($script:Settings.StackName)") 'project lookup'
    $containers = @()
    foreach ($id in ($ids -split '\r?\n' | Where-Object { $_ })) {
        $labels = Invoke-Docker @('container', 'inspect', '--format', '{{json .Config.Labels}}', $id) 'ownership check' | ConvertFrom-Json -AsHashtable
        if (-not $labels -or -not $labels['com.docker.compose.project.working_dir']) { throw 'A matching container has no verifiable Compose owner directory.' }
        $workingDirectory = [IO.Path]::GetFullPath(($labels['com.docker.compose.project.working_dir'] -replace '[/\\]', [IO.Path]::DirectorySeparatorChar))
        $service = $labels['com.docker.compose.service']
        if ($labels['com.docker.compose.project'] -ne $script:Settings.StackName -or $service -notin @('snsql', 'db-init', 'snapp', 'snis') -or
            -not $workingDirectory.Equals($ProjectDirectory, $PathComparison)) {
            throw 'The stack name is already used by containers outside this project directory. No containers were changed.'
        }
        $running = (Invoke-Docker @('container', 'inspect', '--format', '{{.State.Running}}', $id) 'state lookup') -eq 'true'
        $containers += [pscustomobject]@{ Id = $id; Service = $service; Running = $running }
    }
    foreach ($volume in 'db-data', 'app-data') {
        $name = "$($script:Settings.StackName)_$volume"
        $matches = Invoke-Docker @('volume', 'ls', '--quiet', '--filter', "name=$name") 'volume namespace lookup'
        if ($name -in ($matches -split '\r?\n')) {
            $labels = Invoke-Docker @('volume', 'inspect', '--format', '{{json .Labels}}', $name) 'volume namespace check' | ConvertFrom-Json -AsHashtable
            if (-not $labels -or $labels['com.docker.compose.project'] -ne $script:Settings.StackName -or $labels['com.docker.compose.volume'] -ne $volume -or
                $labels['io.github.vargajoe.plotmanager.project-directory-sha256'] -cne (Get-ProjectIdentity)) {
                throw 'The stack name is already used by data volumes outside this project directory. No data volume was changed.'
            }
        }
    }
    return $containers
}

function Get-OwnedContainers {
    $containers = @(Assert-ProjectNamespace)
    if (@($containers | Where-Object { $_.Service -eq 'db-init' -and $_.Running }).Count) { throw 'Database initialization is still running; retry after installation completes.' }
    if (@($containers | Where-Object Service -eq 'snsql').Count -ne 1 -or @($containers | Where-Object Service -eq 'snapp').Count -ne 1) {
        throw 'Install this project before backing up or restoring its data.'
    }
    return $containers
}

function Assert-OwnedVolumes {
    foreach ($volume in 'db-data', 'app-data') {
        $name = "$($script:Settings.StackName)_$volume"
        $labels = Invoke-Docker @('volume', 'inspect', '--format', '{{json .Labels}}', $name) 'volume ownership check' | ConvertFrom-Json -AsHashtable
        if (-not $labels -or $labels['com.docker.compose.project'] -ne $script:Settings.StackName -or $labels['com.docker.compose.volume'] -ne $volume -or
            $labels['io.github.vargajoe.plotmanager.project-directory-sha256'] -cne (Get-ProjectIdentity)) {
            throw 'A data volume does not belong to this Compose project. No volume was changed.'
        }
    }
    $null = Invoke-Docker @('image', 'inspect', '--format', '{{.Id}}', $script:Settings.Images.Sql) 'cached SQL image lookup'
}

function Restart-PreviouslyRunning($Containers) {
    $services = @($Containers | Where-Object Running | ForEach-Object Service)
    if ($services -contains 'snsql') {
        $null = Invoke-Compose @('start', 'snsql') 'SQL restart'
        $sql = $Containers | Where-Object Service -eq 'snsql'
        $deadline = [DateTime]::UtcNow.AddMinutes(3)
        do {
            $health = Invoke-Docker @('container', 'inspect', '--format', '{{.State.Health.Status}}', $sql.Id) 'SQL readiness'
            if ($health -eq 'healthy') { break }
            if ([DateTime]::UtcNow -ge $deadline) { throw 'SQL did not become healthy after the offline data operation.' }
            Start-Sleep -Seconds 2
        } while ($true)
    }
    foreach ($service in 'snis', 'snapp') {
        if ($services -contains $service) { $null = Invoke-Compose @('start', $service) 'service restart' }
    }
}

function Invoke-VolumeArchive([string]$Volume, [string]$Directory, [switch]$Restore) {
    $volumeName = "$($script:Settings.StackName)_$Volume"
    $mode = if ($Restore) { 'rw' } else { 'ro' }
    $command = if ($Restore) {
        "find /data -mindepth 1 -maxdepth 1 -exec rm -rf -- {} +; tar --numeric-owner -xzpf /backup/$Volume.tar.gz -C /data"
    } else { "tar --numeric-owner -czpf /backup/$Volume.tar.gz -C /data ." }
    if (-not $Restore -and -not $IsWindows) {
        $ownerId = (& id -u).Trim(); $groupId = (& id -g).Trim()
        if ($LASTEXITCODE -ne 0 -or $ownerId -notmatch '^\d+$' -or $groupId -notmatch '^\d+$') { throw 'Could not determine the local backup owner.' }
        $command += "; chmod 600 /backup/$Volume.tar.gz; chown -- ${ownerId}:${groupId} /backup/$Volume.tar.gz"
    }
    $backupMount = if ($Restore) { "${Directory}:/backup:ro" } else { "${Directory}:/backup" }
    $null = Invoke-Docker @('run', '--rm', '--pull', 'never', '--network', 'none', '--user', '0',
        '--label', "io.github.vargajoe.plotmanager.owner=$($script:Settings.StackName)",
        '--volume', "${volumeName}:/data:$mode", '--volume', $backupMount,
        '--entrypoint', '/bin/bash', $script:Settings.Images.Sql, '-ec', $command) 'offline volume archive'
}

function New-LocalHttpClient([string]$Fingerprint, [int]$ApiPort, [int]$IdentityPort) {
    if (-not ('PlotSenseNetPinnedClient' -as [type])) {
        Add-Type -TypeDefinition @'
using System;
using System.Net;
using System.Net.Http;
using System.Net.Security;
using System.Security.Cryptography;
public static class PlotSenseNetPinnedClient {
    public static HttpClient Create(string fingerprint, int apiPort, int identityPort) {
        var handler = new HttpClientHandler {
            AllowAutoRedirect = false, UseProxy = false, CookieContainer = new CookieContainer()
        };
        handler.ServerCertificateCustomValidationCallback = (request, cert, chain, errors) =>
            cert != null && request.RequestUri.Scheme == "https" &&
            (request.RequestUri.Host == "localhost" || request.RequestUri.Host == "127.0.0.1") &&
            (request.RequestUri.Port == apiPort || request.RequestUri.Port == identityPort) &&
            (errors & (SslPolicyErrors.RemoteCertificateNameMismatch | SslPolicyErrors.RemoteCertificateNotAvailable)) == SslPolicyErrors.None &&
            DateTime.UtcNow >= cert.NotBefore.ToUniversalTime() && DateTime.UtcNow <= cert.NotAfter.ToUniversalTime() &&
            cert.GetCertHashString(HashAlgorithmName.SHA256).Equals(fingerprint, StringComparison.OrdinalIgnoreCase);
        return new HttpClient(handler, true) { Timeout = TimeSpan.FromSeconds(20) };
    }
}
'@
    }
    return [PlotSenseNetPinnedClient]::Create($Fingerprint, $ApiPort, $IdentityPort)
}

function Read-HttpJson($Response, [string]$Purpose) {
    try {
        if (-not $Response.IsSuccessStatusCode) { throw "$Purpose failed (HTTP $([int]$Response.StatusCode))." }
        try { return ($Response.Content.ReadAsStringAsync().GetAwaiter().GetResult() | ConvertFrom-Json -AsHashtable) }
        catch { throw "$Purpose returned an invalid JSON response." }
    } finally { $Response.Dispose() }
}

function Assert-IdentityEndpoint([string]$Address) {
    $uri = $null
    if (-not [Uri]::TryCreate($Address, [UriKind]::Absolute, [ref]$uri) -or $uri.Scheme -ne 'https' -or
        $uri.Host -ne 'localhost' -or $uri.Port -ne $script:Settings.IdentityPort) {
        throw 'Identity discovery returned an endpoint outside this local project.'
    }
    return $uri.AbsoluteUri
}

function Get-AuthenticatedClient($Prepared) {
    $http = New-LocalHttpClient $Prepared.CertificateSha256 $script:Settings.ApiPort $script:Settings.IdentityPort
    try {
        $repository = "https://localhost:$($script:Settings.ApiPort)"
        $authority = "https://localhost:$($script:Settings.IdentityPort)"
        $deadline = [DateTime]::UtcNow.AddSeconds($TimeoutSeconds)
        do {
            try {
                $root = Read-HttpJson ($http.GetAsync("$repository/odata.svc/('Root')?`$select=Id,Path").GetAwaiter().GetResult()) 'Repository readiness'
                if ($root.d.Id -le 0 -or $root.d.Path -ne '/Root') { throw 'Repository returned unexpected Root content.' }
                $metadata = Read-HttpJson ($http.GetAsync("$authority/.well-known/openid-configuration").GetAwaiter().GetResult()) 'Identity discovery'
                break
            } catch {
                if ([DateTime]::UtcNow -ge $deadline) { throw 'SenseNet did not become ready before the timeout; inspect this project status and logs locally.' }
                Start-Sleep -Seconds 3
            }
        } while ($true)

        # Same authorization-code + PKCE flow as the public SenseNet Docker test.
        # The loopback callback URL is a protocol identifier; it is never requested.
        $origin = $repository
        $null = $http.DefaultRequestHeaders.TryAddWithoutValidation('Origin', $origin)
        $client = Read-HttpJson ($http.GetAsync("$repository/odata.svc/('Root')/GetClientRequestParameters?clientType=adminui").GetAwaiter().GetResult()) 'Admin UI discovery'
        if (-not $client.client_id -or (Assert-IdentityEndpoint $client.authority).TrimEnd('/') -ne $authority) { throw 'Repository returned unexpected client metadata.' }
        $keysUri = Assert-IdentityEndpoint $metadata.jwks_uri
        $null = Read-HttpJson ($http.GetAsync($keysUri).GetAwaiter().GetResult()) 'Identity signing keys'
        $tokenUri = Assert-IdentityEndpoint $metadata.token_endpoint
        $authorizeUri = Assert-IdentityEndpoint $metadata.authorization_endpoint
        $redirect = "$origin/authentication/callback"
        $verifier = [Convert]::ToBase64String([Security.Cryptography.RandomNumberGenerator]::GetBytes(32)).TrimEnd('=').Replace('+', '-').Replace('/', '_')
        $challenge = [Convert]::ToBase64String([Security.Cryptography.SHA256]::HashData([Text.Encoding]::ASCII.GetBytes($verifier))).TrimEnd('=').Replace('+', '-').Replace('/', '_')
        $state = [guid]::NewGuid().ToString('N')
        $query = @{ client_id = $client.client_id; redirect_uri = $redirect; response_type = 'code'; scope = 'openid profile sensenet'
            snrepo = $repository; code_challenge = $challenge; code_challenge_method = 'S256'; state = $state; nonce = [guid]::NewGuid().ToString('N') }
        $encoded = ($query.GetEnumerator() | ForEach-Object { [Uri]::EscapeDataString($_.Key) + '=' + [Uri]::EscapeDataString($_.Value) }) -join '&'
        $response = $http.GetAsync("${authorizeUri}?$encoded").GetAwaiter().GetResult()
        try {
            if (-not $response.Headers.Location -or $response.Headers.Location.OriginalString -notmatch '/Account/Login') { throw 'Authorization did not reach the local login page.' }
            $loginUri = Assert-IdentityEndpoint ([Uri]::new([Uri]$authority, $response.Headers.Location).AbsoluteUri)
        } finally { $response.Dispose() }
        $page = $http.GetStringAsync($loginUri).GetAwaiter().GetResult()
        $form = [Collections.Generic.Dictionary[string,string]]::new()
        foreach ($tag in [regex]::Matches($page, '<input\b[^>]*>')) {
            $name = [regex]::Match($tag.Value, '\bname="([^"]*)"').Groups[1].Value
            if ($name) { $form[$name] = [Net.WebUtility]::HtmlDecode([regex]::Match($tag.Value, '\bvalue="([^"]*)"').Groups[1].Value) }
        }
        $adminPassword = [Environment]::GetEnvironmentVariable('PLOTMANAGER_SECRET_SENSENET_ADMIN_PASSWORD')
        $form['Username'] = 'admin'; $form['Password'] = if ($adminPassword) { $adminPassword } else { 'admin' }; $form['button'] = 'login'
        $response = $http.PostAsync("$authority/Account/Login", [Net.Http.FormUrlEncodedContent]::new($form)).GetAwaiter().GetResult()
        try {
            $loginRedirect = if ($response.Headers.Location) { [Uri]::new([Uri]$authority, $response.Headers.Location) } else { $null }
            $loginPage = $null
            if (-not $loginRedirect -and [int]$response.StatusCode -eq 200) {
                $loginPage = $response.Content.ReadAsStringAsync().GetAwaiter().GetResult()
                # IdentityServer's successful PKCE login renders a redirect view instead of HTTP 302.
                # Read its URL as data; never execute page JavaScript or follow arbitrary links.
                if ($loginPage -match 'You are now being returned to the application') {
                    foreach ($meta in [regex]::Matches($loginPage, '<meta\b[^>]*>')) {
                        $target = [regex]::Match($meta.Value, '\bdata-url="([^"]*)"')
                        if ($target.Success) {
                            $decoded = [Net.WebUtility]::HtmlDecode($target.Groups[1].Value)
                            if ($decoded.StartsWith('/connect/authorize/callback?', [StringComparison]::Ordinal)) {
                                $loginRedirect = [Uri]::new([Uri]$authority, $decoded)
                                break
                            }
                        }
                    }
                }
            }
            if (-not $loginRedirect -or $loginRedirect.AbsolutePath -ne '/connect/authorize/callback') {
                if ($null -eq $loginPage) { $loginPage = $response.Content.ReadAsStringAsync().GetAwaiter().GetResult() }
                if ($loginPage -match 'Invalid repository') { throw 'IdentityServer rejected the loopback repository host; check this project public/internal repository mapping.' }
                if ($loginPage -match 'antiforgery|anti-forgery') { throw 'IdentityServer rejected the login antiforgery form; inspect its local configuration.' }
                $redirectPath = if ($loginRedirect) { $loginRedirect.AbsolutePath } else { 'none' }
                throw "Admin login failed (HTTP $([int]$response.StatusCode), redirect $redirectPath). This demo initially uses admin/admin; after changing it, supply PLOTMANAGER_SECRET_SENSENET_ADMIN_PASSWORD to the local runner."
            }
            $callback = Assert-IdentityEndpoint $loginRedirect.AbsoluteUri
        } finally { $response.Dispose() }
        $response = $http.GetAsync($callback).GetAwaiter().GetResult()
        try {
            if (-not $response.Headers.Location) { throw 'Authorization returned no callback.' }
            $destination = $response.Headers.Location.AbsoluteUri
            if (-not $destination.StartsWith("${redirect}?", [StringComparison]::Ordinal)) { throw 'Authorization returned an unexpected redirect.' }
            $code = [regex]::Match($destination, '[?&]code=([^&]+)')
            $returnedState = [regex]::Match($destination, '[?&]state=([^&]+)')
            if (-not $code.Success -or -not $returnedState.Success -or [Uri]::UnescapeDataString($returnedState.Groups[1].Value) -cne $state) { throw 'Authorization returned no valid code and state.' }
        } finally { $response.Dispose() }
        $exchange = [Collections.Generic.Dictionary[string,string]]::new()
        $exchange['grant_type'] = 'authorization_code'; $exchange['client_id'] = $client.client_id; $exchange['redirect_uri'] = $redirect
        $exchange['code'] = [Uri]::UnescapeDataString($code.Groups[1].Value); $exchange['code_verifier'] = $verifier
        $token = Read-HttpJson ($http.PostAsync($tokenUri, [Net.Http.FormUrlEncodedContent]::new($exchange)).GetAwaiter().GetResult()) 'PKCE token exchange'
        if (-not $token.access_token) { throw 'PKCE exchange returned no access token.' }
        $http.DefaultRequestHeaders.Authorization = [Net.Http.Headers.AuthenticationHeaderValue]::new('Bearer', $token.access_token)
        $admin = Read-HttpJson ($http.GetAsync("$repository/odata.svc/Root/IMS/BuiltIn/Portal('Admin')?`$select=Id,Name").GetAwaiter().GetResult()) 'Authenticated Admin read'
        if ($admin.d.Id -ne 1) { throw 'Authenticated Admin content read returned an unexpected identity.' }
        return $http
    } catch { $http.Dispose(); throw }
}

function Get-ContentAddress([string]$Path) {
    if ($Path -notmatch '^/Root/(?:[a-zA-Z0-9_-]+/)*[a-zA-Z0-9_-]+$') { throw 'Content checks accept only simple paths beneath /Root.' }
    $separator = $Path.LastIndexOf('/')
    $parent = $Path.Substring(0, $separator); $name = $Path.Substring($separator + 1)
    return "https://localhost:$($script:Settings.ApiPort)/odata.svc${parent}('$name')?`$select=Id,Name,Path"
}

$Settings = Get-PublicConfiguration
switch ($Action) {
    'prepare' {
        $null = Assert-ProjectNamespace
        Protect-Directory $LocalDirectory
        if (Test-Path -LiteralPath $PreparedPath) {
            $null = Get-Prepared $Settings
            Write-Output "Prepared runtime already exists for $($Settings.StackName); private values were retained."
            break
        }
        if ((Test-Path -LiteralPath $EnvironmentPath) -or (Test-Path -LiteralPath $CertificatePath)) {
            throw 'An incomplete prepared runtime already exists. Review its private files locally; prepare will not overwrite them.'
        }
        $sqlPassword = 'Pm!aA' + [Convert]::ToHexString([Security.Cryptography.RandomNumberGenerator]::GetBytes(24))
        $certificatePassword = [Convert]::ToHexString([Security.Cryptography.RandomNumberGenerator]::GetBytes(32))
        $repositoryApiKey = [Convert]::ToHexString([Security.Cryptography.RandomNumberGenerator]::GetBytes(48))
        $rsa = [Security.Cryptography.RSA]::Create(2048)
        try {
            $request = [Security.Cryptography.X509Certificates.CertificateRequest]::new('CN=localhost', $rsa, [Security.Cryptography.HashAlgorithmName]::SHA256, [Security.Cryptography.RSASignaturePadding]::Pkcs1)
            $san = [Security.Cryptography.X509Certificates.SubjectAlternativeNameBuilder]::new()
            $san.AddDnsName('localhost'); $san.AddIpAddress([Net.IPAddress]::Loopback)
            $request.CertificateExtensions.Add($san.Build())
            $request.CertificateExtensions.Add([Security.Cryptography.X509Certificates.X509BasicConstraintsExtension]::new($false, $false, 0, $true))
            $request.CertificateExtensions.Add([Security.Cryptography.X509Certificates.X509KeyUsageExtension]::new([Security.Cryptography.X509Certificates.X509KeyUsageFlags]::DigitalSignature -bor [Security.Cryptography.X509Certificates.X509KeyUsageFlags]::KeyEncipherment, $true))
            $oids = [Security.Cryptography.OidCollection]::new(); $null = $oids.Add([Security.Cryptography.Oid]::new('1.3.6.1.5.5.7.3.1'))
            $request.CertificateExtensions.Add([Security.Cryptography.X509Certificates.X509EnhancedKeyUsageExtension]::new($oids, $true))
            $certificate = $request.CreateSelfSigned([DateTimeOffset]::UtcNow.AddMinutes(-5), [DateTimeOffset]::UtcNow.AddYears(2))
            try {
                Write-PrivateFile $CertificatePath ($certificate.Export([Security.Cryptography.X509Certificates.X509ContentType]::Pfx, $certificatePassword))
                $fingerprint = $certificate.GetCertHashString([Security.Cryptography.HashAlgorithmName]::SHA256)
            } finally { $certificate.Dispose() }
        } finally { $rsa.Dispose() }
        $environmentText = @(
            "STACK_NAME=$($Settings.StackName)", "PROJECT_DIRECTORY_SHA256=$(Get-ProjectIdentity)", "API_PORT=$($Settings.ApiPort)", "IDENTITY_PORT=$($Settings.IdentityPort)",
            "SQL_PASSWORD=$sqlPassword", "CERT_PASSWORD=$certificatePassword", "REPOSITORY_API_KEY=$repositoryApiKey",
            "API_IMAGE=$($Settings.Images.Api)", "IDENTITY_IMAGE=$($Settings.Images.Identity)", "SQL_IMAGE=$($Settings.Images.Sql)"
        ) -join "`n"
        Write-PrivateText $EnvironmentPath ($environmentText + "`n")
        $prepared = [ordered]@{ FormatVersion = 1; Binding = $Settings; CertificateSha256 = $fingerprint
            CertificateFileSha256 = (Get-FileHash -LiteralPath $CertificatePath -Algorithm SHA256).Hash
            EnvironmentFileSha256 = (Get-FileHash -LiteralPath $EnvironmentPath -Algorithm SHA256).Hash; PreparedUtc = [DateTime]::UtcNow.ToString('o') }
        Write-PrivateText $PreparedPath ($prepared | ConvertTo-Json -Depth 12)
        Write-Output "Prepared $($Settings.StackName): API https://localhost:$($Settings.ApiPort), identity https://localhost:$($Settings.IdentityPort). Private runtime files remain in .local; no certificate trust store was changed."
    }
    { $_ -in 'verify', 'demo-content' } {
        $prepared = Get-Prepared $Settings
        $http = Get-AuthenticatedClient $prepared
        try {
            if ($Action -eq 'demo-content') {
                $contentPath = '/Root/Content/PlotManagerDemo'
                $response = $http.GetAsync((Get-ContentAddress $contentPath)).GetAwaiter().GetResult()
                if ([int]$response.StatusCode -eq 404) {
                    $response.Dispose()
                    $body = [Net.Http.StringContent]::new('{"__ContentType":"Folder","Name":"PlotManagerDemo","DisplayName":"Plot Manager Docker demo"}', [Text.Encoding]::UTF8, 'application/json')
                    try { $response = $http.PostAsync("https://localhost:$($Settings.ApiPort)/odata.svc/Root('Content')", $body).GetAwaiter().GetResult() }
                    finally { $body.Dispose() }
                    try { if (-not $response.IsSuccessStatusCode) { throw "Demo content creation failed (HTTP $([int]$response.StatusCode))." } }
                    finally { $response.Dispose() }
                    $response = $http.GetAsync((Get-ContentAddress $contentPath)).GetAwaiter().GetResult()
                }
                $content = Read-HttpJson $response 'Demo content creation/read'
                if ($content.d.Id -le 0 -or $content.d.Path -ne $contentPath) { throw 'Demo content returned an unexpected identifier or path.' }
                Write-Output "Demo content ready: $contentPath (Id=$($content.d.Id))."
            } elseif ($ExpectedContentPath) {
                $content = Read-HttpJson ($http.GetAsync((Get-ContentAddress $ExpectedContentPath)).GetAwaiter().GetResult()) 'Persistent content check'
                if ($content.d.Id -le 0 -or $content.d.Path -ne $ExpectedContentPath) { throw 'The expected persistent content was not found.' }
                Write-Output "Verified Root, discovery, PKCE Admin login and $ExpectedContentPath (Id=$($content.d.Id))."
            } else {
                Write-Output 'Verified repository Root content, identity discovery, PKCE Admin login and authenticated Admin(Id=1) read with the project certificate pin.'
            }
        } finally { $http.Dispose() }
    }
    'backup' {
        $prepared = Get-Prepared $Settings
        $containers = @(Get-OwnedContainers)
        Assert-OwnedVolumes
        $backupsDirectory = Join-Path $LocalDirectory 'backups'
        Protect-Directory $backupsDirectory
        $directory = Join-Path $backupsDirectory ([DateTime]::UtcNow.ToString('yyyyMMdd-HHmmss') + '-' + [guid]::NewGuid().ToString('N').Substring(0, 8))
        Protect-Directory $directory
        try {
            $null = Invoke-Compose @('stop', '--timeout', '60') 'offline backup stop'
            foreach ($volume in 'db-data', 'app-data') { Invoke-VolumeArchive $volume $directory }
            foreach ($path in $EnvironmentPath, $CertificatePath, $PreparedPath) {
                Write-PrivateFile (Join-Path $directory ([IO.Path]::GetFileName($path))) ([IO.File]::ReadAllBytes($path))
            }
            $files = foreach ($name in 'db-data.tar.gz', 'app-data.tar.gz', 'runtime.env', 'snapp.pfx', 'prepared.json') {
                $file = Get-Item -LiteralPath (Join-Path $directory $name)
                if (-not $IsWindows) { & chmod 600 -- $file.FullName; if ($LASTEXITCODE -ne 0) { throw 'Could not protect a backup archive.' } }
                [ordered]@{ Name = $name; Length = $file.Length; Sha256 = (Get-FileHash -LiteralPath $file.FullName -Algorithm SHA256).Hash }
            }
            $manifest = [ordered]@{ FormatVersion = 1; Binding = $Settings; CertificateSha256 = $prepared.CertificateSha256
                CreatedUtc = [DateTime]::UtcNow.ToString('o'); Files = @($files) }
            Write-PrivateText (Join-Path $directory 'manifest.json') ($manifest | ConvertTo-Json -Depth 12)
        } finally { Restart-PreviouslyRunning $containers }
        Write-Output "Offline SQL and App_Data backup completed: $directory. The backup includes private credentials and certificate; retain its owner-only permissions."
    }
    'restore' {
        $prepared = Get-Prepared $Settings
        if ($ConfirmRestore -cne $Settings.StackName) { throw 'Restore replaces this project data. Set ConfirmRestore to the exact StackName to authorize it.' }
        if (-not $BackupPath) { throw 'Select a completed backup directory under this project .local/backups.' }
        $directory = if ([IO.Path]::IsPathFullyQualified($BackupPath)) { [IO.Path]::GetFullPath($BackupPath) } else { [IO.Path]::GetFullPath((Join-Path $ProjectDirectory $BackupPath)) }
        $allowed = [IO.Path]::GetFullPath((Join-Path $LocalDirectory 'backups')) + [IO.Path]::DirectorySeparatorChar
        if (-not $directory.StartsWith($allowed, $PathComparison)) { throw 'Restore accepts only a backup beneath this project .local/backups directory.' }
        Assert-PlainPath $directory
        $manifest = Get-Content -LiteralPath (Join-Path $directory 'manifest.json') -Raw | ConvertFrom-Json -AsHashtable
        if ($manifest.FormatVersion -ne 1 -or (Get-BindingJson $manifest.Binding) -cne (Get-BindingJson $Settings) -or $manifest.CertificateSha256 -ne $prepared.CertificateSha256) {
            throw 'Backup binding, image versions or certificate differ from this installation.'
        }
        $expectedNames = @('db-data.tar.gz', 'app-data.tar.gz', 'runtime.env', 'snapp.pfx', 'prepared.json')
        if (@($manifest.Files).Count -ne $expectedNames.Count -or @($manifest.Files.Name | Select-Object -Unique).Count -ne $expectedNames.Count) { throw 'Backup manifest file list is invalid.' }
        foreach ($entry in $manifest.Files) {
            if ($entry.Name -notin $expectedNames) { throw 'Backup manifest contains an unexpected file.' }
            $path = Join-Path $directory $entry.Name
            Assert-PlainPath $path
            if ((Get-Item -LiteralPath $path).Length -ne $entry.Length -or (Get-FileHash -LiteralPath $path -Algorithm SHA256).Hash -ne $entry.Sha256) {
                throw 'Backup file length or SHA256 validation failed. No running services or data were changed.'
            }
        }
        $containers = @(Get-OwnedContainers)
        Assert-OwnedVolumes
        $null = Invoke-Compose @('stop', '--timeout', '60') 'offline restore stop'
        try {
            foreach ($volume in 'db-data', 'app-data') { Invoke-VolumeArchive $volume $directory -Restore }
            foreach ($name in 'runtime.env', 'snapp.pfx', 'prepared.json') {
                Write-PrivateFile (Join-Path $LocalDirectory $name) ([IO.File]::ReadAllBytes((Join-Path $directory $name)))
            }
        } catch { throw 'Restore did not complete; this project services remain stopped. Inspect the selected backup locally before restarting.' }
        Restart-PreviouslyRunning $containers
        Write-Output "Restored $($Settings.StackName) from $directory. SQL and App_Data ownership was preserved; identity sessions require a fresh login. Run verify next."
    }
}
