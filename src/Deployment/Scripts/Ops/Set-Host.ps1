[CmdletBinding(SupportsShouldProcess=$True)]
Param(
[Parameter(Mandatory=$true)]
[string[]]$SiteHosts 
)

Write-Verbose "================================================"
Write-Verbose "SET HOST FILE"
Write-Verbose "================================================"
# CALL: .\SetHostFile.ps1 -hostname "sensenet"

Write-Verbose "Hosts $SiteHosts" 
	
function New-ObjectHostFileEntry{
    param(
        [string]$IP,
        [string]$DNS
    )
    New-Object PSObject -Property @{
        IP = $IP
        DNS = $DNS
    }
}

function Is-Exists{
	[CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
		[String]$FindHostname
	)	
 
    $HostFileContent = get-content "$env:windir\System32\drivers\etc\hosts"
    foreach($Line in $HostFilecontent){
        if(!$Line.StartsWith("#") -and $Line -ne ""){
 
            $IP = ([regex]"(([2]([0-4][0-9]|[5][0-5])|[0-1]?[0-9]?[0-9])[.]){3}(([2]([0-4][0-9]|[5][0-5])|[0-1]?[0-9]?[0-9]))").match($Line).value

			# \s = space metacharacter
			$DNS = ($Line -replace $IP, "") -replace  '\s',""
        }
				
		if($DNS -eq "$FindHostname")
		{
			return $true
		}
    }
	return $false
}

function Add-Host{ 
	<#
	.EXAMPLE
		PS C:> Add-Host -IP "127.0.0.1" -DNS "www.project.org"
	#>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [String]$IP, 
        [Parameter(Mandatory=$true)]
        [String]$DNS
    )
 
    $HostFile = "$env:windir\System32\drivers\etc\hosts"
    $LastLine = ($ContentFile | select -Last 1)
	
    if($IP -match [regex]"(([2]([0-4][0-9]|[5][0-5])|[0-1]?[0-9]?[0-9])[.]){3}(([2]([0-4][0-9]|[5][0-5])|[0-1]?[0-9]?[0-9]))"){
 
        Write-Verbose "Add Host in host file: $(if($IP){$IP + " "}else{})$(if($DNS){$DNS})"
		
        Add-Content -Path $HostFile -Value ("`r`n"+$IP + "       " + $DNS) -Encoding "Ascii"
		Write-Verbose "$HostFile has been modified successfully!" 
    }
}

function Remove-HostFileEntry{
 
<# 
.EXAMPLE
    PS C:> Remove-HostFileEntry -IP "192.168.50.4" -DNS "local.wordpress.dev"
#>
 
    [CmdletBinding()]
    param(
        [String]
        $IP,
 
        [String]
        $DNS
    )
 
    $HostFile = "$env:windirSystem32driversetchosts"
    $HostFileContent = get-content $HostFile
    $HostFileContentNew = @()
    $Modification = $false
 
    foreach($Line in $HostFilecontent){
        if($Line.StartsWith("#") -or $Line -eq ""){
 
            $HostFileContentNew += $Line
        }else{
 
            $HostIP = ([regex]"(([2]([0-4][0-9]|[5][0-5])|[0-1]?[0-9]?[0-9])[.]){3}(([2]([0-4][0-9]|[5][0-5])|[0-1]?[0-9]?[0-9]))").match($Line).value
            $HostDNS = ($Line -replace $HostIP, "") -replace 's+',""
 
            if($HostIP -eq $IP -or $HostDNS -eq $DNS){
 
                Write-Verbose "Remove host file entry: $(if($IP){$IP + " "}else{})$(if($DNS){$DNS})"
                $Modification = $true
            }else{
                $HostFileContentNew += $Line
            }
        }
    }
 
    if($Modification){
 
        Set-Content -Path $HostFile -Value $HostFileContentNew
    }else{
        throw "Couldn't find entry to remove in hosts file."
		exit 1
    }
}

try{
	foreach ($hostCombinedUrl in $SiteHosts) {
		$hostUrlComponents = $hostCombinedUrl.Split(":")
		if ($hostUrlComponents[1] -eq $Null){
			$hostUrl = $hostUrlComponents[0]
		} else {
			$hostUrl = $hostUrlComponents[1]
		}				
		$HostnameToLower = $hostUrl.ToLower()
		$IsExists = Is-Exists -FindHostname $HostnameToLower
		Write-Verbose "Check for $HostnameToLower"
		if (!$IsExists)
		{
			Add-Host -IP "127.0.0.1" -DNS $HostnameToLower
		}
		else{
			Write-Verbose "$HostnameToLower is already exist in hosts file!" 
		}
	}
	exit 0
}
Catch
{
	$ErrorMessage = $_.Exception.Message
	# Write-Verbose "[Error][Add-HostFileEntry()] => "$ErrorMessage
	Write-Verbose "$ErrorMessage"
	exit 1
}
	
if($LastExitCode -gt 0){
	Write-Verbose "Something wrong during modify host file! ExitCode:($LastExitCode)"
	exit 1
}
