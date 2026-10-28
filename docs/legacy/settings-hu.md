<!-- documentation-anchors:start -->
<a id="doc-configuration-settings"></a>
<!-- documentation-anchors:end -->
# Konfigurációs beállítások

<!-- documentation-navigation -->
[English](settings.md) | [Magyar](settings-hu.md) · [Dokumentáció](../README-hu.md) · [Projekt](../../README-hu.md)
<!-- /documentation-navigation -->

A Plot Manager konfigurációját JSON-beállításfájlok kezelik, amelyek környezetspecifikus paramétereket, plotdefiníciókat és működési beállításokat adnak meg. A keretrendszer rétegzett konfigurációt használ, amelyben a projektspecifikus beállítások felülírják az alapértelmezett konfigurációkat.

<!-- documentation-anchors:start -->
<a id="doc-settings-file-structure"></a>
<!-- documentation-anchors:end -->
## A beállításfájl szerkezete

<!-- documentation-anchors:start -->
<a id="doc-default-configuration-files"></a>
<!-- documentation-anchors:end -->
### Alapértelmezett konfigurációs fájlok
- **`project-default.json`**: Alapbeállításokat és közös plotdefiníciókat tartalmaz
- **`project-local.json`**: Helyi fejlesztői környezeti felülírások
- **Környezetspecifikus fájlok**: Egyedi konfigurációk eltérő telepítési célokhoz

<!-- documentation-anchors:start -->
<a id="doc-configuration-merging"></a>
<!-- documentation-anchors:end -->
### Konfigurációk összefésülése
Plotvégrehajtáskor a keretrendszer ebben a sorrendben fésüli össze a konfigurációkat:
1. Alapbeállítások betöltése a `project-default.json` fájlból
2. Környezetspecifikus beállítások betöltése (például `project-local.json`)
3. Ütközés esetén a projektbeállítások felülírják az alapbeállításokat
4. A `PLOTMANAGER_` előtagú környezeti változók bármely beállítást felülírják

<!-- documentation-anchors:start -->
<a id="doc-configuration-sections"></a>
<!-- documentation-anchors:end -->
## Konfigurációs szekciók

<!-- documentation-anchors:start -->
<a id="doc-plots-section"></a>
<!-- documentation-anchors:end -->
### Plots szekció
Lépéssorozatként definiálja az automatizációs forgatókönyveket:

```json
{
  "Plots": {
    "fullinstall": [
      "stop",
      "restorepckgs",
      "prbuild",
      "dropdb",
      "snservices",
      "createsite",
      "start"
    ],
    "backup": [
      "stop",
      "backupdb",
      "start"
    ]
  }
}
```

**Lépésszintaxis**: A lépések kettőspontos jelöléssel szekciót is megcímezhetnek:
- `"index"`: A lépés végrehajtása az alapértelmezett szekcióval
- `"index:TestSite"`: A lépés végrehajtása a "TestSite" konfigurációs szekcióval

<!-- documentation-anchors:start -->
<a id="doc-source-section"></a>
<!-- documentation-anchors:end -->
### Source szekció
Az egyes környezetektől független erőforráshelyeket és megosztott útvonalakat definiál:

```json
{
  "Source": {
    "PackagesPath": "..\\Packages",
    "DbBackupFilePath": "..\\Databases\\project-latest.bak",
    "DatabasesPath": "..\\Databases\\",
    "VsTemplatesRepo": "https://github.com/SenseNet/sn-vs-projecttemplates",
    "TemplatesBranch": "master",
    "SnWebFolderFilePath": "..\\Archives\\project-Web.zip"
  }
}
```

<!-- documentation-anchors:start -->
<a id="doc-project-section"></a>
<!-- documentation-anchors:end -->
### Project szekció
A legtöbb lépés alapértelmezett konfigurációs szekciója, jellemzően helyi fejlesztői beállításokkal:

```json
{
  "Project": {
    "DataSource": "MySenseNetContentRepositoryDatasource",
    "InitialCatalog": "sensenetdb",
    "WebAppName": "sensenetapp",
    "AppPoolName": "sensenetapp",
    "Hosts": ["sensenet.local"],
    "DotNetVersion": "v4.0",
    "WebFolderPath": "..\\WebApplication",
    "AsmFolderPath": "..\\WebApplication\\bin",
    "WebConfigFilePath": "..\\WebApplication\\web.config"
  }
}
```

<!-- documentation-anchors:start -->
<a id="doc-common-configuration-properties"></a>
<!-- documentation-anchors:end -->
## Gyakori konfigurációs tulajdonságok

<!-- documentation-anchors:start -->
<a id="doc-database-settings"></a>
<!-- documentation-anchors:end -->
### Adatbázis-beállítások
- **`DataSource`**: SQL Server-példánynév vagy kapcsolati karakterlánc
- **`InitialCatalog`**: Adatbázisnév
- **`UserName`**: SQL Server-hitelesítési felhasználónév (opcionális)
- **`UserPsw`**: SQL Server-hitelesítési jelszó (opcionális)

<!-- documentation-anchors:start -->
<a id="doc-application-settings"></a>
<!-- documentation-anchors:end -->
### Alkalmazásbeállítások
- **`WebAppName`**: IIS-site neve
- **`AppPoolName`**: IIS-alkalmazáskészlet neve
- **`DotNetVersion`**: .NET Framework-verzió (például "v4.0")
- **`Hosts`**: Gépnevek tömbje helyi fejlesztéshez

<!-- documentation-anchors:start -->
<a id="doc-file-system-paths"></a>
<!-- documentation-anchors:end -->
### Fájlrendszerútvonalak
- **`WebFolderPath`**: Webalkalmazás gyökérkönyvtára
- **`AsmFolderPath`**: Bináris assemblyk könyvtára (jellemzően bin/)
- **`ToolsFolderPath`**: Segédprogramok és eszközök könyvtára
- **`SolutionFilePath`**: Visual Studio solutionfájl útvonala

<!-- documentation-anchors:start -->
<a id="doc-sensenet-specific-settings"></a>
<!-- documentation-anchors:end -->
### SenseNet-specifikus beállítások
- **`SnAdminFilePath`**: Az snadmin.exe segédprogram útvonala
- **`IndexerPath`**: Az indexfeltöltő futtatható fájl útvonala
- **`RepoFsFolderPath`**: Repositorytartalom importkönyvtára
- **`DeployFolderPath`**: Telepítési manifeszt könyvtára

<!-- documentation-anchors:start -->
<a id="doc-environment-specific-sections"></a>
<!-- documentation-anchors:end -->
## Környezetspecifikus szekciók

Hozz létre egyedi szekciókat a különböző telepítési célokhoz:

```json
{
  "Production": {
    "DataSource": "prod-sql-server",
    "InitialCatalog": "ProductionDB",
    "WebAppName": "ProductionSite",
    "MachineName": "PROD-SERVER-01"
  },
  "Staging": {
    "DataSource": "staging-sql-server",
    "InitialCatalog": "StagingDB",
    "WebAppName": "StagingSite"
  }
}
```

<!-- documentation-anchors:start -->
<a id="doc-tools-section"></a>
<!-- documentation-anchors:end -->
## Tools szekció
A különböző lépések által használt külső segédprogramok útvonalait definiálja:

```json
{
  "Tools": {
    "VisualStudio": "C:\\Program Files\\Microsoft Visual Studio\\2019\\Professional\\Common7\\IDE\\CommonExtensions\\Microsoft\\TeamFoundation\\Team Explorer\\tf.exe",
    "UnZipperFilePath": "C:\\Program Files\\7-Zip\\7z.exe",
    "NuGetFilePath": "..\\Tools\\nuget\\nuget.exe"
  }
}
```

<!-- documentation-anchors:start -->
<a id="doc-environment-variable-overrides"></a>
<!-- documentation-anchors:end -->
## Környezeti változós felülírások

Bármely konfigurációs beállítás felülírható `PLOTMANAGER_` előtagú környezeti változókkal:

```powershell
# Override database settings
$env:PLOTMANAGER_DataSource = "new-sql-server"
$env:PLOTMANAGER_InitialCatalog = "NewDatabase"

# Override application settings
$env:PLOTMANAGER_WebAppName = "TestApplication"
```

<!-- documentation-anchors:start -->
<a id="doc-best-practices"></a>
<!-- documentation-anchors:end -->
## Bevált gyakorlatok

<!-- documentation-anchors:start -->
<a id="doc-security"></a>
<!-- documentation-anchors:end -->
### Biztonság
- Az érzékeny adatokat, például jelszavakat környezeti változókban tárold konfigurációs fájlok helyett
- Ha lehetséges, használj SQL Server integrált hitelesítést
- A konfigurációs fájlokat megfelelő fájlrendszer-jogosultságokkal védd

<!-- documentation-anchors:start -->
<a id="doc-organization"></a>
<!-- documentation-anchors:end -->
### Rendszerezés
- A környezetspecifikus beállításokat tartsd külön a közös konfigurációktól
- Használj leíró szekcióneveket speciális karakterek és szóközök nélkül
- Dokumentáld az egyedi konfigurációs tulajdonságokat és céljukat

<!-- documentation-anchors:start -->
<a id="doc-maintenance"></a>
<!-- documentation-anchors:end -->
### Karbantartás
- Rendszeresen validáld a konfigurációs útvonalakat, és ellenőrizd az eszközök elérhetőségét
- Teszteld a konfigurációkat minden célkörnyezetben
- A konfigurációs fájlokat verziókezeld, az érzékeny adatokat viszont zárd ki
