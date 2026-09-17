#requires -Version 5.1
Set-StrictMode -Version Latest
. (Join-Path $PSScriptRoot 'JsonText.ps1')

function Copy-PlotValue {
    param([AllowNull()]$Value)
    if ($null -eq $Value) { return $null }
    if ($Value -is [System.Collections.IDictionary]) {
        $copy = @{}
        foreach ($key in $Value.Keys) { $copy[[string]$key] = Copy-PlotValue $Value[$key] }
        return $copy
    }
    if ($Value.GetType() -eq [System.Management.Automation.PSCustomObject]) {
        $copy = @{}
        foreach ($property in $Value.PSObject.Properties) { $copy[$property.Name] = Copy-PlotValue $property.Value }
        return $copy
    }
    if ($Value -is [array]) {
        $copy = [Collections.Generic.List[object]]::new()
        foreach ($item in $Value) { $copy.Add((Copy-PlotValue $item)) }
        return ,$copy.ToArray()
    }
    return $Value
}

function Merge-PlotSettings {
    <#
    .SYNOPSIS
    Deep-copy and merge settings from left to right. Arrays and explicit null replace.
    #>
    [CmdletBinding()]
    param([AllowNull()][object[]]$Layers)
    $merged = @{}
    foreach ($layer in $Layers) {
        if ($null -eq $layer) { continue }
        $source = Copy-PlotValue $layer
        if ($source -isnot [hashtable]) { throw 'Each settings layer must be an object.' }
        foreach ($key in $source.Keys) {
            if ($merged.ContainsKey($key) -and $merged[$key] -is [hashtable] -and $source[$key] -is [hashtable] -and
                -not $source[$key].ContainsKey('$ref') -and -not $source[$key].ContainsKey('$env') -and
                -not $merged[$key].ContainsKey('$ref') -and -not $merged[$key].ContainsKey('$env')) {
                $merged[$key] = Merge-PlotSettings -Layers @($merged[$key], $source[$key])
            } else { $merged[$key] = Copy-PlotValue $source[$key] }
        }
    }
    return $merged
}

function Read-PlotConfiguration {
    <#
    .SYNOPSIS
    Read JSON configuration files in precedence order; later files override earlier files.
    #>
    [CmdletBinding()]
    param([Parameter(Mandatory)][ValidateNotNullOrEmpty()][string[]]$Path)
    $merged = @{}
    foreach ($file in $Path) {
        if ([string]::IsNullOrWhiteSpace($file)) { throw 'Configuration paths must not be empty.' }
        Write-Verbose "Configuration layer: $([IO.Path]::GetFullPath($file))"
        $json = Get-Content -LiteralPath $file -Raw -Encoding UTF8 -ErrorAction Stop
        if ([string]::IsNullOrWhiteSpace($json) -or -not $json.TrimStart().StartsWith('{')) { throw "Configuration must be a JSON object: $file" }
        $configuration = Copy-PlotValue (ConvertFrom-PlotJsonText $json)
        if ($configuration -isnot [hashtable]) { throw "Configuration must be a JSON object: $file" }
        $merged = Merge-PlotSettings -Layers @($merged, $configuration)
    }
    return $merged
}

function Get-PlotMember {
    param($Object, [string]$Name, $Default = $null)
    if ($null -ne $Object -and $Object.ContainsKey($Name)) { return $Object[$Name] }
    return $Default
}

function Resolve-PackagePath {
    param([string]$Root, [string]$RelativePath)
    if ([IO.Path]::IsPathRooted($RelativePath)) { throw 'RootModule must be relative to its package.' }
    $rootPath = [IO.Path]::GetFullPath($Root).TrimEnd('\', '/') + [IO.Path]::DirectorySeparatorChar
    $path = [IO.Path]::GetFullPath((Join-Path $Root $RelativePath))
    if (-not $path.StartsWith($rootPath, [StringComparison]::OrdinalIgnoreCase)) { throw 'RootModule escapes its package.' }
    if (-not (Test-Path -LiteralPath $path -PathType Leaf) -or [IO.Path]::GetExtension($path) -ne '.psm1') {
        throw "Package module not found or not a .psm1 file: $path"
    }
    return $path
}

function New-PlotRegistry {
    <#
    .SYNOPSIS
    Discover installed Auto/<package>/package.psd1 manifests and validate all names before importing.
    #>
    [CmdletBinding()]
    param([Parameter(Mandatory)][string]$AutoPath)
    $packages = @{}
    $steps = @{}
    $names = @{}
    $modules = [Collections.Generic.List[object]]::new()
    foreach ($directory in @(Get-ChildItem -LiteralPath $AutoPath -Directory -ErrorAction Stop | Sort-Object Name)) {
        $manifestPath = Join-Path $directory.FullName 'package.psd1'
        if (-not (Test-Path -LiteralPath $manifestPath -PathType Leaf)) { continue }
        $manifest = Import-PowerShellDataFile -LiteralPath $manifestPath -ErrorAction Stop
        foreach ($required in @('Name','Version','RootModule','Steps')) {
            if (-not $manifest.ContainsKey($required)) { throw "Missing '$required' in $manifestPath" }
        }
        if ((Get-PlotMember $manifest 'Platform' 'Any') -notin @('Any','Windows')) { throw "Unsupported Platform in $manifestPath" }
        $name = [string]$manifest.Name
        if ($name -notmatch '^[a-zA-Z][a-zA-Z0-9-]*$') { throw "Invalid package name '$name' in $manifestPath" }
        if ($packages.ContainsKey($name)) { throw "Duplicate package '$name': $($packages[$name].ManifestPath) and $manifestPath" }
        try { $null = [version]$manifest.Version } catch { throw "Invalid package version in $manifestPath" }
        if ($manifest.Steps -isnot [hashtable] -or $manifest.Steps.Count -eq 0) { throw "Steps must be a non-empty map in $manifestPath" }
        $package = [pscustomobject]@{
            Name=$name; Version=[string]$manifest.Version; Root=$directory.FullName
            ManifestPath=$manifestPath; Manifest=$manifest
            ModulePath=(Resolve-PackagePath $directory.FullName $manifest.RootModule); Module=$null
        }
        $packages[$name] = $package
        foreach ($shortName in $manifest.Steps.Keys) {
            if ($shortName -notmatch '^[a-zA-Z][a-zA-Z0-9-]*$') { throw "Invalid step '$shortName' in $manifestPath" }
            $definition = $manifest.Steps[$shortName]
            if ($definition -isnot [hashtable] -or -not $definition.ContainsKey('Command') -or -not $definition.ContainsKey('Parameters')) {
                throw "Step '$shortName' needs Command and Parameters in $manifestPath"
            }
            if ($definition.Parameters -isnot [hashtable]) { throw "Invalid parameter schema for '$name.$shortName'." }
            foreach ($parameterName in $definition.Parameters.Keys) {
                $schema = $definition.Parameters[$parameterName]
                if ($schema -isnot [hashtable] -or (Get-PlotMember $schema 'Type' '') -notin @('string','int','bool','array','object')) {
                    throw "Invalid type for '$name.$shortName.$parameterName'."
                }
            }
            $id = "$name.$shortName"
            $step = [pscustomobject]@{ Id=$id; Package=$package; Definition=$definition; Command=$null }
            $steps[$id] = $step
            $identifiers = @($id) + @(Get-PlotMember $definition 'Aliases' @())
            foreach ($identifier in $identifiers) {
                if ([string]::IsNullOrWhiteSpace([string]$identifier) -or $identifier -match '[:\s]') { throw "Invalid step identifier in $manifestPath" }
                if ($names.ContainsKey($identifier)) {
                    throw "Duplicate step name '$identifier': $($names[$identifier].Package.ManifestPath) and $manifestPath"
                }
                $names[$identifier] = $step
            }
        }
    }
    # Check dependency existence/cycles before any package code is imported.
    $pending = @($packages.Keys | Sort-Object)
    $ordered = @()
    while ($pending.Count -gt 0) {
        $ready = @()
        foreach ($name in $pending) {
            $dependencies = @(Get-PlotMember $packages[$name].Manifest 'Dependencies' @())
            foreach ($dependency in $dependencies) {
                if (-not $packages.ContainsKey($dependency)) { throw "Package '$name' requires missing package '$dependency'." }
            }
            if (@($dependencies | Where-Object { $_ -notin $ordered }).Count -eq 0) { $ready += $name }
        }
        if ($ready.Count -eq 0) { throw "Package dependency cycle: $($pending -join ', ')" }
        $ordered += $ready
        $pending = @($pending | Where-Object { $_ -notin $ready })
    }
    try {
        foreach ($name in $ordered) {
            $package = $packages[$name]
            $module = Import-Module -Name $package.ModulePath -PassThru -Scope Local -ErrorAction Stop
            $modules.Add($module)
            $package.Module = $module
        }
        foreach ($step in $steps.Values) {
            $commandName = [string]$step.Definition.Command
            if (-not $step.Package.Module.ExportedFunctions.ContainsKey($commandName)) { throw "Step '$($step.Id)' exports no function '$commandName'." }
            $command = $step.Package.Module.ExportedFunctions[$commandName]
            if (-not $command.Parameters.ContainsKey('Settings') -or -not $command.Parameters.ContainsKey('Context')) {
                throw "Step '$($step.Id)' must accept Settings and Context."
            }
            $step.Command = $command
        }
    } catch {
        foreach ($module in $modules) { Remove-Module -ModuleInfo $module -ErrorAction SilentlyContinue }
        throw
    }
    [pscustomobject]@{ Packages=$packages; Steps=$steps; Names=$names; Modules=$modules }
}

function Remove-PlotRegistry {
    [CmdletBinding()]
    param([Parameter(Mandatory)]$Registry)
    foreach ($module in $Registry.Modules) { Remove-Module -ModuleInfo $module -ErrorAction SilentlyContinue }
}

function Get-ReferenceValue {
    param([string]$Path, [hashtable]$Roots)
    $value = $Roots
    foreach ($part in $Path.Split('.')) {
        if ($value -is [Collections.IDictionary] -and $value.Contains($part)) { $value = $value[$part] }
        elseif ($null -ne $value -and $value -isnot [Collections.IDictionary] -and $null -ne $value.PSObject.Properties[$part]) { $value = $value.PSObject.Properties[$part].Value }
        else { throw "Reference '$Path' cannot be resolved." }
    }
    return Copy-PlotValue $value
}

function Resolve-PlotValue {
    param($Value, [hashtable]$Roots, [string[]]$PreviousIds, [switch]$Preflight, [string[]]$ReferenceStack = @())
    if ($Value -is [hashtable]) {
        if ($Value.ContainsKey('$ref')) {
            if ($Value.Count -ne 1 -or $Value['$ref'] -isnot [string]) { throw 'A $ref object must contain only a string $ref.' }
            $path = $Value['$ref']
            if ($path -notmatch '^(settings|steps)\.') { throw "Unsupported reference '$path'." }
            if ($path.StartsWith('steps.', [StringComparison]::OrdinalIgnoreCase)) {
                $parts = $path.Split('.')
                if ($parts.Count -lt 3 -or $parts[1] -notin $PreviousIds) { throw "Reference '$path' must address an earlier invocation." }
                if ($Preflight) { return Copy-PlotValue $Value }
                # Output is data, not a new source of configuration directives.
                return Get-ReferenceValue $path $Roots
            }
            if ($path -in $ReferenceStack) {
                throw "Circular settings reference: $( (@($ReferenceStack) + $path) -join ' -> ' )."
            }
            if ($ReferenceStack.Count -ge 64) { throw 'Settings reference chain exceeds the limit of 64 references.' }
            $selected = Get-ReferenceValue $path $Roots
            # Keep ancestry local to this branch so repeated sibling references are valid.
            return Resolve-PlotValue $selected $Roots $PreviousIds -Preflight:$Preflight -ReferenceStack (@($ReferenceStack) + $path)
        }
        if ($Value.ContainsKey('$env')) {
            if ($Value.Count -ne 1 -or $Value['$env'] -isnot [string]) { throw 'An $env object must contain only a string $env.' }
            $environmentValue = [Environment]::GetEnvironmentVariable($Value['$env'])
            if ($null -eq $environmentValue) { throw "Environment variable '$($Value['$env'])' is missing." }
            return $environmentValue
        }
        $resolved = @{}
        foreach ($key in $Value.Keys) { $resolved[$key] = Resolve-PlotValue $Value[$key] $Roots $PreviousIds -Preflight:$Preflight -ReferenceStack $ReferenceStack }
        return $resolved
    }
    if ($Value -is [array]) {
        $resolved = [Collections.Generic.List[object]]::new()
        foreach ($item in $Value) { $resolved.Add((Resolve-PlotValue $item $Roots $PreviousIds -Preflight:$Preflight -ReferenceStack $ReferenceStack)) }
        return ,$resolved.ToArray()
    }
    return $Value
}

function Test-DeferredValue {
    param($Value)
    if ($Value -is [hashtable]) {
        if ($Value.ContainsKey('$ref')) { return $true }
        foreach ($item in $Value.Values) { if (Test-DeferredValue $item) { return $true } }
    } elseif ($Value -is [array]) {
        foreach ($item in $Value) { if (Test-DeferredValue $item) { return $true } }
    }
    return $false
}

function Convert-StepParameters {
    param([hashtable]$Settings, [hashtable]$Schema, [string]$InvocationId, [switch]$Preflight)
    foreach ($key in $Settings.Keys) {
        if (-not $Schema.ContainsKey($key)) { throw "Invocation '$InvocationId': unknown parameter '$key'." }
    }
    $converted = Copy-PlotValue $Settings
    foreach ($key in $Schema.Keys) {
        $rule = $Schema[$key]
        if (-not $converted.ContainsKey($key)) {
            if (Get-PlotMember $rule 'Required' $false) { throw "Invocation '$InvocationId': required parameter '$key' is missing." }
            continue
        }
        $value = $converted[$key]
        if ($Preflight -and (Test-DeferredValue $value)) { continue }
        if ($null -eq $value) {
            if (-not (Get-PlotMember $rule 'AllowNull' $false)) { throw "Invocation '$InvocationId': '$key' cannot be null." }
            continue
        }
        $valid = $true
        switch ($rule.Type) {
            'string' {
                $valid = $value -is [string]
                if ((Get-PlotMember $rule 'Required' $false) -and [string]::IsNullOrWhiteSpace([string]$value)) { $valid = $false }
            }
            'int' {
                if ($value -is [string]) {
                    $number = 0
                    $valid = [int]::TryParse($value, [ref]$number)
                    if ($valid) { $converted[$key] = $number }
                } else { $valid = $value -is [int] -or ($value -is [long] -and $value -ge [int]::MinValue -and $value -le [int]::MaxValue) }
            }
            'bool' {
                if ($value -is [string]) {
                    $boolean = $false
                    $valid = [bool]::TryParse($value, [ref]$boolean)
                    if ($valid) { $converted[$key] = $boolean }
                } else { $valid = $value -is [bool] }
            }
            'array' { $valid = $value -is [array] }
            'object' { $valid = $value -is [hashtable] }
        }
        if (-not $valid) { throw "Invocation '$InvocationId': parameter '$key' must be $($rule.Type)." }
        if ($rule.ContainsKey('ValidateSet') -and $converted[$key] -notin $rule.ValidateSet) { throw "Invocation '$InvocationId': '$key' is outside its allowed values." }
        if ($rule.ContainsKey('Minimum') -and $converted[$key] -lt $rule.Minimum) { throw "Invocation '$InvocationId': '$key' is below its minimum." }
        if ($rule.ContainsKey('Maximum') -and $converted[$key] -gt $rule.Maximum) { throw "Invocation '$InvocationId': '$key' exceeds its maximum." }
    }
    return $converted
}

function Update-PlotSources {
    param([hashtable]$Sources, [hashtable]$Layer, [string]$Label, [string]$Prefix = '')
    foreach ($key in $Layer.Keys) {
        $path = if ($Prefix) { "$Prefix.$key" } else { [string]$key }
        $value = $Layer[$key]
        if ($value -is [hashtable] -and $value.Count -eq 0 -and @($Sources.Keys | Where-Object { $_.StartsWith("$path.", [StringComparison]::OrdinalIgnoreCase) }).Count -gt 0) { continue }
        if ($value -is [hashtable] -and -not $value.ContainsKey('$ref') -and -not $value.ContainsKey('$env') -and $value.Count -gt 0) {
            $Sources.Remove($path)
            Update-PlotSources $Sources $value $Label $path
        } else {
            foreach ($oldPath in @($Sources.Keys)) {
                if ($oldPath.StartsWith("$path.", [StringComparison]::OrdinalIgnoreCase)) { $Sources.Remove($oldPath) }
            }
            $Sources[$path] = $Label
        }
    }
}
function Get-PlotPlan {
    [CmdletBinding()]
    param([Parameter(Mandatory)]$Registry, [Parameter(Mandatory)][hashtable]$Configuration,
        [Parameter(Mandatory)][string]$Plot, [hashtable]$Overrides = @{})
    $plots = Get-PlotMember $Configuration 'Plots' @{}
    if (-not $plots.ContainsKey($Plot)) { throw "Plot '$Plot' does not exist." }
    $plotDefinition = $plots[$Plot]
    if ($plotDefinition -is [array]) { $plotDefinition = @{ Steps=$plotDefinition } }
    if ($plotDefinition -isnot [hashtable] -or -not $plotDefinition.ContainsKey('Steps')) { throw "Plot '$Plot' must declare Steps." }
    $plan = [Collections.Generic.List[object]]::new()
    $ids = @{}
    $previousIds = @()
    $roots = @{ settings=$Configuration; steps=@{} }
    $index = 0
    foreach ($invocation in @($plotDefinition.Steps)) {
        $index++
        if ($invocation -is [string]) {
            $parts = $invocation.Split(':', 2)
            $invocation = @{ Step=$parts[0] }
            if ($parts.Count -eq 2) { $invocation.Section = $parts[1] }
        }
        if ($invocation -isnot [hashtable] -or -not $invocation.ContainsKey('Step')) { throw "Invalid invocation $index in plot '$Plot'." }
        $id = [string](Get-PlotMember $invocation 'Id' "step$index")
        if ($id -notmatch '^[a-zA-Z][a-zA-Z0-9_-]*$' -or $ids.ContainsKey($id)) { throw "Invalid or duplicate invocation id '$id'." }
        $ids[$id] = $true
        $stepName = [string]$invocation.Step
        if (-not $Registry.Names.ContainsKey($stepName)) { throw "Invocation '$id': step '$stepName' is not installed." }
        $step = $Registry.Names[$stepName]
        $platform = Get-PlotMember $step.Package.Manifest 'Platform' 'Any'
        if ($platform -eq 'Windows' -and [Environment]::OSVersion.Platform -ne [PlatformID]::Win32NT) { throw "Package '$($step.Package.Name)' requires Windows." }
        $defaultValues = @{}
        foreach ($key in $step.Definition.Parameters.Keys) {
            $rule = $step.Definition.Parameters[$key]
            if ($rule.ContainsKey('Default')) { $defaultValues[$key] = Copy-PlotValue $rule.Default }
        }
        $stepDefaults = Get-PlotMember (Get-PlotMember $Configuration 'StepDefaults' @{}) $step.Id @{}
        $section = @{}
        if ($invocation.ContainsKey('Section')) {
            if (-not $Configuration.ContainsKey($invocation.Section)) { throw "Invocation '$id': configuration section '$($invocation.Section)' is missing." }
            $section = $Configuration[$invocation.Section]
        }
        $layers = @($defaultValues, (Get-PlotMember $Configuration 'Defaults' @{}), $stepDefaults, $section,
            (Get-PlotMember $plotDefinition 'Defaults' @{}), (Get-PlotMember $invocation 'With' @{}), (Get-PlotMember $Overrides $id @{}))
        $labels = @('step default','configuration default','step configuration','section','plot default','invocation','override')
        $sources = @{}
        for ($i=0; $i -lt $layers.Count; $i++) {
            if ($layers[$i] -isnot [hashtable]) { throw "Invocation '$id': each settings layer must be an object." }
            Update-PlotSources $sources $layers[$i] $labels[$i]
        }
        $settings = Merge-PlotSettings -Layers $layers
        $settings = Resolve-PlotValue $settings $roots $previousIds -Preflight
        $null = Convert-StepParameters $settings $step.Definition.Parameters $id -Preflight
        $plan.Add([pscustomobject]@{ Id=$id; Step=$step; Settings=$settings; Sources=$sources; PreviousIds=@($previousIds) })
        $previousIds += $id
    }
    foreach ($id in $Overrides.Keys) { if (-not $ids.ContainsKey($id)) { throw "Override targets unknown invocation '$id'." } }
    return ,$plan.ToArray()
}

function Invoke-Plot {
    <#
    .SYNOPSIS
    Preflight and execute a plot, stopping on the first error and returning a structured result.
    #>
    [CmdletBinding(SupportsShouldProcess)]
    param([Parameter(Mandatory)]$Registry, [Parameter(Mandatory)][hashtable]$Configuration,
        [Parameter(Mandatory)][string]$Plot, [hashtable]$Overrides=@{},
        [string]$WorkDirectory=(Get-Location).Path)
    $plan = Get-PlotPlan -Registry $Registry -Configuration $Configuration -Plot $Plot -Overrides $Overrides
    $runId = [guid]::NewGuid().ToString()
    $results = [Collections.Generic.List[object]]::new()
    $roots = @{ settings=(Copy-PlotValue $Configuration); steps=@{} }
    $status = 'Succeeded'
    foreach ($invocation in $plan) {
        $timer = [Diagnostics.Stopwatch]::StartNew()
        $stepStatus = 'Succeeded'
        $outputValue = $null
        $errorMessage = $null
        $settings = @{}
        try {
            if ($PSCmdlet.ShouldProcess("$Plot/$($invocation.Id) [$($invocation.Step.Id)]", 'Execute step')) {
                $settings = Resolve-PlotValue $invocation.Settings $roots $invocation.PreviousIds
                $settings = Convert-StepParameters $settings $invocation.Step.Definition.Parameters $invocation.Id
                $context = [pscustomobject]@{ RunId=$runId; InvocationId=$invocation.Id; PackageRoot=$invocation.Step.Package.Root; WorkDirectory=[IO.Path]::GetFullPath($WorkDirectory) }
                $dependencies = @{}
                foreach ($dependency in @(Get-PlotMember $invocation.Step.Package.Manifest 'Dependencies' @())) {
                    foreach ($dependencyStep in $Registry.Steps.Values | Where-Object { $_.Package.Name -eq $dependency }) {
                        $defaults = @{}
                        foreach ($key in $dependencyStep.Definition.Parameters.Keys) {
                            $rule = $dependencyStep.Definition.Parameters[$key]
                            if ($rule.ContainsKey('Default')) { $defaults[$key] = Copy-PlotValue $rule.Default }
                        }
                        $dependencies[$dependencyStep.Id] = [pscustomobject]@{ Command=$dependencyStep.Command; Defaults=$defaults }
                    }
                }
                $context | Add-Member -NotePropertyName Dependencies -NotePropertyValue $dependencies
                Write-Verbose "[$runId/$($invocation.Id)] $($invocation.Step.Id); parameter sources: $(($invocation.Sources.GetEnumerator() | Sort-Object Key | ForEach-Object { "$($_.Key)=$($_.Value)" }) -join ', ')"
                $output = @(& $invocation.Step.Command -Settings (Copy-PlotValue $settings) -Context $context -ErrorAction Stop)
                if ($output.Count -eq 1) { $outputValue = $output[0] } elseif ($output.Count -gt 1) { $outputValue = $output }
            } else { $stepStatus = 'Skipped'; $status = 'Skipped' }
        } catch {
            $stepStatus = 'Failed'
            $status = 'Failed'
            $errorMessage = $_.Exception.Message
            foreach ($key in $invocation.Step.Definition.Parameters.Keys) {
                if ((Get-PlotMember $invocation.Step.Definition.Parameters[$key] 'Secret' $false) -and $settings.ContainsKey($key) -and $null -ne $settings[$key]) {
                    $secret = [string]$settings[$key]
                    if ($secret.Length -gt 0) { $errorMessage = $errorMessage.Replace($secret, '[redacted]') }
                }
            }
        } finally { $timer.Stop() }
        $result = [pscustomobject]@{ Id=$invocation.Id; Step=$invocation.Step.Id; Status=$stepStatus; Output=$outputValue; Error=$errorMessage; DurationMs=$timer.ElapsedMilliseconds }
        $results.Add($result)
        $roots.steps[$invocation.Id] = @{ Output=$outputValue; Status=$stepStatus }
        if ($stepStatus -eq 'Failed') { break }
    }
    [pscustomobject]@{ RunId=$runId; Plot=$Plot; Status=$status; Steps=$results.ToArray() }
}

Export-ModuleMember -Function ConvertFrom-PlotJsonText, Copy-PlotValue, Merge-PlotSettings, Read-PlotConfiguration, New-PlotRegistry, Remove-PlotRegistry, Get-PlotPlan, Invoke-Plot
