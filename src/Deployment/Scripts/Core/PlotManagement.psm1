#requires -Version 5.1
Set-StrictMode -Version Latest
Import-Module (Join-Path $PSScriptRoot 'PlotManager.psm1') -ErrorAction Stop

function Get-ManagedConfiguration {
    param([string[]]$Files = @())
    $sources = @{}
    $layers = @()
    $merged = @{}
    # Use the engine's reader/merge and provenance logic, including atomic directives.
    $engine = Get-Module PlotManager
    foreach ($file in $Files) {
        $path = [IO.Path]::GetFullPath($file)
        $data = Read-PlotConfiguration @($path)
        & $engine { param($s,$d,$p) Update-PlotSources $s $d $p } $sources $data $path
        $merged = Merge-PlotSettings @($merged,$data)
        $layers += [pscustomobject]@{ Path=$path; Data=$data }
    }
    [pscustomobject]@{ Configuration=$merged; Sources=$sources; Layers=@($layers) }
}

function Get-ManagedSourceFile {
    param([hashtable]$Sources,[string]$Path)
    # Arrays replace as a whole, so descendents inherit the nearest recorded parent.
    while ($Path) {
        if ($Sources.ContainsKey($Path)) { return $Sources[$Path] }
        $last = $Path.LastIndexOf('.')
        if ($last -lt 0) { break }
        $Path = $Path.Substring(0,$last)
    }
    return $null
}

function Get-ManagedOrigins {
    param($PlanItem,[hashtable]$Configuration,[hashtable]$Sources,[string]$Plot,[int]$Index)
    $origins = @{}
    $plotValue = $Configuration.Plots[$Plot]
    $plotPath = "Plots.$Plot"
    $invocationPath = "$plotPath.Steps.$Index"
    $raw = $null
    if ($plotValue -is [array]) { $raw=$plotValue[$Index]; $invocationPath="$plotPath.$Index" }
    else { $raw=$plotValue.Steps[$Index] }
    foreach ($key in $PlanItem.Sources.Keys) {
        $label = $PlanItem.Sources[$key]
        $path = $null; $file = $null
        switch ($label) {
            'step default' { $file=$PlanItem.Step.Package.ManifestPath; $path="Steps.$($PlanItem.Step.Id.Split('.')[1]).Parameters.$key.Default" }
            'configuration default' { $path="Defaults.$key" }
            'step configuration' { $path="StepDefaults.$($PlanItem.Step.Id).$key" }
            'section' {
                $section=if ($raw -is [string]) { $raw.Split(':',2)[1] } else { $raw.Section }
                $path="$section.$key"
            }
            'plot default' { $path="$plotPath.Defaults.$key" }
            'invocation' { $path="$invocationPath.With.$key" }
            'override' { $path="Overrides.$($PlanItem.Id).$key"; $file='run override' }
        }
        if (-not $file) { $file=Get-ManagedSourceFile $Sources $path }
        $engine=Get-Module PlotManager
        $rawValue=& $engine { param($k,$v) Get-ReferenceValue "input.$k" @{input=$v} } $key $PlanItem.RawSettings
        $references=@(Get-ManagedReferenceOrigins $rawValue $Configuration $Sources)
        $origins[$key]=[pscustomobject]@{ Layer=$label; File=$file; Path=$path; References=$references }
    }
    return $origins
}

function Get-ManagedReferenceOrigins {
    param($Value,[hashtable]$Configuration,[hashtable]$Sources,[string[]]$Stack=@())
    if ($Value -is [hashtable]) {
        if ($Value.ContainsKey('$ref')) {
            $reference=[string]$Value['$ref']
            if ($reference.StartsWith('settings.',[StringComparison]::OrdinalIgnoreCase)) {
                $path=$reference.Substring(9)
                [pscustomobject]@{Reference=$reference;File=(Get-ManagedSourceFile $Sources $path);Path=$path}
                if ($reference -notin $Stack -and $Stack.Count -lt 64) {
                    $engine=Get-Module PlotManager
                    $selected=& $engine {param($r,$c) Get-ReferenceValue $r @{settings=$c}} $reference $Configuration
                    Get-ManagedReferenceOrigins $selected $Configuration $Sources (@($Stack)+$reference)
                }
            } else { [pscustomobject]@{Reference=$reference;File='earlier output';Path=$reference} }
        } elseif ($Value.ContainsKey('$env')) {
            [pscustomobject]@{Reference=('$env:'+$Value['$env']);File='runner environment / secret store';Path=$Value['$env']}
        } else { foreach ($item in $Value.Values) { Get-ManagedReferenceOrigins $item $Configuration $Sources $Stack } }
    } elseif ($Value -is [array]) { foreach ($item in $Value) { Get-ManagedReferenceOrigins $item $Configuration $Sources $Stack } }
}

function Get-ManagedCatalog {
    param($Registry)
    $windows=[Environment]::OSVersion.Platform -eq [PlatformID]::Win32NT
    $steps=@(foreach ($step in ($Registry.Steps.Values | Sort-Object Id)) {
        $parameters=Copy-PlotValue $step.Definition.Parameters
        foreach ($rule in $parameters.Values) { if ($rule.ContainsKey('Secret') -and $rule.Secret) { $rule.Remove('Default') } }
        $platform='Any'; if ($step.Package.Manifest.ContainsKey('Platform')) { $platform=$step.Package.Manifest.Platform }
        $tools=@(); if ($step.Package.Manifest.ContainsKey('RequiresCommands')) {
            $tools=@(foreach ($name in $step.Package.Manifest.RequiresCommands) { [pscustomobject]@{Name=$name;Available=($null -ne (Get-Command $name -CommandType Application -ErrorAction SilentlyContinue | Select-Object -First 1))} })
        }
        if ($step.Package.Manifest.ContainsKey('RequiresModules')) {
            $tools+=@(foreach ($name in $step.Package.Manifest.RequiresModules) { [pscustomobject]@{Name="PowerShell module: $name";Available=($null -ne (Get-Module -ListAvailable -Name $name | Select-Object -First 1))} })
        }
        $outputs=@{}; if ($step.Definition.ContainsKey('Outputs')) { $outputs=Copy-PlotValue $step.Definition.Outputs }
        $description=$step.Id; if ($step.Definition.ContainsKey('Description')) { $description=$step.Definition.Description }
        [pscustomobject]@{ Id=$step.Id; Package=$step.Package.Name; Version=$step.Package.Version; Parameters=$parameters; Description=$description; Outputs=$outputs; Platform=$platform; Supported=($platform -ne 'Windows' -or $windows); Tools=@($tools) }
    })
    [pscustomobject]@{ ProtocolVersion=1; Steps=@($steps); Packages=@($Registry.Packages.Values | Sort-Object Name | ForEach-Object { [pscustomobject]@{Name=$_.Name;Version=$_.Version} }) }
}

function Find-ManagedSecrets {
    param($Value,[Collections.Generic.HashSet[string]]$Secrets)
    if ($Value -is [hashtable]) {
        if ($Value.ContainsKey('$env') -and $Value['$env'] -is [string]) {
            $secret=[Environment]::GetEnvironmentVariable($Value['$env'])
            if (-not [string]::IsNullOrEmpty($secret)) { $null=$Secrets.Add($secret) }
        }
        foreach ($item in $Value.Values) { Find-ManagedSecrets $item $Secrets }
    } elseif ($Value -is [array]) { foreach ($item in $Value) { Find-ManagedSecrets $item $Secrets } }
}

function Add-ManagedSecretStrings {
    param($Value,[Collections.Generic.HashSet[string]]$Secrets)
    if ($Value -is [string] -and $Value.Length) { $null=$Secrets.Add($Value) }
    elseif ($Value -is [hashtable]) { foreach ($item in $Value.Values) { Add-ManagedSecretStrings $item $Secrets } }
    elseif ($Value -is [array]) { foreach ($item in $Value) { Add-ManagedSecretStrings $item $Secrets } }
}

function Protect-ManagedValue {
    param($Value,[Collections.Generic.HashSet[string]]$Secrets,[switch]$PreserveKeys,[switch]$PreserveDirectives)
    if ($null -eq $Value) { return $null }
    if ($Value -is [Collections.IDictionary]) {
        # Raw references name configuration/environment entries; they are not
        # evaluated secret data. Never corrupt a binding while displaying it.
        if ($PreserveDirectives -and ($Value.Contains('$env') -or $Value.Contains('$ref'))) { return Copy-PlotValue $Value }
        $copy=@{}
        foreach ($key in $Value.Keys) {
            $name=[string]$key
            if (-not $PreserveKeys) { $name=Protect-ManagedValue $name $Secrets }
            $unique=$name; $suffix=1
            while ($copy.ContainsKey($unique)) { $unique=$name+'#'+$suffix; $suffix++ }
            $copy[$unique]=Protect-ManagedValue $Value[$key] $Secrets -PreserveKeys:$PreserveKeys -PreserveDirectives:$PreserveDirectives
        }
        return $copy
    }
    if ($Value.GetType() -eq [Management.Automation.PSCustomObject]) {
        $copy=@{}
        foreach ($property in $Value.PSObject.Properties) {
            $name=$property.Name
            if (-not $PreserveKeys) { $name=Protect-ManagedValue $name $Secrets }
            $unique=$name; $suffix=1
            while ($copy.ContainsKey($unique)) { $unique=$name+'#'+$suffix; $suffix++ }
            $copy[$unique]=Protect-ManagedValue $property.Value $Secrets -PreserveKeys:$PreserveKeys -PreserveDirectives:$PreserveDirectives
        }
        return $copy
    }
    if ($Value -is [array]) {
        $items=[Collections.Generic.List[object]]::new()
        foreach ($item in $Value) { $items.Add((Protect-ManagedValue $item $Secrets -PreserveKeys:$PreserveKeys -PreserveDirectives:$PreserveDirectives)) }
        return ,$items.ToArray()
    }
    if ($Value -is [string]) {
        $tokens=@($Secrets | Sort-Object Length -Descending | ForEach-Object { [regex]::Escape($_) })
        if ($tokens.Count) { $Value=[regex]::Replace($Value,($tokens -join '|'),'[redacted]') }
    } elseif ($Secrets.Contains([Convert]::ToString($Value,[Globalization.CultureInfo]::InvariantCulture))) {
        return '[redacted]'
    }
    return $Value
}

function Invoke-ManagedPlotRequest {
    [CmdletBinding()]
    param([Parameter(Mandatory)][hashtable]$Request,[string]$AutoPath=(Join-Path $PSScriptRoot '../Auto'),[scriptblock]$OnEvent)
    $allowed=@('Operation','ConfigurationFiles','Plot','InvocationId','Overrides','WorkDirectory','WhatIf')
    foreach ($key in $Request.Keys) { if ($key -notin $allowed) { throw "Unknown managed request field: $key" } }
    if (-not $Request.ContainsKey('Operation') -or $Request.Operation -notin @('catalog','inspect','plan','run')) { throw 'Invalid managed operation.' }
    if ($Request.ContainsKey('WhatIf') -and $Request.WhatIf -isnot [bool]) { throw 'WhatIf must be a JSON boolean.' }
    foreach ($key in @('Plot','InvocationId','WorkDirectory')) {
        if ($Request.ContainsKey($key) -and ($Request[$key] -isnot [string] -or [string]::IsNullOrWhiteSpace($Request[$key]))) { throw "$key must be a nonempty string." }
    }
    $files=@()
    if ($Request.ContainsKey('ConfigurationFiles')) {
        if ($Request.ConfigurationFiles -isnot [array]) { throw 'ConfigurationFiles must be an ordered array.' }
        foreach ($file in $Request.ConfigurationFiles) {
            if ($file -isnot [string] -or [string]::IsNullOrWhiteSpace($file)) { throw 'Configuration paths must be nonempty strings.' }
            $files+=$file
        }
    }
    $info=Get-ManagedConfiguration $files
    $secrets=[Collections.Generic.HashSet[string]]::new([StringComparer]::Ordinal)
    Find-ManagedSecrets $info.Configuration $secrets
    $overrides=@{}
    if ($Request.ContainsKey('Overrides')) {
        if ($Request.Overrides -isnot [hashtable]) { throw 'Overrides must be an object.' }
        $overrides=$Request.Overrides
        Find-ManagedSecrets $overrides $secrets
    }
    $registry=$null
    try {
        # Inspect contains raw configuration references and source paths, never
        # their evaluated values. Protocol metadata must not be substring-masked.
        if ($Request.Operation -eq 'inspect') { return $info }
        $registry=New-PlotRegistry $AutoPath
        if ($Request.Operation -eq 'catalog') { return Get-ManagedCatalog $registry }
        if (-not $Request.ContainsKey('Plot')) { throw 'Plot is required.' }
        $plan=Get-PlotPlan $registry $info.Configuration $Request.Plot -Overrides $overrides -InvocationId $Request['InvocationId']
        foreach ($item in $plan) {
            foreach ($key in $item.Step.Definition.Parameters.Keys) {
                $rule=$item.Step.Definition.Parameters[$key]
                if ($rule.ContainsKey('Secret') -and $rule.Secret -and $item.Settings.ContainsKey($key) -and $null -ne $item.Settings[$key]) {
                    Add-ManagedSecretStrings $item.Settings[$key] $secrets
                }
            }
        }
        if ($Request.Operation -eq 'plan') {
            $items=@(foreach ($item in $plan) {
                $origins=Get-ManagedOrigins $item $info.Configuration $info.Sources $Request.Plot $item.Index
                $safeSettings=@{}
                foreach ($key in $item.Settings.Keys) { $safeSettings[$key]=Protect-ManagedValue $item.Settings[$key] $secrets }
                [pscustomobject]@{Id=$item.Id;Step=$item.Step.Id;Settings=$safeSettings;Sources=$item.Sources;Origins=$origins}
            })
            $safeConfiguration=Protect-ManagedValue $info.Configuration $secrets -PreserveKeys -PreserveDirectives
            return [pscustomobject]@{ProtocolVersion=1;Steps=@($items);Configuration=$safeConfiguration;ConfigurationSources=$info.Sources}
        }
        $directory=(Get-Location).Path; if ($Request.ContainsKey('WorkDirectory')) { $directory=$Request.WorkDirectory }
        if (-not [IO.Directory]::Exists($directory)) { throw 'WorkDirectory must exist.' }
        $args=@{Registry=$registry;Configuration=$info.Configuration;Plot=$Request.Plot;Overrides=$overrides;WorkDirectory=$directory;OnEvent=$OnEvent}
        if ($Request.ContainsKey('InvocationId')) { $args.InvocationId=$Request.InvocationId }
        $preview=$Request.ContainsKey('WhatIf') -and $Request.WhatIf
        $result=Invoke-Plot @args -WhatIf:$preview
        foreach ($item in $result.Steps) {
            $item.Output=Protect-ManagedValue $item.Output $secrets
            $item.Error=Protect-ManagedValue $item.Error $secrets
        }
        return $result
    } finally { if ($registry) { Remove-PlotRegistry $registry } }
}
Export-ModuleMember -Function Invoke-ManagedPlotRequest,Get-ManagedConfiguration
