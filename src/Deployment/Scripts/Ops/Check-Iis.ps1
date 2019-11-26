$exitcode = -1

$iis = Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\InetStp\"
# setupstring, versionstring, majorVersion, minorVersion, ProductString

# Technical Debt: what happens if more than one IIS versions are installed
if ($iis) {
    $iisversion = $iis.majorVersion
    Write-Output "IIS version $iisversion is available."    
    $exitcode = 0
}
else {
    Write-Output "IIS is not available."
    $exitcode = 1
}

exit $exitcode


