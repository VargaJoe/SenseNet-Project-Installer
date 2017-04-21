# SenseNet Project Installer

## How it works

This is basically a package of various scripts my team use for create and manage custom project installations. There are some batch scripts as previously used solution, but lately we replaced them with powershell scripts.
It contains the following scripts for now:
- Create, start and stop IIS sites
- Setup host file
- Unzip archives
- Build solutions
- Install Sense/Net site from source package
- Get latest from TFS
- Import/Export content and index populate Sense/Net site
- and some other custom scripts

## Prerequisits

Prerequisits are mostly come from the script are for managing Sense/Net, so you 

1. Microsoft SQL Server
	a.       SQL Server Configuration Manager
2. Visual Studio
3. IIS
3. PowerShell (or obsolate batch scripts uses command line)
4. Environment settings

## Powershell script modules:

- `StartWebsiteAppPool`: start the site what you give it in parameter. 
```
StartWebsiteAppPool.ps1 [SiteName]
```
- `StopWebsiteAppPool`: stop the site what you give it in parameter.
```powershell
StopWebsiteAppPool.ps1 [SiteName]
```
- BuildSnSolution: build the solution what you give path in parameter.
```
BuildSnSolution.ps1` -slnPath [Solution file path. It is .sln file]
```
- `Create-IISSite`: create the application pool and site. In the first parameter need to give the application pool (same site name) and in the second parameter need to give the site’s physical path on the hard drive.
```
Create-IISSite.ps1 [SiteName] [site’s physicalPath]
```
- `GetLatestSolution`: get latest version from the repository.
```
GetLatestSolution.ps1 -tfexepath [tf.exe physical path] –location [project source folder path]
```
- `Import-Module`: import the project files to the repository.
- `Export-Module`: sxport the project files from the repository.
- `Index-Project`: run indexpopulation process.
- `Init-Assemblies`: copy the sensenet dlls into bin and tools folders and edit the config files.
- `init-functions`: functions of initialization.
- `Initialization`: initialize the script variables
- `Install-SenseNet`: install the sensenet
- `RemoveDemo`: remove the default site from the sensenet portal.
- `SetHostFile`: set in the web.config host attribute.
- `Unzip`: unzip the zip file (example: sensenet package) to the destination folder.
```
unzip.ps1 -filename [zip file path] -destname [destination path]
```
- `START`: You can run different modes: 
-- fullinstall: run sensenet install process.

## Local install 

If everything've set right, you can call simply the scripts with the following parameter:
```
START.ps1 fullinstall
```

## Build server example steps

The same scripts used local install can be used visual studio's build server.

1.	Stop the site 
2.	Unzip the Sensenet package
3.	Build the Sensenet solution
4.	Install Sensenet
5.	Copy DLLs to bin and tools folder
6.	Get latest version
7.	Build solution
8.	Import contents to repository
9.	Indexpopulation
10.	Start the site 

## Known issues

There are some steps we've not yet fully automated. So manual setup may required, such as:

- The plan was to use different json settings for different project and/or environment, but local settings work only for now
- The script wont automatically map your Visual Studio version and it's location which is needed for get latest tfs and solution build steps. You have to set properly `tf.exe` path in `project-local.json`'s Tools.VisualStudio property
- Unzip archive script use 7zip, the location for `7za.exe` file needs to setup `project-local.json` too
- if you use sql alias like `MySenseNetContentRepositoryDatasource` in default Sense/Net install, you have to set it manually before use the script or set different Datasource in `project-local.json`
- project references should be checked up if matchthe proper Sense/Net version