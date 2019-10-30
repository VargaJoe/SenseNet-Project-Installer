[CmdletBinding(SupportsShouldProcess = $True)]
Param(
    [Parameter(Mandatory = $true)]
    [string]$FilePath,
    [Parameter(Mandatory = $true)]
    [string]$SnippetPath
)

$LASTEXITCODE = 0

Write-Verbose "Inject this: $SourcePath"
Write-Verbose "to this file: $FilePath"

#$snippet = New-Object -ComObject "HTMLFile"
#$snippet.IHTMLDocument2_write($(Get-Content $SnippetPath -raw))
#$snippet.all.tags("div") | % innerText

$snippet = [IO.File]::ReadAllText($SnippetPath)

$regex = [regex]::escape('</head>')
$new_html = @()
$test = $false

foreach($line in Get-Content $FilePath) { 
        if ($_ -match $regex) {
            $test = $true
        }
        if ($test) {
            $new_html += ($_ -replace $regex, $snippet + '</head>')
        }
        else { $new_html += $_ }  
    }
$new_html | set-content $FilePath


exit $LASTEXITCODE