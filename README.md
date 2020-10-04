# SenseNet Project Installer

> The description is under construction but I hope it's still better than a description of an obsolate solution. if you're looking for the older version of the script, it's in the 'installer-6.5' branch.

## How it works

The latest version of this project is basically a plot manager with package of various scripts used by my team creating and managing custom project installations. With this we have created automated steps and can run them in predefined order. With a little powershell script knowledge these steps can be broaden.

Steps contain the following scripts for now:
- Create, start and stop IIS sites
- Setup host file
- Unzip archives
- Build solutions
- Install Sense/Net site from source package
- Get latest from TFS
- Import/Export content and index populate Sense/Net site
- and some other custom scripts

## Prerequisits

Prerequisits are mostly come from the scripts that are made for managing Sense/Net:

1. PowerShell: first and foremost the whole logic is based on powershell scripts, so naturally it needs to be executeable
- Enable the powershell script running permission: PS C:\PowerShell-PowerUp> Set-ExecutionPolicy unrestricted
- Some scripts need administrator privilages so I advice to run the scripts in administrator mode
2. The user who executes the scripts have to have read and write privilages to the scripts, packages and soltuion folders because some steps will need it, eg. will create temporary files
3. Visual Studio: some scripts based on visual studio tools, so if we want to use these steps we will need a VS in our environment
4. Microsoft SQL Server: some steps will create database, for these steps we will need MsSql server on target machine
a.       SQL Server Configuration Manager: we usually use a default server alias, if use default settings we have to set up this first
b.       SqlServer powershell module
          ```powershell
          Install-Module -Name SqlServer -Force –AllowClobber
          ```
5. IIS: there are step to create an IIS site and it naturally needs IIS on target machine
6. Environment settings
- because it is for manage our development environment so to get SenseNet install we basically use a VS solution, and this project has an example for this. It can be replaced as long it has all the folders and tools to execute predefined steps
- Download and install the 7-Zip application from http://www.7-zip.org/.

[How to execute a "plot"](/docs/how-to-execute-a-plot.md)
[How to execute steps](/docs/how-to-execute-steps.md)

**How is it working?**

The main part of the solution is in the Script folder. The entry point of the solution is the Run.ps1 file in the root of the Script folder. This file accepts the execute parameters required to the automatization, this file loads and prepares the predefined configurations for processing.

Parameters for run the script:
-Plot: this is the name of the scenario. If it is not existed, the step with the same name will be executed.
-Settings: it is for define the related settings file. The solution is working based on this project-"$Settings".json file. If it is not set, it uses the "local" value by default so it will use the content of the project-local.json.
-ShowOutput = $True
-Verbose: it is not a real parameter, it controls the output information made by "Write-Verbose". It is useful when you are creating unique scripts, so that you can keep the control over the amount of dispayed information,

Let's see how all this are connected.
- First, when we start the process, we give a scenario name to the Run script.

```powershell
.\Run.ps1 fullinstall
```

- before we could do anything with this information, the script loads the helper methods and prepares the steps that could be used.
- then it gets into a adaptor method, which is declared in the init-functions.ps1. (each helper method gets here)

```powershell
Run-Steps "fullinstall"
```

- the helper method checks if one of the configs has a scenario with that name

```json
pl. "fullinstall": [ "stop", "restorepckgs", "prbuild", "dropdb", "snservices", "snwebpages", "removedemo", "adminusers", "prinstall", "setrepourl", "index", "createsite", "sethost", "start" ],
```

- after that it iterates through the steps of the scenario and executes the steps one by one. If there's an error, the error code is returned to the caller script as a value of a variable names Result.
- finally, when all the steps are executed, the Run script quits with the error code in $Result, or if it is supported in the step, it could be return $JsonResult as a powershell variable.

Loading of the helper methods and steps happens nearly automatically. The methods are stored in the "init-functions.ps1", the steps are stored in the "Default-Modules.ps1" file. These two file can be found in the "AutoExt" folder inside the Scripts folder. Everything powershell file stored in the "AutoExt" folder will be loaded automatically by the Run script. So if you need unique or project-specific steps do not modify the files mentioned above. Create your own file and put it into this folder, so that you can handle these custom steps separately and updating the common code will be easier.

[Settings](/docs/settings.md)

## Local install 

If everything've set right, you can call the scripts simply with the following parameter:
```powershell
Run.ps1 fullinstall
```

[Build server basic steps](/docs/build-server-basic-steps.md)

[Custom steps](/docs/custom-steps.md)

## Tfs Build Szerver

Végezetül egy megjegyzés: mivel a build szerver képes powershell scripteket futtatni és ha a távoli környezetek is megfelelően be vannak állítva a settings file-okban, például belőttük a teszt szerver eléréséhez szükséges beállításokat, akkor minden további nélkül alkalmazhatóak a fent említett futtatási információk build szerver összeállításakor is. Ez esetben nem szükséges a környezeti változókat külön még a build szerveren is beállítani, futtatáskor ugyanúgy a settings file-ból fogja ezeket beolvasni. Hacsak nem feltétlenül szükséges mindenáron külön kezelni, akár lépésenként akor plot futtatásban egyszerűbbé válik a build szerver összeállítása is. Hiszen, ha egy adott forgatókönyv lefut lokál környezetből az adott szerverre, valószínűleg build szerverről is futni fog.

## Known issues

There are some steps we've not fully automated yet. So some manual setups may required, such as:

- The script won't automatically map your Visual Studio version and its location which is needed to get latest tfs and solution build steps. You have to set `tf.exe` path properly in `project-local.json`'s Tools.VisualStudio property
- Unziping archive script uses 7zip, the location for `7za.exe` file needs to be set in `project-local.json` too
- If you use sql alias like `MySenseNetContentRepositoryDatasource` in default Sense/Net install, you have to set it manually before using the script or you have to set different Datasource in `project-local.json`
- Nuget packages and snadmin version in the project should be checked if they're matching the proper sensenet version.
