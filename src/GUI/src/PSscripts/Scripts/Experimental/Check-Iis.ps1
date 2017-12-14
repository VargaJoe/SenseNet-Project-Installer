$iis = get-itemproperty HKLM:\SOFTWARE\Microsoft\InetStp\  | select setupstring,versionstring 
write-host $iis