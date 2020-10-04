[CmdletBinding(SupportsShouldProcess=$True)]
Param(
    [Parameter(Mandatory=$true)]
    [string]$ConfigFilePath,
    [Parameter(Mandatory=$False)]
    [String[]]$Packages = @(),
    [Parameter(Mandatory=$False)]
    [String]$nodeName = "packages"
)

# custom function in this separate script due to independence
$exitCode = 0

#Write-Output "Set install packages string value: $Packages"
Write-Output "in config file: $ConfigFilePath"

try {
    Write-Output "on $nodeName settings the following packages will be set:"
    if ($Packages -and $Packages -ne @{}) {
        foreach ($package in $Packages) {
            Write-Output "`t $package"
        }
    } else {
        Write-Output "`t there are no packages given, so empty array is about to set"
    }

    $doc = Get-Content "$ConfigFilePath" -raw | ConvertFrom-Json
    Write-Host 1 $doc.sensenet.install

    if ($doc.sensenet.install."$nodeName" -or $doc.sensenet.install."$nodeName" -eq @()) {
        Write-Host 2 $doc.sensenet.install."$nodeName"
    } else {        
        Write-Host "Adding missing $nodeName property..."
        try {
            $doc.sensenet.install | add-member -Name "$nodeName" -value @() -MemberType NoteProperty
        } 
        catch {
            write-host "$_.Exception"
        }
    }
    $doc.sensenet.install."$nodeName" = $Packages
    Write-Host 3 $doc.sensenet.install."$nodeName"
    $doc | ConvertTo-Json -depth 10 | set-content "$ConfigFilePath"
} 
catch {
    $exitCode = 1
}

exit $exitCode