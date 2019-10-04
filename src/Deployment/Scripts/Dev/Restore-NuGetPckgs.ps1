Param (
	[Parameter(Mandatory = $true)]
	[string]$slnPath,
	[Parameter(Mandatory = $true)]
	[string]$nuGetFilePath = "..\..\Tools\nuget\nuget.exe"	
)

$exitCode = -1

try {
		# $Output = if ($ShowOutput -eq $False) {"Out-Null"} else {"Out-Default"}		
		Write-Output "$nuGetFilePath restore $slnPath" 
		& "$nuGetFilePath" restore "$slnPath" 
		# | & $Output
	
    $exitCode = 0
}
catch [exception] {
    Write-Output "$_.Exception"
    $exitCode = 1
}

exit $exitCode