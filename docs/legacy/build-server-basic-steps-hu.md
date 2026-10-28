<!-- documentation-anchors:start -->
<a id="doc-build-server-basic-steps"></a>
<!-- documentation-anchors:end -->
# Buildszerver-alaplépések

<!-- documentation-navigation -->
[English](build-server-basic-steps.md) | [Magyar](build-server-basic-steps-hu.md) · [Dokumentáció](../README-hu.md) · [Projekt](../../README-hu.md)
<!-- /documentation-navigation -->

A külső scriptek részletezése nélkül is több olyan lépést készítettünk, amelyeket a mindennapi sensenet fejlesztői környezet kezeléséhez használunk. Itt csak a lépések "rövid nevét" használom, de az AutoExt mappában lévő scriptekben "Step-" előtaggal találhatók. Az előtag a szokásos PowerShell-függvényektől különbözteti meg őket. Például a "stop" lépés "Step-Stop" néven található a "Default-Modules.ps1" fájlban. A külső scriptek külön fájlok, és kézi paraméterezéssel is futtathatók, de ekkor elveszítenénk az előre definiált beállítások kényelmét és automatizmusát. Ezek a külső scriptfájlok a többi mappában találhatók. Itt nincs idő és hely minden használt külső scriptet és paramétert leírni. Talán később.

*stop*
- feladata: Leállítja az IIS-site-ot és alkalmazáskészletét
- beállítások: A beállítási JSON megadott szekciójának értékeit használja; az alapértelmezett szekció Project
- külső script: .\Ops\Stop-IISSite.ps1 $ProjectSiteName

start
- feladata: Elindítja az IIS-site-ot és alkalmazáskészletét
- beállítások: A beállítási JSON megadott szekciójának értékeit használja; az alapértelmezett szekció Project
- külső script .\Ops\Start-IISSite.ps1 $ProjectSiteName

getlatest
- feladata: Lekéri a projekt solution legújabb verzióját TFS-ből
- beállítások: Fixen a Project szekció SourceFolderPath beállítását és a Tools szekció VisualStudio beállítását használja
- külső script: .\Dev\GetLatestSolution.ps1 -tfexepath $TfExePath -location $ProjectSourceFolderPath

restorepckgs
- feladata: A projektben használt nuget csomagok letöltése, befrissítése
- beállítások: fixen használja a Tools szekció NuGetSourceUrl és NuGetFilePath beállításait, illetve szintén fixen a project szekció SolutionFilePath beállítását
- külső script: .\Dev\Download-File.ps1 -Url $NuGetSourcePath -Output $NuGetFilePath
- különlegesség: a külső script csak a segédprogramot (nuget.exe) frissíti be, a csomagok frissítését a lépés közvetlenül a console app segítségével végzi

prbuild
- feladata: Lefordítja a Visual Studio solutiont
- beállítások: Szintén fixen a Project szekció SolutionFilePath beállítását használja
- külső script: .\Dev\Build-Solution.ps1 -slnPath $ProjectSolutionFilePath

snservices
- feladata: Telepíti a services csomagot, amely létrehozza a sensenet alap API-rétegét
- beállítások: A beállítások közül a megcímzett (alapértelmezetten Project) szekció WebConfigFilePath, ToolsFolderPath, DataSource, InitialCatalog és SnAdminFilePath beállításait használja
- külső script: .\Deploy\Tool-Module.ps1 -SnAdminPath $SnAdminPath -ToolName install-services -ToolParameters "datasource:$DataSource","initialcatalog:$InitialCatalog","FORCEDREINSTALL:true"

snwebpages
- feladata: Telepíti a webpages csomagot, amely létrehozza a sensenet WebForms-funkcióit
- beállítások: A beállítások közül a megcímzett (alapértelmezetten Project) szekció SnAdminFilePath beállítását használja
- külső script: .\Deploy\Tool-Module.ps1 -SnAdminPath $SnAdminPath -ToolName install-webpages

removedemo
- feladata: Általunk összeállított snadmin csomagot futtat, ami eltávolítja az sn webpages által felrakott demo tartalmakat
- beállítások: Fixen a Source szekció PackagesPath beállítását és az ezzel képzett fix nevű csomag elérését, illetve a megcímzett (alapértelmezetten Project) szekció SnAdminFilePath beállítását használja
- külső script: .\Deploy\Package-Module.ps1 -SnAdminPath $SnAdminPath -PackagePath $PackagePath

adminusers
- feladata: Általunk összeállított példa snadmin csomag custom admin user beállításra és a default admin user deaktiválására
- beállítások: Fixen a Source szekció PackagesPath beállítását és az ezzel képzett fix nevű csomag elérését, illetve a megcímzett (alapértelmezetten Project) szekció SnAdminFilePath beállítását használja
- külső script: .\Deploy\Package-Module.ps1 -SnAdminPath $SnAdminPath -PackagePath $PackagePath

install
- feladata: A projekt beállítások között deklarált custom tartalmak és egyéb előkészítő beállítások futtatására készült lépés
- beállítások: A beállítások közül a megcímzett (alapértelmezetten Project) szekció SnAdminFilePath és DeployFolderPath beállításait használja
- külső script: .\Deploy\Package-Module.ps1 -SnAdminPath $SnAdminPath -PackagePath $PackagePath

createsite
- feladata: IIS Site és Application pool létrehozására szolgáló lépés
- beállítások: A beállítások közül a megcímzett (alapértelmezetten Project) szekció WebFolderPath, WebAppName, AppPoolName és Hosts beállításait használja
- külső script: .\Ops\Create-IISSite.ps1 -DirectoryPath $ProjectWebFolderPath -SiteName $ProjectSiteName -PoolName $ProjectAppPoolName -SiteHosts $ProjectSiteHosts

sethost
- feladata: A felvett url-ek lokál gépen hosts file-ba felvételére szolgáló lépés
- beállítások: A beállítások közül a megcímzett (alapértelmezetten Project) szekció Hosts beállítását használja
- külső script: .\Ops\Set-Host.ps1 -SiteHosts $ProjectSiteHosts

deploywebfolder
- feladata: Egy előre elkészített webfolder "template" kirakására szolgál
- beállítások: Fixen a Source szekció SnWebFolderFilePath beállítását és a megcímzett szekció WebFolderPath beállítását használja
- külső script: .\Tools\Unzip-File.ps1 -filename $SnWebfolderPackPath -destname $ProjectWebFolderPath

index
- feladata: Lucene indexpopulálást hajt végre
- beállítások: A beállítások közül a megcímzett (alapértelmezetten Project) szekció SnAdminFilePath beállítását használja
- külső script: .\Deploy\Index-Project.ps1 -SnAdminPath $SnAdminPath

import
- feladata: Snadmin segítségével importálja a beállításban megadott útvonalról a projekt tartalmakat
- beállítások: A beállítások közül a megcímzett (alapértelmezetten Project) szekció RepoFsFolderPath és SnAdminFilePath beállításait használja
- külső script: .\Deploy\Import-Module.ps1 -SnAdminPath $SnAdminPath -SourcePath $ProjectRepoFsFolderPath
export
- feladata: Snadmin segítségével exportálja a beállításban megadott webfolder App_Datája alá a projekt tartalmakat egy dátumozott mappába
- beállítások: A beállítások közül a megcímzett (alapértelmezetten Project) szekció RepoFsFolderPath és SnAdminFilePath beállításait használja
- külső script: .\Deploy\Export-Module.ps1 -SnAdminPath $SnAdminPath -TargetPath $ProjectWebFolderPath\App_Data\Export$CurrentDateTime

setrepourl
- feladata: A beállításokban felvett url-eket beállítja a repositoryban a beállításnak megfelelő site-okon
- beállítások: A beállítások közül a megcímzett (alapértelmezetten Project) szekció SnAdminFilePath beállítását használja
- külső script: .\Deploy\Tool-Module.ps1 -SnAdminPath $SnAdminPath -ToolName seturl -ToolParameters "site:$ProjectSiteName","url:$HostnameToLower","authenticationType:$AuthenticationType"

backupdb
- feladata: Backupot készít az adatbázisról
- beállítások: A beállítások közül a megcímzett (alapértelmezetten Project) szekció DataSource, InitialCatalog és DbBackupFilePath beállításait használja
- külső script: .\Ops\Backup-Db.ps1 -ServerName $DataSource -CatalogName $InitialCatalog -FileName $DbBackupFilePath

autobackupdb
- feladata: Backupot készít az adatbázisról
- beállítások: A beállítások közül a megcímzett (alapértelmezetten Project) szekció DataSource, InitialCatalog és DatabasesPath beállításait használja
- külső script: .\Ops\Backup-Db.ps1 -ServerName "$DataSource" -CatalogName "$InitialCatalog" -FileName "$DatabaseBackupsFolderPath\$BackupName"

restoredb
- feladata: A megadott útvonalról restore-ol egy adatbázist (hálózati útvonalról még nem megoldott)
- beállítások: A beállítások közül a megcímzett (alapértelmezetten Project) szekció DataSource, InitialCatalog és DbBackupFilePath beállításait használja
- külső script: .\Ops\Restore-Db.ps1 -ServerName $DataSource -CatalogName $InitialCatalog -FileName $DbBackupFilePath

dropdb
- feladata: Törli az adatbázist az sql szerverből
- beállítások: A beállítások közül a megcímzett (alapértelmezetten Project) szekció DataSource, InitialCatalog beállításait használja
- külső script: .\Ops\Drop-Db.ps1 -ServerName "$DataSource" -CatalogName "$InitialCatalog"

setconnection
- feladata: beállítja a connection stringet a web.configban és az snadminruntime configban, ez a két beállítás minimális feltétele az snadmin csomagok futtatásának
- beállítások: A beállítások közül a megcímzett (alapértelmezetten Project) szekció DataSource, InitialCatalog, SnAdminRCFilePath és WebConfigFilePath beállításait használja
- külső script: .\Deploy\Set-Connection.ps1 -ConfigFilePath "$aConfigFilePath" -DataSource "$DataSource" -InitialCatalog "$InitialCatalog"

downloaddatabase
- feladata: Letölti az adatbázis backupot egy url-ről és lementi a beállításban megadott útvonalra
- beállítások: Fixen a Source szekció DbBackupFileUrl és DbBackupFilePath beállításait használja
- külső script: .\Dev\Download-File.ps1 -Url $WebPath -Output $LocalPath

downloadwebpack
- feladata: Letölti a webfolder "template"-et egy url-ről és lementi a beállításban megadott útvonalra
- beállítások: Fixen a Source szekció SnWebFolderFileUrl és SnWebFolderFilePath beállításait használja
- külső script: .\Dev\Download-File.ps1 -Url $WebPath -Output $LocalPath

stopremote
- feladata: Leállítja az IIS site-ot egy távoli gépen
- beállítások: A beállítások közül a megcímzett (alapértelmezetten Project) szekció WebAppName és MachineName beállításait használja
- külső script: .\Ops\Run-Remote.ps1 -RemoteServerName $MachineName -PsFilePath .\Ops\Stop-IISSite.ps1 -PsFileArgumentList $ProjectSiteName

startremote
- feladata: Elindítja az IIS site-ot egy távoli gépen
- beállítások: A beállítások közül a megcímzett (alapértelmezetten Project) szekció WebAppName és MachineName beállításait használja
- külső script: .\Ops\Run-Remote.ps1 -RemoteServerName $MachineName -PsFilePath .\Ops\Start-IISSite.ps1 -PsFileArgumentList $ProjectSiteName

A fenti lépések még nélülöznek mindenféle rendszerezést. Lehet később szét lesznek szedve funkciók szerint külön file-okba, de lehet hogy csak szimplán csoportosítva lesznek a könnyebb átláthatóság kedvéért.

Az itt tárgyalt lépések tetszőlegesen bővíthetők, a már korábban említett módon. Tehát célszerű az adott projekthez saját ps1 file-t készíteni (pl. Sajátproject-Modules.ps1) és szimplán elhelyezni az "AutoExt" mappában. Innentől kezdve automatikusan elérhetőek a benne deklarált lépések. (A file neve egyelőre "Modules"-ra végződik, ez ne zavarjon meg senkit, aki powershellben járatos. Célszerűen "Steps"-nek kellene hívni, csak itt még nem neveztük át.)

Példák egyedi scriptekre
"Deploy-Modules.ps1":

prinstall
- feladata: a default lépések között található install lépéssel megegyezik, azzal a különbséggel, hogy forrásként fixen a Project szekciót használja
- beállítások: A beállítások közül a megcímzett (alapértelmezetten Project) szekció SnAdminFilePath és fixen a Project szekció DeployFolderPath beállítását használja
- külső script: .\Deploy\Package-Module.ps1 -SnAdminPath $SnAdminPath -PackagePath $PackagePath

primport
- feladata: a default lépések között található import lépéssel megegyezik, azzal a különbséggel, hogy forrásként fixen a Project szekciót használja
- beállítások: A beállítások közül a megcímzett (alapértelmezetten Project) szekció SnAdminFilePath és fixen a Project szekció RepoFsFolderPath beállítását használja
- külső script: .\Deploy\Import-Module.ps1 -SnAdminPath $SnAdminPath -SourcePath $ProjectRepoFsFolderPath

prasmdeploy
- feladata: A priject bin folderének tartalmát kimásolja a cél webfolder bin mappájába
- beállítások: A beállítások közül a megcímzett (alapértelmezetten Project) szekció AsmFolderPath és fixen a Project szekció AsmFolderPath beállítását használja
- külső script: nem használ külső scriptet, a másolási logika a lépésben van deklarálva

"Old-Modules.ps1"

proldimport
- feladata: sn7-t megelőző sensenet verziókban használt import toolon alapuló content importálás
- beállítások: A beállítások közül fixen a Project szekció RepoFsFolderPath és a megcímzett (alapértelmezetten Project) szekció ImporterPath és AsmFolderPath beállításait használja
- külső script: .\Old\Import-Module.ps1 -ImporterPath $ImporterPath -SourcePath $ProjectRepoFsFolderPath -AsmFolderPath $AsmFolderPath
- megjegyzés: távoli gépen, hálózati útvonalról futtatásához engedélyezve kell lennia tool configjában a távoli assemblyk betöltésének

proldexport
- feladata: sn7-t megelőző sensenet verziókban használt import toolon alapuló content exportálás
- beállítások: A beállítások közül fixen a Project szekció RepoFsFolderPath és a megcímzett (alapértelmezetten Project) szekció WebFolderPath, ExporterPath és AsmFolderPath beállításait használja
- külső script: .\Old\Export-Module.ps1 -ExporterPath $ExporterPath -TargetPath $ProjectWebFolderPath\App_Data\Export$CurrentDateTime -AsmFolderPath $AsmFolderPath
- megjegyzés: távoli gépen, hálózati útvonalról futtatásához engedélyezve kell lennia tool configjában a távoli assemblyk betöltésének

proldindex
- feladata: sn7-t megelőző sensenet verziókban használt import toolon alapuló lucene indexelés
- beállítások: A beállítások közül fixen a megcímzett (alapértelmezetten Project) szekció IndexerPath és AsmFolderPath beállításait használja
- külső script: .\Old\Index-Module.ps1 -IndexerPath $IndexerPath -AsmFolderPath $AsmFolderPath
- megjegyzés: távoli gépen, hálózati útvonalról futtatásához engedélyezve kell lennia tool configjában a távoli assemblyk betöltésének
