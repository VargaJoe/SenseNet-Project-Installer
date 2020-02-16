FROM mcr.microsoft.com/dotnet/core/sdk:3.0 AS build
WORKDIR /src

# Copy csproj and restore as distinct layers
COPY ["SnWebApplication/SnWebApplication.csproj", "SnWebApplication/"]
COPY ["nuget.config", "./"]
COPY ["nuget.exe", "./"]

#RUN dotnet restore
#RUN powershell ($webClient = New-Object -TypeName "System.Net.WebClient").DownloadFile("https://dist.nuget.org/win-x86-commandline/v$nugetVersion/NuGet.exe", nuget.exe)
#RUN nuget restore "SnWebApplication/SnWebApplication.csproj" -Source "http://172.19.140.80/nuget" -UserName nugetuser -Password nugetpass

RUN dir 

#RUN nuget.exe restore "SnWebApplication/SnWebApplication.csproj" -Source "http://172.19.140.80/nuget" 
# RUN dotnet restore "SnWebApplication/SnWebApplication.csproj" -s "http://172.19.140.80/nuget"
RUN dotnet restore "SnWebApplication/SnWebApplication.csproj" 

# show files
RUN dir 

# Copy everything else and build
COPY . ./
WORKDIR "/src/SnWebApplication"
RUN dotnet build "SnWebApplication.csproj" -c Release -o /app/build

FROM build AS publish
RUN dotnet publish "SnWebApplication.csproj" -c Release -o /app/publish

# Build runtime image
FROM mcr.microsoft.com/dotnet/core/aspnet:3.0
WORKDIR /app
#COPY --from=build-env /app/out .
COPY --from=publish /app/publish .
ENTRYPOINT ["dotnet", "SnWebApplication.dll"]

#docker build -t netcoretest -f .\settings\project-netcoredocker2.dockerfile ..\temp\Templates\src\netcore\SnWebApplication\
