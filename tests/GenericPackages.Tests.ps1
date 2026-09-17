# Dot-sourced by Run-Tests.ps1; all fixtures use its random temporary directory.
function Invoke-TestStep($Step,$With,[string]$Directory=$testRoot) {
    Invoke-Plot $registry (New-Config @(@{Step=$Step;With=$With})) demo -WorkDirectory $Directory
}
function Assert-Succeeded($Result) {
    if ($Result.Status -ne 'Succeeded') { throw ("Unexpected step failure: " + $Result.Steps[-1].Error) }
}
$genericRoot=Join-Path $testRoot 'generic [files]'
$null=[IO.Directory]::CreateDirectory($genericRoot)
Test-Case 'Filesystem creates directories, reads UTF-8 and computes a known SHA256' {
    $result=Invoke-TestStep filesystem.mkdir @{Path='input/empty'} $genericRoot
    Assert-Succeeded $result
    Assert-Equal $result.Steps[0].Output.Created $true
    $result=Invoke-TestStep filesystem.mkdir @{Path='input/empty'} $genericRoot
    Assert-Equal $result.Steps[0].Output.Created $false
    $text='caf' + [char]0xe9
    $result=Invoke-TestStep filesystem.write @{Path='input/unicode.txt';Content=$text} $genericRoot
    Assert-Succeeded $result
    $result=Invoke-TestStep filesystem.read @{Path='input/unicode.txt'} $genericRoot
    Assert-Equal $result.Steps[0].Output.Content $text
    Assert-Succeeded (Invoke-TestStep filesystem.write @{Path='input/known.txt';Content='abc'} $genericRoot)
    $result=Invoke-TestStep filesystem.hash @{Path='input/known.txt'} $genericRoot
    Assert-Equal $result.Steps[0].Output.Hash 'ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad'
}
Test-Case 'Directory copy preserves empty directories and checks conflicts before writing' {
    $result=Invoke-TestStep filesystem.copy-tree @{Source='input';Destination='copied'} $genericRoot
    Assert-Succeeded $result
    Assert-Equal $result.Steps[0].Output.Files 2
    Assert-True ([IO.Directory]::Exists((Join-Path $genericRoot 'copied/empty')))
    [IO.File]::WriteAllText((Join-Path $genericRoot 'input/new.txt'),'new')
    $result=Invoke-TestStep filesystem.copy-tree @{Source='input';Destination='copied'} $genericRoot
    Assert-Equal $result.Status 'Failed'
    Assert-True (-not [IO.File]::Exists((Join-Path $genericRoot 'copied/new.txt')))
    Assert-Succeeded (Invoke-TestStep filesystem.copy-tree @{Source='input';Destination='copied';Overwrite=$true} $genericRoot)
    Assert-Equal ([IO.File]::ReadAllText((Join-Path $genericRoot 'copied/new.txt'))) 'new'
    $result=Invoke-TestStep filesystem.copy-tree @{Source='input';Destination='input/nested'} $genericRoot
    Assert-Equal $result.Status 'Failed'
    Assert-True (-not [IO.Directory]::Exists((Join-Path $genericRoot 'input/nested')))
}
Test-Case 'Scoped removal rejects root, parent escape and implicit recursive deletion' {
    foreach ($target in @('.','../outside')) {
        $result=Invoke-TestStep filesystem.remove @{Root='.';Path=$target;Recurse=$true} $genericRoot
        Assert-Equal $result.Status 'Failed'
    }
    $result=Invoke-TestStep filesystem.remove @{Root='.';Path='copied'} $genericRoot
    Assert-Equal $result.Status 'Failed'
    Assert-True ([IO.File]::Exists((Join-Path $genericRoot 'copied/known.txt')))
    $result=Invoke-TestStep filesystem.remove @{Root='.';Path='copied';Recurse=$true} $genericRoot
    Assert-Succeeded $result
    Assert-True (-not [IO.Directory]::Exists((Join-Path $genericRoot 'copied')))
    Assert-Equal (Invoke-TestStep filesystem.remove @{Root='.';Path='missing'} $genericRoot).Status 'Failed'
    $result=Invoke-TestStep filesystem.remove @{Root='.';Path='missing';MissingOk=$true} $genericRoot
    Assert-Succeeded $result
    Assert-Equal $result.Steps[0].Output.Removed $false
}
Test-Case 'ZIP roundtrip preserves files, Unicode names, hidden files and empty directories' {
    $unicodeName='r' + [char]0xe9 + 'port.txt'
    [IO.File]::WriteAllText((Join-Path $genericRoot ('input/'+$unicodeName)),'unicode name')
    $hidden=Join-Path $genericRoot 'input/.hidden'
    [IO.File]::WriteAllText($hidden,'hidden')
    if ([Environment]::OSVersion.Platform -eq [PlatformID]::Win32NT) { [IO.File]::SetAttributes($hidden,[IO.FileAttributes]::Hidden) }
    $result=Invoke-TestStep archive.pack @{Source='input';Destination='bundle.zip'} $genericRoot
    Assert-Succeeded $result
    Assert-Equal $result.Steps[0].Output.Files 5
    $result=Invoke-TestStep archive.unpack @{Source='bundle.zip';Destination='restored'} $genericRoot
    Assert-Succeeded $result
    Assert-Equal $result.Steps[0].Output.Files 5
    Assert-True ([IO.Directory]::Exists((Join-Path $genericRoot 'restored/empty')))
    Assert-Equal ([IO.File]::ReadAllText((Join-Path $genericRoot ('restored/'+$unicodeName)))) 'unicode name'
    Assert-Equal ([IO.File]::ReadAllText((Join-Path $genericRoot 'restored/.hidden'))) 'hidden'
    $original=Invoke-TestStep filesystem.hash @{Path='input/unicode.txt'} $genericRoot
    $restored=Invoke-TestStep filesystem.hash @{Path='restored/unicode.txt'} $genericRoot
    Assert-Equal $original.Steps[0].Output.Hash $restored.Steps[0].Output.Hash
}
Test-Case 'ZIP overwriting is explicit and pack rejects destination inside source' {
    $before=[IO.File]::ReadAllBytes((Join-Path $genericRoot 'bundle.zip'))
    Assert-Equal (Invoke-TestStep archive.pack @{Source='input';Destination='bundle.zip'} $genericRoot).Status 'Failed'
    Assert-Equal ([Convert]::ToBase64String([IO.File]::ReadAllBytes((Join-Path $genericRoot 'bundle.zip')))) ([Convert]::ToBase64String($before))
    Assert-Succeeded (Invoke-TestStep archive.pack @{Source='input';Destination='bundle.zip';Overwrite=$true} $genericRoot)
    Assert-Equal (Invoke-TestStep archive.unpack @{Source='bundle.zip';Destination='restored'} $genericRoot).Status 'Failed'
    Assert-Succeeded (Invoke-TestStep archive.unpack @{Source='bundle.zip';Destination='restored';Overwrite=$true} $genericRoot)
    Assert-Equal (Invoke-TestStep archive.pack @{Source='input';Destination='input/self.zip'} $genericRoot).Status 'Failed'
}
function Write-TestZip([string]$Path,[string[]]$Names) {
    Add-Type -AssemblyName System.IO.Compression
    $stream=[IO.File]::Open($Path,[IO.FileMode]::Create)
    $zip=[IO.Compression.ZipArchive]::new($stream,[IO.Compression.ZipArchiveMode]::Create,$true)
    try {
        foreach ($name in $Names) {
            $entry=$zip.CreateEntry($name)
            if (-not $name.EndsWith('/')) {
                $writer=[IO.StreamWriter]::new($entry.Open())
                try { $writer.Write('fixture') } finally { $writer.Dispose() }
            }
        }
    } finally { $zip.Dispose(); $stream.Dispose() }
}
Test-Case 'ZIP rejects traversal, duplicate targets and file-parent collisions before output' {
    $cases=@(
        @('first.txt','../escape.txt'),
        @('first.txt','/absolute.txt'),
        @('first.txt','C:/drive.txt'),
        @('same.txt','same.txt'),
        @('parent','parent/child.txt')
    )
    $index=0
    foreach ($names in $cases) {
        $zipPath=Join-Path $genericRoot "bad-$index.zip"
        Write-TestZip $zipPath $names
        $result=Invoke-TestStep archive.unpack @{Source=$zipPath;Destination="bad-output-$index"} $genericRoot
        Assert-Equal $result.Status 'Failed'
        Assert-True (-not [IO.Directory]::Exists((Join-Path $genericRoot "bad-output-$index")))
        $index++
    }
    Assert-True (-not [IO.File]::Exists((Join-Path $genericRoot 'escape.txt')))
}
Test-Case 'JSON steps merge nested data with replacement arrays and preserve inputs' {
    Write-TestJson (Join-Path $genericRoot 'data-base.json') @{Nested=@{Keep=1;Change=2};Items=@(1,2);Enabled=$true;Value='old'}
    Write-TestJson (Join-Path $genericRoot 'data-override.json') @{Nested=@{Change=0};Items=@();Enabled=$false;Value=$null}
    $config=New-Config @(
        @{Id='merge';Step='json.merge';With=@{Paths=@('data-base.json','data-override.json')}},
        @{Id='write';Step='json.write';With=@{Path='merged.json';Value=@{'$ref'='steps.merge.Output.Value'}}},
        @{Id='read';Step='json.read';With=@{Path=@{'$ref'='steps.write.Output.Path'}}}
    )
    $result=Invoke-Plot $registry $config demo -WorkDirectory $genericRoot
    Assert-Succeeded $result
    $value=$result.Steps[2].Output.Value
    Assert-Equal $value.Nested.Keep 1
    Assert-Equal $value.Nested.Change 0
    Assert-Equal $value.Items.Count 0
    Assert-Equal $value.Enabled $false
    Assert-True ($null -eq $value.Value)
    Assert-Equal (Invoke-TestStep json.read @{Path='data-base.json'} $genericRoot).Steps[0].Output.Value.Nested.Change 2
}
Test-Case 'JSON invalid inputs fail and writes require explicit overwrite' {
    [IO.File]::WriteAllText((Join-Path $genericRoot 'bad.json'),'{')
    Assert-Equal (Invoke-TestStep json.read @{Path='bad.json'} $genericRoot).Status 'Failed'
    [IO.File]::WriteAllText((Join-Path $genericRoot 'bad.json'),'[{}]')
    Assert-Equal (Invoke-TestStep json.read @{Path='bad.json'} $genericRoot).Status 'Failed'
    Assert-Equal (Invoke-TestStep json.merge @{Paths=@()} $genericRoot).Status 'Failed'
    Assert-Equal (Invoke-TestStep json.merge @{Paths=@(1)} $genericRoot).Status 'Failed'
    Assert-Equal (Invoke-TestStep json.write @{Path='merged.json';Value=@{Changed=$true}} $genericRoot).Status 'Failed'
    Assert-Succeeded (Invoke-TestStep json.write @{Path='merged.json';Value=@{Changed=$true};Overwrite=$true} $genericRoot)
    Assert-Equal (Invoke-TestStep json.read @{Path='merged.json'} $genericRoot).Steps[0].Output.Value.Changed $true
}
Test-Case 'XML updates namespaced attributes and escapes leaf text' {
    [IO.File]::WriteAllText((Join-Path $genericRoot 'source.xml'),'<root xmlns="urn:example"><value enabled="yes">old</value><keep>same</keep></root>')
    $result=Invoke-TestStep xml.set @{Source='source.xml';Destination='attribute.xml';XPath='/x:root/x:value/@enabled';Namespaces=@{x='urn:example'};Value='no'} $genericRoot
    Assert-Succeeded $result
    $result=Invoke-TestStep xml.set @{Source='attribute.xml';Destination='updated.xml';XPath='/x:root/x:value';Namespaces=@{x='urn:example'};Value='a & <b>'} $genericRoot
    Assert-Succeeded $result
    $doc=[xml][IO.File]::ReadAllText((Join-Path $genericRoot 'updated.xml'))
    Assert-Equal $doc.root.value.InnerText 'a & <b>'
    Assert-Equal $doc.root.value.enabled 'no'
    Assert-Equal $doc.root.keep 'same'
}
Test-Case 'XML rejects unmatched, ambiguous, nonleaf and DTD edits without destination writes' {
    [IO.File]::WriteAllText((Join-Path $genericRoot 'multiple.xml'),'<root><value/><value/></root>')
    foreach ($xpath in @('/missing','/root/value','/root')) {
        Assert-Equal (Invoke-TestStep xml.set @{Source='multiple.xml';Destination='invalid-update.xml';XPath=$xpath;Value='x'} $genericRoot).Status 'Failed'
    }
    Assert-True (-not [IO.File]::Exists((Join-Path $genericRoot 'invalid-update.xml')))
    [IO.File]::WriteAllText((Join-Path $genericRoot 'dtd.xml'),'<!DOCTYPE root [<!ENTITY example "data">]><root>&example;</root>')
    Assert-Equal (Invoke-TestStep xml.set @{Source='dtd.xml';Destination='invalid-update.xml';XPath='/root';Value='x'} $genericRoot).Status 'Failed'
    Assert-Equal (Invoke-TestStep xml.set @{Source='source.xml';Destination='updated.xml';XPath='/root';Value='x'} $genericRoot).Status 'Failed'
    Assert-Succeeded (Invoke-TestStep xml.set @{Source='updated.xml';Destination='updated.xml';XPath='/x:root/x:keep';Namespaces=@{x='urn:example'};Value='new';Overwrite=$true} $genericRoot)
}
Test-Case 'Generic write operations honor WhatIf when invoked directly' {
    $context=[pscustomobject]@{WorkDirectory=$genericRoot}
    $operations=@(
        @{Step='filesystem.mkdir';With=@{Path='preview-directory'}},
        @{Step='filesystem.copy-tree';With=@{Source='input';Destination='preview-copy';Overwrite=$false}},
        @{Step='filesystem.remove';With=@{Root='.';Path='restored';Recurse=$true;MissingOk=$false}},
        @{Step='archive.pack';With=@{Source='input';Destination='preview.zip';Overwrite=$false}},
        @{Step='archive.unpack';With=@{Source='bundle.zip';Destination='preview-extract';Overwrite=$false}},
        @{Step='json.write';With=@{Path='preview.json';Value=@{Key='value'};Overwrite=$false}},
        @{Step='xml.set';With=@{Source='multiple.xml';Destination='preview.xml';XPath='/root/value[1]';Value='new';Namespaces=@{};Overwrite=$false}}
    )
    foreach ($operation in $operations) { & $registry.Steps[$operation.Step].Command -Settings $operation.With -Context $context -WhatIf | Out-Null }
    Assert-Equal @(Get-ChildItem -LiteralPath $genericRoot -Filter 'preview*' -Force).Count 0
    Assert-True ([IO.Directory]::Exists((Join-Path $genericRoot 'restored')))
}
Test-Case 'Directory and archive operations reject junctions' {
    if ([Environment]::OSVersion.Platform -ne [PlatformID]::Win32NT) { return }
    $target=Join-Path $testRoot 'junction-target'
    $junction=Join-Path $genericRoot 'input/link'
    $null=[IO.Directory]::CreateDirectory($target)
    $null=New-Item -ItemType Junction -Path $junction -Target $target
    try {
        Assert-Equal (Invoke-TestStep filesystem.copy-tree @{Source='input';Destination='link-copy'} $genericRoot).Status 'Failed'
        Assert-Equal (Invoke-TestStep archive.pack @{Source='input';Destination='link.zip'} $genericRoot).Status 'Failed'
        Assert-Equal (Invoke-TestStep filesystem.remove @{Root='.';Path='input';Recurse=$true} $genericRoot).Status 'Failed'
        Assert-Equal (Invoke-TestStep archive.unpack @{Source='bundle.zip';Destination='input/link'} $genericRoot).Status 'Failed'
        Assert-True ([IO.Directory]::Exists($target))
    } finally {
        # Delete only the literal junction created above, never its target or a recursive tree.
        [IO.Directory]::Delete($junction,$false)
    }
}
Test-Case 'Each new capability package installs independently' {
    foreach ($package in @('Filesystem','Archive','Json','Xml')) {
        $auto=Join-Path $testRoot ('standalone-' + $package)
        $null=[IO.Directory]::CreateDirectory($auto)
        Copy-Item -LiteralPath (Join-Path $scriptsPath "Auto/$package") -Destination $auto -Recurse
        $single=New-PlotRegistry $auto
        try {
            Assert-Equal $single.Packages.Count 1
            $config=switch ($package) {
                Filesystem { New-Config @(@{Step='filesystem.read';With=@{Path='input/known.txt'}}) }
                Archive { New-Config @(@{Step='archive.pack';With=@{Source='input';Destination='standalone.zip'}}) }
                Json { New-Config @(@{Step='json.read';With=@{Path='merged.json'}}) }
                Xml { New-Config @(@{Step='xml.set';With=@{Source='multiple.xml';Destination='standalone.xml';XPath='/root/value[1]';Value='new'}}) }
            }
            Assert-Succeeded (Invoke-Plot $single $config demo -WorkDirectory $genericRoot)
        } finally { Remove-PlotRegistry $single }
    }
}
Test-Case 'Shipped layered artifact example runs through CLI with matching restored content' {
    $work=Join-Path $testRoot 'shipped-example'
    $null=[IO.Directory]::CreateDirectory($work)
    $example=Join-Path $scriptsPath 'Examples/layered-artifact'
    $cli=Invoke-TestCli @('layered-artifact','-DefaultConfigPath',(Join-Path $example 'default.json'),'-ConfigPath',(Join-Path $example 'project.json'),'-EnvironmentConfigPath',(Join-Path $example 'environment.json'),'-WorkDirectory',$work)
    Assert-Equal $cli.Code 0
    $result=$cli.Text | ConvertFrom-Json
    Assert-Succeeded $result
    $original=@($result.Steps | Where-Object Id -eq 'originalHash')[0].Output.Hash
    $restored=@($result.Steps | Where-Object Id -eq 'restoredHash')[0].Output.Hash
    Assert-Equal $original $restored
    $report=[IO.File]::ReadAllText((Join-Path $work 'restored/report.json')) | ConvertFrom-Json
    Assert-Equal $report.Label 'Example project'
    Assert-Equal $report.Environment 'preview'
    Assert-Equal $report.Enabled $false
    Assert-Equal $report.Iterations 0
    Assert-Equal $report.Formatting.Keep 'inherited'
    Assert-True (-not [IO.Directory]::Exists((Join-Path $work 'staging')))
}
