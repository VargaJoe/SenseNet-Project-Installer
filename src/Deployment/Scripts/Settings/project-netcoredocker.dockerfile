#Depending on the operating system of the host machines(s) that will build or run the containers, the image specified in the FROM statement may need to be changed.
#For more information, please see https://aka.ms/containercompat

FROM mcr.microsoft.com/dotnet/core/aspnet:3.0-nanoserver-1903 AS base
WORKDIR /app
EXPOSE 80

FROM mcr.microsoft.com/dotnet/core/sdk:3.0-nanoserver-1903 AS build
WORKDIR /src
COPY ["SnWebApplicationWithIdentity/SnWebApplicationWithIdentity.csproj", "SnWebApplicationWithIdentity/"]
COPY ["nuget.config", "./"]

#replace username + password
#(Get-Content c:\nuget.server.web\NuGet.Server.Web\web.config).replace('[MYID]', 'MyValue') | Set-Content c:\nuget.server.web\NuGet.Server.Web\web.config
#RUN powershell ($webClient = New-Object -TypeName "System.Net.WebClient").DownloadFile("https://dist.nuget.org/win-x86-commandline/v$nugetVersion/NuGet.exe", nuget.exe)
#RUN  nuget restore "SnWebApplicationWithIdentity/SnWebApplicationWithIdentity.csproj" -Source "http://172.19.128.250/nuget" -UserName nugetuser -Password nugetpass
# RUN dotnet restore "SnWebApplicationWithIdentity/SnWebApplicationWithIdentity.csproj" -s "http://172.19.128.250/nuget"
RUN dotnet restore "SnWebApplicationWithIdentity/SnWebApplicationWithIdentity.csproj" 
COPY . .
WORKDIR "/src/SnWebApplicationWithIdentity"
RUN dotnet build "SnWebApplicationWithIdentity.csproj" -c Release -o /app/build

FROM build AS publish
RUN dotnet publish "SnWebApplicationWithIdentity.csproj" -c Release -o /app/publish

FROM base AS final
WORKDIR /app
COPY --from=publish /app/publish .
ENTRYPOINT ["dotnet", "SnWebApplicationWithIdentity.dll"]


#FROM mcr.microsoft.com/dotnet/core/sdk:3.0 AS build-env
#WORKDIR /app
#
## Copy csproj and restore as distinct layers
#COPY *.csproj ./
## copy nuget.config
#COPY *.config ./
#
##RUN dotnet restore
#RUN dotnet restore -s \\snfilesrv02\Processes\Products\SenseNet-CMS\Releases\nuget --packages packages --ignore-failed-sources
#
## show files
#RUN ls
#
## Copy everything else and build
#COPY . ./
#RUN dotnet publish -c Release -o out
#
## Build runtime image
#FROM mcr.microsoft.com/dotnet/core/aspnet:3.0
#WORKDIR /app
#COPY --from=build-env /app/out .
#ENTRYPOINT ["dotnet", "SnWebApplicationWithIdentity.dll"]
#

#"SnCrMsSql": "Persist Security Info=False;Initial Catalog=netcoretest;Data Source=172.19.135.18;Integrated Security=true;User ID=sa;Password=QWEasd123%;"

# standalone test
#FROM mcr.microsoft.com/dotnet/core/sdk:3.0 AS build-env
#COPY . ./
#ENTRYPOINT ["dotnet", "SnWebApplicationWithIdentity.dll"]

