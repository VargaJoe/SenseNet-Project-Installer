$scriptpath = split-path -parent $MyInvocation.MyCommand.Definition
$filename = "testps2.ps1"
$scriptFolder = "PSscripts"
write-host "My work path: "$scriptpath\$scriptFolder\$filename
#& $scriptpath\$filename
#. $scriptpath\$filename

. $scriptpath".\testps2.ps1"