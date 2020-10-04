Param(
		[Parameter(Mandatory=$true)]
    [Int]$Port
	)

function Allow-SinglePort($port, $direction) {
  $displayName = "PlotManager Allow $direction Port $port"
  $rule = Get-NetFirewallRule -DisplayName $displayName
  if(!$rule) {
      New-NetFirewallRule -DisplayName $displayName -Direction $direction -LocalPort $port -Protocol TCP -Action Allow
  } else {
    Write-Output "Rule already exists: $displayName"
  }
}

Allow-SinglePort $Port "Inbound"
Allow-SinglePort $Port "Outbound"
