#requires -Version 5.1
Set-StrictMode -Version Latest
function Resolve-ComposeFile([string]$Path,[string]$Directory) {
    if ([string]::IsNullOrWhiteSpace($Path)) { throw 'Compose file path must not be empty.' }
    if (-not [IO.Path]::IsPathRooted($Path)) { $Path=Join-Path $Directory $Path }
    $Path=[IO.Path]::GetFullPath($Path)
    if (-not [IO.File]::Exists($Path)) { throw "Compose input file does not exist: $Path" }
    $Path
}
function Invoke-ComposeOperation($Settings,$Context,[string]$Operation) {
    if ($Settings.ProjectName -cnotmatch '^[a-z0-9][a-z0-9_-]*$') { throw 'Compose ProjectName must use lowercase letters, digits, underscores and hyphens.' }
    $directory=$Settings.Directory
    if (-not [IO.Path]::IsPathRooted($directory)) { $directory=Join-Path $Context.WorkDirectory $directory }
    $directory=[IO.Path]::GetFullPath($directory)
    if ($Settings.Files.Count -eq 0) { throw 'At least one explicit Compose file is required.' }
    $arguments=@('compose','--project-name',$Settings.ProjectName,'--project-directory',$directory)
    foreach ($path in $Settings.Files) { if ($path -isnot [string]) { throw 'Files must contain strings.' }; $arguments+=@('--file',(Resolve-ComposeFile $path $directory)) }
    foreach ($path in $Settings.EnvFiles) { if ($path -isnot [string]) { throw 'EnvFiles must contain strings.' }; $arguments+=@('--env-file',(Resolve-ComposeFile $path $directory)) }
    foreach ($profile in $Settings.Profiles) {
        if ($profile -isnot [string] -or $profile -notmatch '^[a-zA-Z0-9][a-zA-Z0-9_.-]*$') { throw 'Invalid Compose profile.' }
        $arguments+=@('--profile',$profile)
    }
    $arguments+=$Operation
    if ($Operation -eq 'up') { $arguments+='--detach' }
    foreach ($argument in $Settings.Arguments) { if ($null -eq $argument -or $argument -isnot [string]) { throw 'Arguments must contain strings.' }; $arguments+=$argument }
    foreach ($service in $Settings.Services) {
        if ($service -isnot [string] -or $service -notmatch '^[a-zA-Z0-9][a-zA-Z0-9_.-]*$') { throw 'Invalid Compose service.' }
        $arguments+=$service
    }
    $dependency=$Context.Dependencies['process.run']
    if ($null -eq $dependency) { throw 'The process package dependency is required.' }
    $options=@{}; foreach ($key in $dependency.Defaults.Keys) { $options[$key]=$dependency.Defaults[$key] }
    $options.FilePath='docker'; $options.Arguments=$arguments; $options.WorkingDirectory=$directory
    $options.Environment=$Settings.Environment; $options.TimeoutSeconds=$Settings.TimeoutSeconds
    & $dependency.Command -Settings $options -Context $Context -ErrorAction Stop
}
function Invoke-PlotComposeConfig {
    [CmdletBinding(SupportsShouldProcess)] param([hashtable]$Settings,$Context)
    if ($PSCmdlet.ShouldProcess($Settings.ProjectName,'docker compose config')) { Invoke-ComposeOperation $Settings $Context 'config' }
}
function Invoke-PlotComposePull {
    [CmdletBinding(SupportsShouldProcess)] param([hashtable]$Settings,$Context)
    if ($PSCmdlet.ShouldProcess($Settings.ProjectName,'docker compose pull')) { Invoke-ComposeOperation $Settings $Context 'pull' }
}
function Invoke-PlotComposeBuild {
    [CmdletBinding(SupportsShouldProcess)] param([hashtable]$Settings,$Context)
    if ($PSCmdlet.ShouldProcess($Settings.ProjectName,'docker compose build')) { Invoke-ComposeOperation $Settings $Context 'build' }
}
function Invoke-PlotComposeUp {
    [CmdletBinding(SupportsShouldProcess)] param([hashtable]$Settings,$Context)
    if ($PSCmdlet.ShouldProcess($Settings.ProjectName,'docker compose up')) { Invoke-ComposeOperation $Settings $Context 'up' }
}
function Invoke-PlotComposePs {
    [CmdletBinding(SupportsShouldProcess)] param([hashtable]$Settings,$Context)
    if ($PSCmdlet.ShouldProcess($Settings.ProjectName,'docker compose ps')) { Invoke-ComposeOperation $Settings $Context 'ps' }
}
function Invoke-PlotComposeLogs {
    [CmdletBinding(SupportsShouldProcess)] param([hashtable]$Settings,$Context)
    if ($PSCmdlet.ShouldProcess($Settings.ProjectName,'docker compose logs')) { Invoke-ComposeOperation $Settings $Context 'logs' }
}
function Invoke-PlotComposeStop {
    [CmdletBinding(SupportsShouldProcess)] param([hashtable]$Settings,$Context)
    if ($PSCmdlet.ShouldProcess($Settings.ProjectName,'docker compose stop')) { Invoke-ComposeOperation $Settings $Context 'stop' }
}
function Invoke-PlotComposeDown {
    [CmdletBinding(SupportsShouldProcess)] param([hashtable]$Settings,$Context)
    if ($PSCmdlet.ShouldProcess($Settings.ProjectName,'docker compose down')) { Invoke-ComposeOperation $Settings $Context 'down' }
}
Export-ModuleMember -Function Invoke-PlotCompose*
