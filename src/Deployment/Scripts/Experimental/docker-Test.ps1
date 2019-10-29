
$msSqlUser = "sa"
$msSqlPsw = "QWEasd123%"

# Start mssql container
#docker run --rm -it -e ACCEPT_EULA=Y -e sa_password=$($msSqlPsw) -p 1433:1433 -d --name sql1 microsoft/mssql-server-windows-developer:2017-latest

# get mssql ip
$msSqlIp = docker inspect --format '{{ .NetworkSettings.Networks.nat.IPAddress }}' sql1

# start webapp with script folder
docker run -d --rm --name sncont --volume=${PWD}\..\:c:\scripts vargajoe/snwithwepages 

# get snapp ip
$snAppIp = docker inspect --format '{{ .NetworkSettings.Networks.nat.IPAddress }}' sncont

# install sn services to mssql container
#docker exec -it sncont \snapp\admin\bin\SnAdmin.exe install-services dataSource:$($msSqlIp) initialCatalog:sensenet username:sa password:$($msSqlPsw) dbusername:sa dbpassword:$($msSqlPsw)
docker exec -it sncont powershell .\scripts\scripts\Run.ps1 snservices:container -settings webpages-docker -verbose

docker exec -it sncont powershell .\scripts\scripts\Run.ps1 snwebpages:container -settings webpages-docker -verbose

# set host file
. ..\Ops\Set-Host.ps1 -SiteHosts [ "projectwithwebpagesdocker" ] -SiteIp $snAppIp

 # $chrome = (Get-ItemProperty 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\App Paths\chrome.exe').'(Default)'
  # Start-Process "$chrome" $url