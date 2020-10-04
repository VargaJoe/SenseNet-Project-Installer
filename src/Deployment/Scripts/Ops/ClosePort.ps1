Param(
		[Parameter(Mandatory=$true)]
    [Int]$Port
	)

function Allow-SinglePort($port, $direction) {
  $displayName = "PlotManager Allow $direction Port $port"
  $rule = $false
  try {
    $rule = Get-NetFirewallRule -DisplayName $displayName
  }
  catch {
    #Write-Error "$_"
  }

  if($rule) {
      Remove-NetFirewallRule -DisplayName "$displayName"
  } else {
    Write-Output "'$displayName' rule does not exist or something terrible happened"
  }
}

Allow-SinglePort $Port "Inbound"
Allow-SinglePort $Port "Outbound"
