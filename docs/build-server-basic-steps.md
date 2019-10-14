# Build server basic steps

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