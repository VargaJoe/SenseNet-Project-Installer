[CmdletBinding(SupportsShouldProcess = $True)]
Param(
    [Parameter(Mandatory = $true)]
    [string]$FilePath,
    [Parameter(Mandatory = $true)]
    [string]$SnippetPath,
    [Parameter(Mandatory = $false)]
    [string]$Filter = "</head>",
    [Parameter(Mandatory = $false)]
    [boolean]$IsBefore = $true,
    [Parameter(Mandatory = $false)]
    [string]$OutputFilePath = $FilePath
)

$exitCode = -1

if (-Not ($Filter)) {
    Write-Output "Filter is not set!"
    exit 1
}

if (-Not (Test-Path $FilePath)) {
    Write-Output "Given source file is not exists!"
    exit 1
}

if (-Not (Test-Path $SnippetPath)) {
    Write-Output "Given snippet file is not exists!"
    exit 1
}

Write-Output "Inject this: $SnippetPath"
Write-Output "to this file: $FilePath"
Write-Output "and will be saved here: $OutputFilePath"

if ($IsBefore) {
    $placementText = "before"
} else {
    $placementText = "after"
}
Write-Output "$placementText $Filter"

#$snippet = New-Object -ComObject "HTMLFile"
#$snippet.IHTMLDocument2_write($(Get-Content $SnippetPath -raw))
#$snippet.all.tags("div") | % innerText

$snippet = [IO.File]::ReadAllText($SnippetPath)
$regex = [regex]::escape($Filter)
$new_html = @()
$test = $false

try {
    foreach($line in Get-Content $FilePath) { 
            if ($line -match $regex) {
                Write-Output "filter has been found..."
                $test = $true
            }
            if ($test) {
                if ($IsBefore) {
                    $new_html += $snippet
                    $new_html += $line
                    Write-Output "...and snippet injected before that"
                } else {
                    $new_html += $line
                    $new_html += $snippet
                    Write-Output "...and snippet injected after that"
                }
                $test = $false
            }
            else { 
                $new_html += $line 
            }  
        }
    $new_html | set-content $OutputFilePath
    
    $exitCode = 0
}
catch {
    $exitCode = 1
}


exit $exitCode