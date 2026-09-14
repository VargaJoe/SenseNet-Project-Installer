# Author a step package

An operator installs a package by copying its complete directory into an Auto folder. Discovery scans direct subdirectories for `package.psd1`. Keep resource paths relative to the package; do not depend on the repository's current directory or global variables.

Example layout:

```text
Auto/
  Example/
    package.psd1
    Plot.Example.psm1
```

## Manifest

```powershell
@{
    Name = 'example'
    Version = '1.0.0'
    RootModule = 'Plot.Example.psm1'
    Dependencies = @() # Installed package names; cycles are rejected.
    Steps = @{
        greet = @{
            Command = 'Get-ExampleGreeting'
            Aliases = @('greet')
            Parameters = @{
                Name = @{ Type='string'; Required=$true }
                Prefix = @{ Type='string'; Default='Hello' }
            }
        }
    }
}
```

The canonical step ID is `example.greet`. Package names, canonical IDs and aliases are compared case-insensitively. An alias can collide with a canonical name, so all names are validated together before module imports. Duplicate errors identify both source manifests.

Name and step keys start with a letter and contain letters, numbers or hyphens. Version must parse as a .NET Version. RootModule must identify a psm1 file inside the package. Optional Platform is Any or Windows.

Dependencies express installed-package requirements and import order. They do not grant access to another module's private functions. Compose cross-package operations in the plot and pass results explicitly.

## Module

```powershell
function Get-ExampleGreeting {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][hashtable]$Settings,
        [Parameter(Mandatory)]$Context
    )
    [pscustomobject]@{ Text="$($Settings.Prefix), $($Settings.Name)" }
}
Export-ModuleMember -Function Get-ExampleGreeting
```

The exported command must accept Settings and Context. The registry invokes its function object, so separate modules can use the same internal function names. Do not export or define global functions or variables.

Context provides RunId, InvocationId, PackageRoot and WorkDirectory. Settings contains only the resolved, validated parameters for this invocation.

Return data on the success stream. Throw on failure. Use Write-Verbose/Write-Information for diagnostics, and never print settings or credentials wholesale. If an external executable is used, inspect LASTEXITCODE immediately and throw on failure; a native nonzero exit is not automatically a PowerShell exception on all supported runtimes.

## Operations and WhatIf

A mutating function should declare SupportsShouldProcess and guard its actual operation with `$PSCmdlet.ShouldProcess(...)`. The engine also guards each step invocation, so native plot WhatIf executes no step functions at all. The function-level guard protects direct calls.

Use the filesystem and IIS packages for examples. The filesystem writer uses CreateNew by default to avoid silently replacing existing files. IIS imports WebAdministration only when an actual operation is requested.

Importing a package executes PowerShell module initialization code. Installed packages are trusted executable code: imports must only define functions and local initialization, without deployment/file/network operations. Static manifest checks are not a sandbox.

## Testing

Run `./tests/Run-Tests.ps1` in PowerShell 5.1 and 7. Add behavior tests when adding package commands. Test a package in a separate Auto directory so accidental dependencies on the full repo are detected.

Historical AutoExt step conventions are documented in [legacy/custom-steps.md](legacy/custom-steps.md). They belong to the separate compatibility runner.
