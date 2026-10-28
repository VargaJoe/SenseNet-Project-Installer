<!-- documentation-anchors:start -->
<a id="doc-plots-and-steps-audit--grouping-proposal"></a>
<!-- documentation-anchors:end -->
# Plotok és lépések auditja és csoportosítási javaslata

<!-- documentation-navigation -->
[English](plots-steps-audit.md) | [Magyar](plots-steps-audit-hu.md) · [Dokumentáció](README-hu.md) · [Projekt](../README-hu.md)
<!-- /documentation-navigation -->

<!-- documentation-anchors:start -->
<a id="doc-audit-date"></a>
<!-- documentation-anchors:end -->
## Az audit dátuma
2025-07-07

<!-- documentation-anchors:start -->
<a id="doc-scope"></a>
<!-- documentation-anchors:end -->
## Hatókör
Minden lépésfüggvény itt: `src/Deployment/Scripts/AutoExt/Default-Modules.ps1`

<!-- documentation-anchors:start -->
<a id="doc-step-functions-raw-list"></a>
<!-- documentation-anchors:end -->
## Lépésfüggvények (nyers lista)
- Step-Stop
- Step-Start
- Step-GetLatest
- Step-GetLatestVsTemplates
- Step-RestorePckgs
- Step-PrBuild
- Step-CrArtifact
- Step-Publish
- Step-CleanPublishFolder
- Step-SnServices
- Step-SnWebPages
- Step-SnWorkspaces
- Step-SnWorkflow
- Step-SnNotification
- Step-RemoveDemo
- Step-AdminUsers
- Step-Install
- Step-CreateSite
- Step-SetHost
- Step-Index
- Step-Import
- Step-Export
- Step-CreatePackage
- Step-SetRepoUrl
- Step-BackupDb
- Step-AutoBackupDb
- Step-RestoreDb
- Step-DropDb
- Step-CreateEmptyDb
- Step-SetConfigs
- Step-GetSettings
- Step-ListSettings
- Step-SetConnection
- Step-DownloadDatabase
- Step-DownloadWebPack
- Step-StopRemote
- Step-StartRemote
- Step-WebAppOff
- Step-WebAppOn
- Step-WarmApp
- Step-TestWebfolder

<!-- documentation-anchors:start -->
<a id="doc-proposed-groupings"></a>
<!-- documentation-anchors:end -->
## Javasolt csoportosítások

<!-- documentation-anchors:start -->
<a id="doc-system-operations"></a>
<!-- documentation-anchors:end -->
### Rendszerműveletek
- Step-Stop
- Step-Start
- Step-StopRemote
- Step-StartRemote
- Step-WebAppOff
- Step-WebAppOn
- Step-WarmApp
- Step-CreateSite
- Step-SetHost

<!-- documentation-anchors:start -->
<a id="doc-database-operations"></a>
<!-- documentation-anchors:end -->
### Adatbázis-műveletek
- Step-BackupDb
- Step-AutoBackupDb
- Step-RestoreDb
- Step-DropDb
- Step-CreateEmptyDb
- Step-SetConnection
- Step-SetConfigs
- Step-DownloadDatabase

<!-- documentation-anchors:start -->
<a id="doc-build--deployment"></a>
<!-- documentation-anchors:end -->
### Build és telepítés
- Step-GetLatest
- Step-GetLatestVsTemplates
- Step-RestorePckgs
- Step-PrBuild
- Step-CrArtifact
- Step-Publish
- Step-CleanPublishFolder
- Step-CreatePackage
- Step-DownloadWebPack
- Step-TestWebfolder

<!-- documentation-anchors:start -->
<a id="doc-sensenetproject-operations"></a>
<!-- documentation-anchors:end -->
### Sensenet-/projektműveletek
- Step-SnServices
- Step-SnWebPages
- Step-SnWorkspaces
- Step-SnWorkflow
- Step-SnNotification
- Step-RemoveDemo
- Step-AdminUsers
- Step-Install
- Step-Import
- Step-Export
- Step-Index
- Step-SetRepoUrl

<!-- documentation-anchors:start -->
<a id="doc-settings--utility"></a>
<!-- documentation-anchors:end -->
### Beállítások és segédek
- Step-GetSettings
- Step-ListSettings

<!-- documentation-anchors:start -->
<a id="doc-notes--recommendations"></a>
<!-- documentation-anchors:end -->
## Megjegyzések és ajánlások
- Az áttekinthetőség érdekében érdemes minden csoportot saját modulba/fájlba mozgatni.
- Adjunk manifesztet vagy regisztert az elérhető lépésekhez és csoportjukhoz.
- Dokumentáljuk minden lépés kötelező/opcionális paramétereit.
- Docker/Kubernetes esetén szükség szerint adjunk új lépésmodulokat.

---

<!-- documentation-anchors:start -->
<a id="doc-plotstep-settings-injection-problem"></a>
<!-- documentation-anchors:end -->
## Plot-/lépésbeállítások injektálásának problémája
Néhány lépés olyan extra paramétereket/beállításokat igényel, amelyek nem egységesek minden lépésben. Ez megnehezíti a beállítások egységes injektálását.

<!-- documentation-anchors:start -->
<a id="doc-problem-statement"></a>
<!-- documentation-anchors:end -->
### A probléma leírása
- A lépések eltérő paramétereket várnak, egyesek `$GlobalSettings`, mások közvetlen paraméterek útján.
- A plotoknak (munkafolyamatoknak) egyedi beállításokat kellhet átadniuk a lépéseknek.

<!-- documentation-anchors:start -->
<a id="doc-solution-proposal-to-be-expanded-in-a-separate-document"></a>
<!-- documentation-anchors:end -->
### Megoldási javaslat (külön dokumentumban kibővítendő)
- Definiáljunk szabványos interfészt a lépésparaméterekhez (például az extra beállításokhoz mindig fogadjunk hashtable-t/objektumot).
- Dokumentáljuk minden lépés kötelező/opcionális beállításait.
- Beállításinjektálási segéddel szükség szerint fésüljük össze a plot-/lépés-/globális beállításokat.
- Érdemes `Step-Invoke` wrappert készíteni a paraméterleképezéshez és validációhoz.

Lásd még: `docs/plot-step-settings-injection.md` (létrehozandó)
