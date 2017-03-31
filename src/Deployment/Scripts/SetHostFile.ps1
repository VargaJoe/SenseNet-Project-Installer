# ================================================
# ====== SET HOST FILE ===========================
# CALL: .\SetHostFile.ps1 -hostname "sensenet"

param([string]$Hostname)
$global:DNSALREDYEXIST = 0
$global:LASTLINE = ""
	
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

function Get-HostFileEntries{
 
<#
.EXAMPLE
    PS C:> Get-HostFileEntries
#>
[CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [String]
        $FindHostname
	)	
 
    $HostFileContent = get-content "$env:windir\System32\drivers\etc\hosts"
    $Entries = @()
    foreach($Line in $HostFilecontent){
		$global:LASTLINE = $Line
        if(!$Line.StartsWith("#") -and $Line -ne ""){
 
            $IP = ([regex]"(([2]([0-4][0-9]|[5][0-5])|[0-1]?[0-9]?[0-9])[.]){3}(([2]([0-4][0-9]|[5][0-5])|[0-1]?[0-9]?[0-9]))").match($Line).value

			# \s = space metacharacter
			$DNS = ($Line -replace $IP, "") -replace  '\s',""
 
            $Entry = New-ObjectHostFileEntry -IP $IP -DNS $DNS
            $Entries += $Entry
			
        }
		
		
		if($DNS -eq "$FindHostname")
		{
			$global:DNSALREDYEXIST = 1
		}
    }

    if($Entries -ne $Null){
        #$Entries
    }else{
        throw "No entries found in host file"
    }
}

function Add-HostFileEntry{
 
<#
.EXAMPLE
    PS C:> Add-HostFileEntry -IP "192.168.50.4" -DNS "local.wordpress.dev"
#>
 
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [String]
        $IP,
 
        [Parameter(Mandatory=$true)]
        [String]
        $DNS
    )
 
    $HostFile = "$env:windir\System32\drivers\etc\hosts"
    $LastLine = ($ContentFile | select -Last 1)
	
    if($IP -match [regex]"(([2]([0-4][0-9]|[5][0-5])|[0-1]?[0-9]?[0-9])[.]){3}(([2]([0-4][0-9]|[5][0-5])|[0-1]?[0-9]?[0-9]))"){
 
        Write-Host "Add Host in host file: "$(if($IP){$IP + " "}else{})$(if($DNS){$DNS})
		
        Add-Content -Path $HostFile -Value ("`r`n"+$IP + "       " + $DNS) -Encoding "Ascii"
		Write-Host "Adding successfully!" -foregroundcolor "green"
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
 
                Write-Host "Remove host file entry: "$(if($IP){$IP + " "}else{})$(if($DNS){$DNS})
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
	$HostnameToLower = $Hostname.ToLower()
	Get-HostFileEntries -FindHostname $HostnameToLower
	if($global:DNSALREDYEXIST -eq 0)
	{
		#Write-Host "Létrehozza"
		Add-HostFileEntry -IP "127.0.0.1" -DNS $HostnameToLower
	}
	else{
		Write-Host "$Hostname is already exist in hosts file!" -foregroundcolor "Yellow"
	}
	
	exit 0
}
Catch
{
	$ErrorMessage = $_.Exception.Message
	Write-Host "[Error][Add-HostFileEntry()] => "$ErrorMessage
	exit 1
}
	
if($LastExitCode -gt 0){
	Write-Host "Something wrong during modify host file! ExitCode:($LastExitCode)"
	exit 1
}
