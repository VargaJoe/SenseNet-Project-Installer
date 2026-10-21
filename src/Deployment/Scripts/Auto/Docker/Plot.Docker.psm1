#requires -Version 5.1
Set-StrictMode -Version Latest
function Invoke-AdapterProcess($Settings,$Context,[string]$Executable,$Arguments,[string]$Directory) {
    foreach ($argument in @($Arguments)) {
        if ($null -eq $argument -or $argument -isnot [string]) { throw 'Arguments must contain strings.' }
    }
    $dependency=$Context.Dependencies['process.run']
    if ($null -eq $dependency) { throw 'The process package dependency is required.' }
    $options=@{}
    foreach ($key in $dependency.Defaults.Keys) { $options[$key]=$dependency.Defaults[$key] }
    $options.FilePath=$Executable; $options.Arguments=$Arguments; $options.WorkingDirectory=$Directory
    $options.TimeoutSeconds=$Settings.TimeoutSeconds; $options.Environment=$Settings.Environment
    & $dependency.Command -Settings $options -Context $Context -ErrorAction Stop
}
function Get-AdapterPath([string]$Path,$Context) {
    if ([string]::IsNullOrWhiteSpace($Path)) { throw 'Path must not be empty.' }
    if (-not [IO.Path]::IsPathRooted($Path)) { $Path=Join-Path $Context.WorkDirectory $Path }
    [IO.Path]::GetFullPath($Path)
}
function Assert-AdapterOperand([string]$Value) {
    if ([string]::IsNullOrWhiteSpace($Value) -or $Value.StartsWith('-') -or $Value.Contains([char]0)) { throw 'Operand must be nonempty and must not start with a dash.' }
}

function Invoke-PlotDocker {
    [CmdletBinding(SupportsShouldProcess)] param([hashtable]$Settings,$Context)
    $directory=Get-AdapterPath $Settings.Directory $Context
    $allowed=@('build','pull','push','tag','run','start','stop','rm','inspect','network-create','network-inspect','network-connect','network-disconnect','network-rm')
    if ($Settings.Command -notin $allowed) { throw 'Unsupported Docker command.' }
    $arguments=@($Settings.Command -split '-')+@($Settings.Arguments)
    if ($PSCmdlet.ShouldProcess($directory,('docker '+$Settings.Command))) {
        Invoke-AdapterProcess $Settings $Context 'docker' $arguments $directory
    }
}
Export-ModuleMember -Function Invoke-PlotDocker
