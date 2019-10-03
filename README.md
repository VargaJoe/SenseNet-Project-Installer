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
5. IIS: there are step to create an IIS site and it naturally needs IIS on target machine
6. Environment settings
- because it is for manage our development environment so to get SenseNet install we basically use a VS solution, and this project has an example for this. It can be replaced as long it has all the folders and tools to execute predefined steps
- Download and install the 7-Zip application from http://www.7-zip.org/.

## How to execute a "plot" 
As it was mentioned earlier, the solutions main goal is to do specified tasks syncronously. The scenario names "plot" the executable task is the "step". Since in most of the cases "plot" makes it possibel to automate tasks with multiple steps, saving us time, in basic scenarios (e.g. creating or updating the development enviroment) the "plot" plays the bigger role. These scenarios are declared in the settings file storing the steps of related plot. 'fullinstall' is a good example for that, installing sensenet from schratch configured for the specified project. This plot is made up from the following steps (may be different from project to project of course):
- stops the site (if it was installed before)
- downloads the nuget packages that are declared in the project
- creates the needed assembly files (e.g. it builds the solution)
- clears the database
- creates the new database and installs the [sn-services](https://github.com/SenseNet/sensenet) package
- installs [sn-webpages](https://github.com/SenseNet/sn-webpages)
- removes demo content
- adds predefined users to the repository
- installs custom, project related content
- sets the project-specific urls on the related site's of the repository
- populates lucene index
- creates the site in IIS
- adds the defined urls into the HOST file of the local machine
- starts the IIS site 

After this quick overview, see how it should be executed actually. If a project is well-configured and prepared and all the prerequisites for executing are fulfilled, the developer - who let's say you've just joined the project - has only need to get the code, open a powershell window and execute the following code:

```powershell
.\Run.ps1 fullinstall
```

The code above will execute the "fullinstall" scenario for configure the "Project" with the "local" settings, which means it creates the local development enviroment (in this case a sensenet site).
In this case the script will give you a minimal feedback, only those messages will shown that are returned from the helper tools. If you need further information the feedbacks considered important by the creators of the script can be reached with the following addition:

```powershell
.\Run.ps1 fullinstall -Verbose
```

And if you want to skip the feedback messages of the helper tools, then use:

```powershell
.\Run.ps1 fullinstall -ShowOutput false
```

The examples above are sufficient only if we execute predefined scenarios in local enviroment, but we can also define custom scenarios, non-local enviroments (e.g. test server) or handle multiple projects. In this cases you have know the parameters a bit more. The second example above could be look like this:

```powershell
.\Run.ps1 -Plot fullinstall:Project -Settings local -ShowOutput true -Verbose
```

Suppose that we want to update custom project content on a distributed test server in a project names 'Custom', that has a custom settings file which could be the following:

```powershell
.\Run.ps1 -Plot updatetestsite -Settings custom -ShowOutput true -Verbose
```

Almost all parts of the "Project Installer" is extendable, it will be discussed later.

## How to execute steps
Már szó esett a forgatókönyv végrehajtandó lépéseiről. Egy forgatókönyv általában több lépést tartalmaz, de semmi sem gátol minket abban, hogy 1 lépést definiáljunk benne. Itt jegyezném meg, hogy a lépések direktben is meghívhatók, arra kell figyelnünk csupán, hogy a lépés és forgatókönyv neve nem lehet ugyanaz. Jelenleg, ha a végrehajtó logika nem talál az adott néven (-Plot valami) végrehajtandó forgatókönyvet, akkor keres egy ugyanolyan nevű lépést. Ha talál, akkor azt az egyet hajtja végre. Korábban a Plot paraméter más néven szerepelt, így kevésbé volt zavaró, szóval ez a működés később lehet, hogy szét lesz szedve. Vagy a közvetlen végrehajtás lesz megszüntetve, de egyelőre sokszor igen hasznosnak bizonyul ez a lehetőség, ez indítja el a folyamatot és ha szükséges itt ad vissztérési értéket a hívónak. 

Hogy működik 
- Belépési pont
A megoldás lényegi része a Script mappában található, az ezen kívül található többi mappáról később ejtek szót. A megoldás belépési pontja a script könyvtár gyökerében található Run.ps1 file. Ez fogadja az automatizáláshoz szükséges futtatási paramétereket, ez tölti be és készíti elő feldolgozásra az előre felvett beállításokat. 

A futtatáshoz használható paraméterek a következők:
-Plot : Erről már esett szó, a végrehajtandó forgatókönyv neve. Ha az nem létezik, az itt megadott nevű step-et fogja keresni és futtatni. Ha itt lépést adunk meg, úgy működik itt is a stepeknél majd később tárgyalt szekció meghatározás is.
-Settings : Ez a futtatáshoz használt settings file meghatározására szolgál. A megoldás ez alapján a project-"$Settings".json file alapján dolgozik. Ha nincs megadva, alapból a "local" értéket veszi fel, tehát a project-local.json beállításai lesznek figyelembe véve.
-ShowOutput = $True
-Verbose : Ez nem igazi paraméter, a "Wrie-Verbose"-zal kimentre küldött információk megjelenítését szabályozza. Egyedi scriptek létrehozásánál érdemes ezt a módszert használni, így szabályozható marad a megjelenítendő információmennyiség.

(további paraméterekkel is kísérleteztem, de ezek maradtak egyelőre bent, a többi emlékeim szerint nincs bekötve a logikába)

Lássuk, hogy is van az egész összedrótozva. 
- Először is, amikor elindítjuk a folyamatot, a Run scriptnek átadunk egy forgatókönyv nevet.
```powershell
.\Run.ps1 fullinstall
```

- még mielőtt bármit kezdenénk ezzel az információval valamit, a script behúzza a segédfüggvényeket és előkészíti a használható lépéseket*
- Innen egy feldolgozó függvénybe kerül, ami az init-functions.ps1-ben van deklarálva. (a segédfüggvények ide kerülnek)

```powershell
Run-Steps "fullinstall"
```

- a segídfüggvény megnézi, hogy a beállítások között van-e ilyen nevű forgatókönyv

```json
pl. "fullinstall": [ "stop", "restorepckgs", "prbuild", "dropdb", "snservices", "snwebpages", "removedemo", "adminusers", "prinstall", "setrepourl", "index", "createsite", "sethost", "start" ],
```

- ezután a megtalált forgatókönyv lépésein végigiterál és egyesével végrehajta a lépéseket, a hibakódot egy Result nevű változóban adja vissza a hívó scriptnek.
- végezetül, ha az összes lépés lefutotta Run script a $Result-ban kapott hibakóddal lép ki, illetve ha a step támogatja, powershell változóként képes $JsonResult-ot is visszaadni

A segédfüggvények és lépések betöltése kvázi-automatikusan történik. Előbbiek az "init-functions.ps1" file-ban, utóbbiak "Default-Modules.ps1" file-ban kaptak helyet. illetve mindkét file a Scripts könyvtáron belül az "AutoExt" mappa alatt találhatóak. Azt kell tudni erről a mappáról, hogy bármely ebben a mappában található powershell file-t automatikusan be fog tölteni a Run script. Tehát ha egyedi lépésekre vagy kifejezetten projekt specifikus lépésekre lenne szükség, nem kell - sőt egyenesen ellenjavallt - az itt említett file-oknak a módosítása. Célszerű saját file-t készíteni a lépések deklarációjánál tárgyalt módon és egyszerűen berakni a file-t ebbe a könyvtárba. Így elkülönítve tudjuk kezelni ezeket a custom lépéseket és a közös kód update-elése is könnyebb lesz.

## Settings
Nem húzhatom tovább, muszáj szót ejtenünk a settings file felépítéséről, hogy használni tudjuk a megoldásunkat. Ezt jó esetben egyszer kell projekt elején jól beállítani és többé nem lesz gondunk vele. Persze gyakorlatban, ahogy egyre több feladatot akarunk automatizmusra bízni, bővíteni kell majd a beállítások körét (pl további site környezetek: development site, teszt site, integration, stb)

Először is egyből minimum két settings file-unk van. Az egyikről már eset szó, ő a projekt beállításokért felelős file. Az ő neve project-local.settings. Ezt persze átnevezhetjük, illetve több projekt esetén egyedi neveket kaphatnak (pl. project-custom1.settings, project-custom2.settings, project-akarmi.settings). Ez esetben vagy módosítani kell a Run.ps1-ben a default settings nevét, vagy ennek megfelelően kell meghívni futtatáskor a -Settings paramétert.

A másik settings file a project-default.settings. Értelem szerűen nem lehet olyan project file-unk, aminek default a neve, mert akkor összeakadna a kettő. Ez a settings file felelőe azokért a beállításokért, ami vagy projekttől független, vagy több projekt esetén is szeretnénk használni és nem akarjuk minden projekt beállításnál külön-külön megadni. A Run.ps1 futtatáskor ebből a két file-ból összemergeli a beállításokat, méghozzá úgy, hogy a projekt beállítások prioritást élveznek.

A két file az alábbi beállítási szekciókat tartalmazza:
- Plots : Itt történik a forgatókönyvek deklarálása, általában ez a default beállítások között szerepel, de termkészetesen kiegészíthető vagy felülírható a projekt beállítások között is. Egy forgatókönyv egy lépésekből álló string tömb. A lépéseket névkonvenció szerint vannak létrehozva, itt csak az egyedi részüket kell megadni. 
Például névkonvenció szerint az indexpopulátor lépés neve "Step-Index", ebben az esetben a settingsben, vagy a "Run" lépés alapú futtatásánál annyit kell megadni "index". Az általunk létrehozott lépések úgy lettek kialakítva, hogy itt lehetőség van kettősponttal elválasztva itt egy beállítási szekció megadására is, pl "index:TestSite" (step: index, szekció: TestSite). Ha nem adunk meg szekciót, a lépés a saját logikájához tartozó default beállítások közül fogja venni a működéséhez szükséges adatokat. Ez legtöbbször a "Project". Ha a kettősponttal megadunk egy ettől eltérő nevet, abban az esetben a működési adatokat a Settings file-ban abból a szekcióból próbálja a kód felolvasni. 

- Source : az olyan beállítások kerülnek ide, amik valamilyen forrásul szolgálnak az adott feladat végrehajtásához, függetlenül a projektjez tartozó környezetektől. Például adatbázis backup, vagy snadmin csomagok gyűjtőhelye.

Jelenleg ezeket használjuk:
"PackagesPath": snadmin csomagok közös gyűjtőhelyének útvonala
"DbBackupFileUrl": adatbázis backup file elérése interneten keresztül, egyik script a kitüntetett adatbázis backup útvonalára menti le innen a file-t
"DbBackupFilePath": kitüntetett adatbázis backup file elérési útja, bizonyos lépések ebbe mentenek és ebből olvasnak vissza
"DatabasesPath": további adatbázis backupok gyűjtőhelyének útvonala, pl automatizált vagy manuálisan indított scriptek ide hoznak létre dátumozott file-okat
"SnWebFolderFileUrl": előre elkészített webfolder internetes elérése, az adatbázisos megoldáshoz hasonlóan működik
"SnWebFolderFilePath": előre elkészített webfolder zip elérése

- Project : Ez a default beállítási szekció a legtöbb lépéshez. Mivel alapvetően lokál fejlesztő környezet kezeléséhez készült a megoldás, itt lokális útvonalak vannak többnyire megadva:

"DataSource": adatbázis szerver elérés, ajánlott beállítás: "MySenseNetContentRepositoryDatasource"
"InitialCatalog": adatbázis neve
"WebAppName": IIS site neve
"AppPoolName": Application Pool neve
"Hosts": a projekthez használt url-eket tartalmazó string tömb, kettősponttal elválasztva lehet definiálni azt is, hogy a sensnet repositoryban melyik site-hoz tartozik. Ha ez nincs megadva, defaultból a "project" nevű site-ot keresi. (pl: a setrepourl lépés a custom nevű site-hoz felveszi a két url-t, ha így van megadva:

```json
[ "custom:custom.hu", "custom:sub.custom.hu" ])
```

"DotNetVersion": Application Pool verziója, "v4.0"
"SourceFolderPath": TFS-t kezelő lépésekhez a forráskönyvtár konténerének elérési útvonala
"WebFolderPath": webfolder elérési útvonala
"AsmFolderPath": bin könyvtár elérési útvonala
"WebConfigFilePath": web.config elérési útvonala
"SnAdminFilePath": snadmin.exe elérési útvonala, snadmin megoldásokat használó lépések használatához
"ToolsFolderPath": Tools mappa elérési útvonala, snadminruntime.exe beállításához
"SnAdminRCFilePath": SnAdminRuntime.config elérési útvonala, snadmin futtatását előkészítő lépés működéséhez
"IndexerPath": indexpopulator.exe elérési útvonala (sn7-nél régebbi projektekhez)
"ImporterPath": import.exe elérési útvonala (sn7-nél régebbi projektekhez)
"ExporterPath": export.exe elérési útvonala (sn7-nél régebbi projektekhez)
"RepoFsFolderPath": project custom content import útvonala, fejlesztésnél a DiskFsSupport miatt nálunk a project webfolder alatt található Root mappa
"DeployFolderPath": snadmin futtatásához szükséges manifest file-t tartalmazó mappa útvonala, nálunk ebben van deklarálva a projekt installáláshoz szükséges információ és a project webfolder alatt található.
"SolutionFilePath": solution file elérési útvonala 

- Tetszőleges nevű szekció : tetszőleges számú és nevú új szekció hozható létre a projectben definiált beállításokkal, amik a lépéseknél és forgatókönyveknél említett módzserrel megcímezhetők (azért lehetőleg ékezet és space ne legyen benne). Talán itt még egy említésre méltő beállítás van: 

"MachineName": távoli script futtatásánál használt a távoli gép azonosítója

- Tools : az egyes lépések futtatásához szükséges segédprogramok elérési útvonala szokott leginkább itt szerepelni. Ez projektenként nem szokott változni, így a default beállítások közé szoktuk rakni.

## Local install 

If everything've set right, you can call the scripts simply with the following parameter:
```powershell
Run.ps1 fullinstall
```

## Build server basic steps

Even I don't go in details with external script we have created several steps we use for everyday sensenet development environment management. I will use only the "short name" for the steps, but you will find them with the prefix "Step-" in the scripts under AutoExt folder. The prefix is needed to distinguish them from ordinary powershell functions. For example "stop" step can be found as "Step-Stop" in "Default-Modules.ps1". External scripts are separate files and could be execute manual parametrizing, but we would lose the comfort and automatism of using the predefined settings. These external script files from the other folders. There is no time and place to write here all the external scripts and parameters we use. Maybe later.

*stop*
- it's job: Stop the IIS site and it's app pool
- settings: it will use the options of the given section of the setting json, default section is Project
- external script: .\Ops\Stop-IISSite.ps1 $ProjectSiteName

start
- it's job: Start the IIS site and it's app pool
- settings: it will use the options of the given section of the setting json, default section is Project
- külső script .\Ops\Start-IISSite.ps1 $ProjectSiteName

getlatest
- it's job: Get latest version of the project solution from TFS
- settings: Fixen a Project szekció SourceFolderPath beállítását és a Tools szekció VisualStudio beállítását használja
- external script: .\Dev\GetLatestSolution.ps1 -tfexepath $TfExePath -location $ProjectSourceFolderPath

restorepckgs
- it's job: A projektben használt nuget csomagok letöltése, befrissítése 
- settings: fixen használja a Tools szekció NuGetSourceUrl és NuGetFilePath beállításait, illetve szintén fixen a project szekció SolutionFilePath beállítását
- external script: .\Dev\Download-File.ps1 -Url $NuGetSourcePath -Output $NuGetFilePath
- special: a külső script csak a segédprogramot (nuget.exe) frissíti be, a csomagok frissítését a lépés közvetlenül a console app segítségével végzi

prbuild
- it's job: Build visual studio solution
- settings: Szintén fixen a Project szekció SolutionFilePath beállítását használja
- external script: .\Dev\Build-Solution.ps1 -slnPath $ProjectSolutionFilePath 

snservices
- it's job: Install services package which will create the basic api layer of sensenet
- settings: A beállítások közül a megcímzett (alapértelmezetten Project) szekció WebConfigFilePath, ToolsFolderPath, DataSource, InitialCatalog és SnAdminFilePath beállításait használja
- external script: .\Deploy\Tool-Module.ps1 -SnAdminPath $SnAdminPath -ToolName install-services -ToolParameters "datasource:$DataSource","initialcatalog:$InitialCatalog","FORCEDREINSTALL:true" 

snwebpages
- it's job: Install webpages package which will create the webforms functionality of sensenet
- settings: A beállítások közül a megcímzett (alapértelmezetten Project) szekció SnAdminFilePath beállítását használja
- external script: .\Deploy\Tool-Module.ps1 -SnAdminPath $SnAdminPath -ToolName install-webpages

removedemo
- it's job: Általunk összeállított snadmin csomagot futtat, ami eltávolítja az sn webpages által felrakott demo tartalmakat
- settings: Fixen a Source szekció PackagesPath beállítását és az ezzel képzett fix nevű csomag elérését, illetve a megcímzett (alapértelmezetten Project) szekció SnAdminFilePath beállítását használja
- external script: .\Deploy\Package-Module.ps1 -SnAdminPath $SnAdminPath -PackagePath $PackagePath

adminusers
- it's job: Általunk összeállított példa snadmin csomag custom admin user beállításra és a default admin user deaktiválására
- settings: Fixen a Source szekció PackagesPath beállítását és az ezzel képzett fix nevű csomag elérését, illetve a megcímzett (alapértelmezetten Project) szekció SnAdminFilePath beállítását használja
- external script: .\Deploy\Package-Module.ps1 -SnAdminPath $SnAdminPath -PackagePath $PackagePath

install
- it's job: A projekt beállítások között deklarált custom tartalmak és egyéb előkészítő beállítások futtatására készült lépés
- settings: A beállítások közül a megcímzett (alapértelmezetten Project) szekció SnAdminFilePath és DeployFolderPath beállításait használja
- external script: .\Deploy\Package-Module.ps1 -SnAdminPath $SnAdminPath -PackagePath $PackagePath

createsite
- it's job: IIS Site és Application pool létrehozására szolgáló lépés
- settings: A beállítások közül a megcímzett (alapértelmezetten Project) szekció WebFolderPath, WebAppName, AppPoolName és Hosts beállításait használja
- external script: .\Ops\Create-IISSite.ps1 -DirectoryPath $ProjectWebFolderPath -SiteName $ProjectSiteName -PoolName $ProjectAppPoolName -SiteHosts $ProjectSiteHosts

sethost
- it's job: A felvett url-ek lokál gépen hosts file-ba felvételére szolgáló lépés
- settings: A beállítások közül a megcímzett (alapértelmezetten Project) szekció Hosts beállítását használja
- external script: .\Ops\Set-Host.ps1 -SiteHosts $ProjectSiteHosts

deploywebfolder
- it's job: Egy előre elkészített webfolder "template" kirakására szolgál
- settings: Fixen a Source szekció SnWebFolderFilePath beállítását és a megcímzett szekció WebFolderPath beállítását használja
- external script: .\Tools\Unzip-File.ps1 -filename $SnWebfolderPackPath -destname $ProjectWebFolderPath

index
- it's job: Lucene indexpopulálást hajt végre
- settings: A beállítások közül a megcímzett (alapértelmezetten Project) szekció SnAdminFilePath beállítását használja
- external script: .\Deploy\Index-Project.ps1 -SnAdminPath $SnAdminPath

import
- it's job: Snadmin segítségével importálja a beállításban megadott útvonalról a projekt tartalmakat
- settings: A beállítások közül a megcímzett (alapértelmezetten Project) szekció RepoFsFolderPath és SnAdminFilePath beállításait használja
- external script: .\Deploy\Import-Module.ps1 -SnAdminPath $SnAdminPath -SourcePath $ProjectRepoFsFolderPath
export
- it's job: Snadmin segítségével exportálja a beállításban megadott webfolder App_Datája alá a projekt tartalmakat egy dátumozott mappába
- settings: A beállítások közül a megcímzett (alapértelmezetten Project) szekció RepoFsFolderPath és SnAdminFilePath beállításait használja
- external script: .\Deploy\Export-Module.ps1 -SnAdminPath $SnAdminPath -TargetPath $ProjectWebFolderPath\App_Data\Export$CurrentDateTime

setrepourl
- it's job: A beállításokban felvett url-eket beállítja a repositoryban a beállításnak megfelelő site-okon
- settings: A beállítások közül a megcímzett (alapértelmezetten Project) szekció SnAdminFilePath beállítását használja
- external script: .\Deploy\Tool-Module.ps1 -SnAdminPath $SnAdminPath -ToolName seturl -ToolParameters "site:$ProjectSiteName","url:$HostnameToLower","authenticationType:$AuthenticationType"

backupdb
- it's job: Backupot készít az adatbázisról
- settings: A beállítások közül a megcímzett (alapértelmezetten Project) szekció DataSource, InitialCatalog és DbBackupFilePath beállításait használja
- external script: .\Ops\Backup-Db.ps1 -ServerName $DataSource -CatalogName $InitialCatalog -FileName $DbBackupFilePath

autobackupdb
- it's job: Backupot készít az adatbázisról
- settings: A beállítások közül a megcímzett (alapértelmezetten Project) szekció DataSource, InitialCatalog és DatabasesPath beállításait használja
- external script: .\Ops\Backup-Db.ps1 -ServerName "$DataSource" -CatalogName "$InitialCatalog" -FileName "$DatabaseBackupsFolderPath\$BackupName"

restoredb
- it's job: A megadott útvonalról restore-ol egy adatbázist (hálózati útvonalról még nem megoldott)
- settings: A beállítások közül a megcímzett (alapértelmezetten Project) szekció DataSource, InitialCatalog és DbBackupFilePath beállításait használja
- external script: .\Ops\Restore-Db.ps1 -ServerName $DataSource -CatalogName $InitialCatalog -FileName $DbBackupFilePath

dropdb
- it's job: Törli az adatbázist az sql szerverből
- settings: A beállítások közül a megcímzett (alapértelmezetten Project) szekció DataSource, InitialCatalog beállításait használja
- external script: .\Ops\Drop-Db.ps1 -ServerName "$DataSource" -CatalogName "$InitialCatalog" 

setconnection
- it's job: beállítja a connection stringet a web.configban és az snadminruntime configban, ez a két beállítás minimális feltétele az snadmin csomagok futtatásának
- settings: A beállítások közül a megcímzett (alapértelmezetten Project) szekció DataSource, InitialCatalog, SnAdminRCFilePath és WebConfigFilePath beállításait használja
- external script: .\Deploy\Set-Connection.ps1 -ConfigFilePath "$aConfigFilePath" -DataSource "$DataSource" -InitialCatalog "$InitialCatalog" 

downloaddatabase
- it's job: Letölti az adatbázis backupot egy url-ről és lementi a beállításban megadott útvonalra
- settings: Fixen a Source szekció DbBackupFileUrl és DbBackupFilePath beállításait használja
- external script: .\Dev\Download-File.ps1 -Url $WebPath -Output $LocalPath

downloadwebpack
- it's job: Letölti a webfolder "template"-et egy url-ről és lementi a beállításban megadott útvonalra
- settings: Fixen a Source szekció SnWebFolderFileUrl és SnWebFolderFilePath beállításait használja
- external script: .\Dev\Download-File.ps1 -Url $WebPath -Output $LocalPath

stopremote
- it's job: Leállítja az IIS site-ot egy távoli gépen
- settings: A beállítások közül a megcímzett (alapértelmezetten Project) szekció WebAppName és MachineName beállításait használja
- external script: .\Ops\Run-Remote.ps1 -RemoteServerName $MachineName -PsFilePath .\Ops\Stop-IISSite.ps1 -PsFileArgumentList $ProjectSiteName

startremote
- it's job: Elindítja az IIS site-ot egy távoli gépen
- settings: A beállítások közül a megcímzett (alapértelmezetten Project) szekció WebAppName és MachineName beállításait használja
- external script: .\Ops\Run-Remote.ps1 -RemoteServerName $MachineName -PsFilePath .\Ops\Start-IISSite.ps1 -PsFileArgumentList $ProjectSiteName

A fenti lépések még nélülöznek mindenféle rendszerezést. Lehet később szét lesznek szedve funkciók szerint külön file-okba, de lehet hogy csak szimplán csoportosítva lesznek a könnyebb átláthatóság kedvéért. 

Az itt tárgyalt lépések tetszőlegesen bővíthetők, a már korábban említett módon. Tehát célszerű az adott projekthez saját ps1 file-t készíteni (pl. Sajátproject-Modules.ps1) és szimplán elhelyezni az "AutoExt" mappában. Innentől kezdve automatikusan elérhetőek a benne deklarált lépések. (A file neve egyelőre "Modules"-ra végződik, ez ne zavarjon meg senkit, aki powershellben járatos. Célszerűen "Steps"-nek kellene hívni, csak itt még nem neveztük át.)

Example custom scripts
"Deploy-Modules.ps1":

prinstall
- it's job: a default lépések között található install lépéssel megegyezik, azzal a különbséggel, hogy forrásként fixen a Project szekciót használja
- settings: A beállítások közül a megcímzett (alapértelmezetten Project) szekció SnAdminFilePath és fixen a Project szekció DeployFolderPath beállítását használja
- external script: .\Deploy\Package-Module.ps1 -SnAdminPath $SnAdminPath -PackagePath $PackagePath

primport
- it's job: a default lépések között található import lépéssel megegyezik, azzal a különbséggel, hogy forrásként fixen a Project szekciót használja
- settings: A beállítások közül a megcímzett (alapértelmezetten Project) szekció SnAdminFilePath és fixen a Project szekció RepoFsFolderPath beállítását használja
- external script: .\Deploy\Import-Module.ps1 -SnAdminPath $SnAdminPath -SourcePath $ProjectRepoFsFolderPath

prasmdeploy
- it's job: A priject bin folderének tartalmát kimásolja a cél webfolder bin mappájába
- settings: A beállítások közül a megcímzett (alapértelmezetten Project) szekció AsmFolderPath és fixen a Project szekció AsmFolderPath beállítását használja
- external script: nem használ külső scriptet, a másolási logika a lépésben van deklarálva

"Old-Modules.ps1"

proldimport 
- it's job: sn7-t megelőző sensenet verziókban használt import toolon alapuló content importálás
- settings: A beállítások közül fixen a Project szekció RepoFsFolderPath és a megcímzett (alapértelmezetten Project) szekció ImporterPath és AsmFolderPath beállításait használja
- external script: .\Old\Import-Module.ps1 -ImporterPath $ImporterPath -SourcePath $ProjectRepoFsFolderPath -AsmFolderPath $AsmFolderPath
- megjegyzés: távoli gépen, hálózati útvonalról futtatásához engedélyezve kell lennia tool configjában a távoli assemblyk betöltésének

proldexport 
- it's job: sn7-t megelőző sensenet verziókban használt import toolon alapuló content exportálás
- settings: A beállítások közül fixen a Project szekció RepoFsFolderPath és a megcímzett (alapértelmezetten Project) szekció WebFolderPath, ExporterPath és AsmFolderPath beállításait használja
- external script: .\Old\Export-Module.ps1 -ExporterPath $ExporterPath -TargetPath $ProjectWebFolderPath\App_Data\Export$CurrentDateTime -AsmFolderPath $AsmFolderPath
- megjegyzés: távoli gépen, hálózati útvonalról futtatásához engedélyezve kell lennia tool configjában a távoli assemblyk betöltésének

proldindex 
- it's job: sn7-t megelőző sensenet verziókban használt import toolon alapuló lucene indexelés
- settings: A beállítások közül fixen a megcímzett (alapértelmezetten Project) szekció IndexerPath és AsmFolderPath beállításait használja
- external script: .\Old\Index-Module.ps1 -IndexerPath $IndexerPath -AsmFolderPath $AsmFolderPath
- megjegyzés: távoli gépen, hálózati útvonalról futtatásához engedélyezve kell lennia tool configjában a távoli assemblyk betöltésének

## Custom Step deklaráció 

Ahhoz hogy a fenti automatizmus működhessen, illetve testzőleges lépésekkel lehessen kiegészíteni a lépésnek az alábbi módon kell felépülnie:

```powershell
Function Step-Lepesneve {
<#
.SYNOPSIS
Lépés rövid leírása
.DESCRIPTION
lépés leírásának bővebb kifejtése
#>
[CmdletBinding(SupportsShouldProcess=$True)]
Param(
[parameter(Mandatory=$false)]
[String]$section="Project"
)

try {
$ProjectSiteName = $GlobalSettings."$section".WebAppName
& "$ScriptBaseFolderPath\Ops\Stop-IISSite.ps1" $ProjectSiteName
$script:Result = $LASTEXITCODE
}
catch {
$script:Result = 1
}
}
```

A fenti példában a lépés közvetlenül meghívható a Run-on keresztül, ha nincs azonos nevű forgatókönyv:
```powershell
.\Run.ps1 lepesneve
```

vagy bővebben (itt ne tévesszen meg, hogy a paraméter neve plot):
```powershell
.\Run.ps1 -Plot lepesneve -Settings local
```

Az adott lépés futtatáskor a script leírásából megjelenítjük a synopsys részt, valahogy így:

```console
================================================
============= Plotneve/Lepesneve =============
================================================
Synopsis: Lépés rövid leírása
Progress: 100
```

A descriptiont érdemes a jövő felhasználói számára kitölteni, illetve itt használható egyéb komment lehetőség is. Ezek a Get-Help powershell függvénnyel hívhatók elő.

A következő paraméter biztosítja a step számára, hogy megcímezhető legyen a beállítás szekció. Példánkban a default szekció a "Project". Ha a lépés nem igényli, nem kötelező deklarálni, de azt vegyük figyelembe, hogy ha Section paraméterrel érkezik a hívás, a lépés hibát fog dobni.
```powershell
[CmdletBinding(SupportsShouldProcess=$True)]
Param(
[parameter(Mandatory=$false)]
[String]$section="Project"
)
```

Az üzleti logikát érdemes try/cacth feldolgozásba rakni, így biztosítható, hogy hiba esetén is legyen visszaadott érték. Általános hiba esetén megegyezés szerint 1-es értékkel térünk vissza. Ettől el lehet térni, tudomásom szerint - még - nem használja semmi a visszatérési értékeket, egyelőre csak információforrásként utazik.

A settings file beállításokat a section paraméterrel együtt egy globális változóból érjük el. Ebben már össze van fűzve a projekt és default beállítás is.
```powershell
$GlobalSettings."$section".beállításnév
```

Végül érdemes normál lefutás esetén a exitcode környezeti változó értékével visszatérni. Console applikációk esetén valószínűleg ez megfelelő értéket fog adni, egyedi scriptek esetén érdemes emulálni:
```powershell
$script:Result = $LASTEXITCODE
```

## Tfs Build Szerver

Végezetül egy megjegyzés: mivel a build szerver képes powershell scripteket futtatni és ha a távoli környezetek is megfelelően be vannak állítva a settings file-okban, például belőttük a teszt szerver eléréséhez szükséges beállításokat, akkor minden további nélkül alkalmazhatóak a fent említett futtatási információk build szerver összeállításakor is. Ez esetben nem szükséges a környezeti változókat külön még a build szerveren is beállítani, futtatáskor ugyanúgy a settings file-ból fogja ezeket beolvasni. Hacsak nem feltétlenül szükséges mindenáron külön kezelni, akár lépésenként akor plot futtatásban egyszerűbbé válik a build szerver összeállítása is. Hiszen, ha egy adott forgatókönyv lefut lokál környezetből az adott szerverre, valószínűleg build szerverről is futni fog.

## Known issues

There are some steps we've not fully automated yet. So some manual setups may required, such as:

- The script won't automatically map your Visual Studio version and its location which is needed to get latest tfs and solution build steps. You have to set `tf.exe` path properly in `project-local.json`'s Tools.VisualStudio property
- Unziping archive script uses 7zip, the location for `7za.exe` file needs to be set in `project-local.json` too
- If you use sql alias like `MySenseNetContentRepositoryDatasource` in default Sense/Net install, you have to set it manually before using the script or you have to set different Datasource in `project-local.json`
- Nuget packages and snadmin version in the project should be checked if they're matching the proper sensenet version.
