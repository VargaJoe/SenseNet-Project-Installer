[CmdletBinding(SupportsShouldProcess=$True)]
Param(
[Parameter(Mandatory=$true)]
[string]$ConfigFilePath,
[Parameter(Mandatory=$true)]
[string]$DataSource,
[Parameter(Mandatory=$true)]
[string]$InitialCatalog
)

$exitCode = 0

function Set-ConnectionString {
	Param(
            [Parameter(Mandatory=$True)]
            [String]$ConfigPath,
			[Parameter(Mandatory=$True)]
            [String]$ConnectionString,
            [Parameter(Mandatory=$False)]
            [String]$ConnectionName = "SnCrMsSql"
         )
	
	Set-ItemProperty $ConfigPath -name IsReadOnly -value $false
	$doc = [xml](get-content $ConfigPath)
    $root = $doc.get_DocumentElement();
    $node = (($root.connectionStrings.add|Where-Object {$_.name -eq $ConnectionName}))
    Write-Host "before $($node.connectionString)"
    $node.connectionString = $ConnectionString
    Write-Host "after: $($node.connectionString)"
    
	$doc.Save($ConfigPath)
}

$ConnectionString = 'Persist Security Info=False;Initial Catalog='+$InitialCatalog+';Data Source='+$DataSource+';Integrated Security=true'
Write-Verbose "Create new connection string value: $ConnectionString"
Write-Verbose "in config file: $ConfigFilePath"
try {
    Set-ConnectionString -ConfigPath "$ConfigFilePath" -ConnectionString "$ConnectionString"
}
catch {
	Write-Verbose "Exception: $_.Exception"
	$exitCode = 1
}

exit $exitCode