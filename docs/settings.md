# Settings
Now it's time to speak about how the settings file is built up. It should be created once when the project starts than you do not have to bother about it later, since you want to improve automatization and expand the range of configurations like additional enviroments, integration, etc.

There're two settings file by default, one responsible for project configurations is mentioned above. It names project-local, settings but can be renamed of course, for example can have multiple different name when you're working on multiple projects. In this case you have to modifify the name of the default settings is the Run.ps1, or call the -Settings parameter with this name.

The other settings file names project-default.settings, which means you cant have a project file names default. This settings file is responsible for project-independent configurations, that is useful when we have multiple projects with commong configurations. When you execute Run.ps1 the installer merges the settings stored in the two files and puts the project configs in advance.

The two files contain the following sections:
- **Plots**: Responsible for
- Source:
- 

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