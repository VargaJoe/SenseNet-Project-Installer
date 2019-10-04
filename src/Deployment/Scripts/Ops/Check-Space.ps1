Param (
    [Parameter(Mandatory = $False)]
    [string]$MachineName = "localhost",
    [Parameter(Mandatory = $False)]
    [string]$NetworkPath = "C:",
    [Parameter(Mandatory = $False)]
    [string]$NeedSpace
)

$exitCode = -1

try {
    $disk = Get-WmiObject Win32_LogicalDisk -ComputerName $MachineName -Filter "DeviceID='$NetworkPath'"
    $size = $disk.Size 
    $free = $disk.FreeSpace 

    Write-Output "Disk size (bytes): $size"
    Write-Output "Free space (bytes): $free"
    Write-Output "Required space (bytes): $NeedSpace"

    if ($free -lt $NeedSpace) {
        Write-Output "Not enough disk space available!"
        $exitCode = 1
    }
    else {
        Write-Output "Disk space is sufficient!"
        $exitCode = 0
    }
}
catch {
    $exitCode = 1
}

exit $exitCode