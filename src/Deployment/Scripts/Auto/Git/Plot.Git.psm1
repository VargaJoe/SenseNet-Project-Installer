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

function Invoke-PlotGitClone {
    [CmdletBinding(SupportsShouldProcess)] param([hashtable]$Settings,$Context)
    Assert-AdapterOperand $Settings.Repository
    $destination=Get-AdapterPath $Settings.Destination $Context
    if (Test-Path -LiteralPath $destination) { throw 'Clone destination already exists.' }
    $arguments=@('clone')
    if ($Settings.Branch) { Assert-AdapterOperand $Settings.Branch; $arguments+=@('--branch',$Settings.Branch) }
    $arguments+=@('--',$Settings.Repository,$destination)
    if ($PSCmdlet.ShouldProcess($destination,'Clone Git repository')) {
        Invoke-AdapterProcess $Settings $Context 'git' $arguments $Context.WorkDirectory
    }
}
function Invoke-PlotGitFetch {
    [CmdletBinding(SupportsShouldProcess)] param([hashtable]$Settings,$Context)
    Assert-AdapterOperand $Settings.Remote
    $directory=Get-AdapterPath $Settings.Directory $Context
    if ($PSCmdlet.ShouldProcess($directory,'Fetch Git remote')) {
        Invoke-AdapterProcess $Settings $Context 'git' @('fetch','--',$Settings.Remote) $directory
    }
}
function Invoke-PlotGitCheckout {
    [CmdletBinding(SupportsShouldProcess)] param([hashtable]$Settings,$Context)
    Assert-AdapterOperand $Settings.Ref
    $directory=Get-AdapterPath $Settings.Directory $Context
    if ($PSCmdlet.ShouldProcess($directory,'Checkout Git ref in detached HEAD')) {
        $status=Invoke-AdapterProcess $Settings $Context 'git' @('status','--porcelain','--untracked-files=normal') $directory
        if (-not [string]::IsNullOrWhiteSpace($status.StandardOutput)) { throw 'Checkout requires a clean worktree, including untracked files.' }
        Invoke-AdapterProcess $Settings $Context 'git' @('checkout','--detach',$Settings.Ref,'--') $directory
    }
}
Export-ModuleMember -Function Invoke-PlotGitClone,Invoke-PlotGitFetch,Invoke-PlotGitCheckout
