FROM coderobin/nuget.server:latest

RUN powershell Remove-Item "C:\nuget.server.web\Packages\*" -Recurse -Force  
#RUN powershell Rename-Item -Path "C:\nuget.server.web\Packages2" -NewName "C:\nuget.server.web\Packages"
