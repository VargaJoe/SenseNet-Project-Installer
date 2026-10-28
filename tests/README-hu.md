<!-- documentation-anchors:start -->
<a id="doc-runtime-regression-tests"></a>
<!-- documentation-anchors:end -->
# A futtatókörnyezet regressziós tesztjei

<!-- documentation-navigation -->
[English](README.md) | [Magyar](README-hu.md) · [Dokumentáció](../docs/README-hu.md) · [Projekt](../README-hu.md)
<!-- /documentation-navigation -->

A kétnyelvű dokumentáció egyezésének és a relatív hivatkozásoknak a független ellenőrzéséhez futtasd a `node ./scripts/management/Test-Documentation.mjs` parancsot.

A közös asztali/böngészős alkalmazás [management tesztkörnyezetet](../docs/management-deployment-hu.md#doc-tests-and-evidence) és [kézi átvételi útmutatót](../docs/management-acceptance-hu.md) ad hozzá. A dokumentált .NET/Node/Playwright előfeltételek telepítése után PowerShell 7 alatt futtasd a `./scripts/management/Test-Management.ps1` parancsot. Valódi elkülönített PowerShell workereket és helyi szolgáltatáshoz kapcsolódó valódi böngészőt használ. A natív WebView-végrehajtás és a Windows NSIS / Ubuntu .deb build külön ellenőrzés. A repository munkafolyamatai csak kézzel indíthatók; az átadás tényleges helyi eredményeit az [ellenőrzési jegyzőkönyv](../docs/management-validation-hu.md) rögzíti.

A backend tesztcsomag azt a windowsos állapotkönyvtár-tulajdonjogot is reprodukálja, amely Modify jogosultsággal, de WRITE_OWNER nélkül rendelkezik, majd ellenőrzi a privát ACL-eket, az újraindítást és a gyermekfájlok öröklését. Ezt a célzott regressziót a `dotnet run --project tests/Management.Server.Tests -- --permissions-only` paranccsal futtasd; a teljes tesztcsomag automatikusan tartalmazza. Linuxon explicit kihagyást jelent.
A windowsos backend tesztcsomag egy valódi katalógusworkerhez verbatim helyi meghajtós motorútvonalat is használ. A `--engine-path-only` ezt a célzott regressziót futtatja; a szolgáltatásnak a PowerShell végrehajtási házirend módosítása nélkül kell normalizálnia az útvonalat.

A kizárólag windowsos IIS/legacy/junction tesztek Linuxon explicit kihagyásként jelennek meg; a nem támogatott IIS-forgatókönyv előzetes ellenőrzését ott is ellenőrzi. Egy sikeres windowsos pwsh-futás nem helyettesít Linux-végrehajtási bizonyítékot.

A repository gyökeréből futtasd:

```powershell
pwsh -NoProfile -File ./tests/Run-Tests.ps1
powershell.exe -NoProfile -File ./tests/Run-Tests.ps1
```

Nem szükséges Pester-telepítés vagy élő infrastruktúra. A tesztcsomag újonnan létrehozott ideiglenes könyvtárban valódi fájlokat és helyettesített IIS-parancsokat használ. Ellenőrzi a csomagválasztást, a modulelkülönítést, az importálás előtti ütközéseket, a konfiguráció rétegeit/másolatait/hivatkozásait, a mellékhatások előtti előzetes ellenőrzést, a hiba miatti megállást, a WhatIf működését és a CLI kilépési kódjait.

A tesztcsomag csak a saját véletlenszerű nevű tesztkönyvtárát törli, annak abszolút útvonala ellenőrzése után. A teszthibák 1-es kilépést eredményeznek. A natív csomagfüggvényeket és a CLI-t egyaránt teszteli; a parserellenőrzések a megtartott legacy szkripteket is tartalmazzák. Élő IIS/SQL/Docker és a történeti GUI nem szerepel a futtatásban.

A futtató a Configuration.Tests.ps1 és GenericPackages.Tests.ps1 fájlokat is tartalmazza. Ezek lefedik a rendezett alap-/projekt-/környezeti fájlokat, a valódi CLI-felülírásokat, a hiányzó/érvénytelen fájlokat, a literális fájlrendszerútvonalakat, a korlátozott hatókörű törlést, a ZIP oda-vissza műveleteket és érvénytelen bejegyzéseket, a JSON-objektumok összefésülését, az XML-névtér-/attribútumfrissítéseket, a független csomagtelepítést, a közvetlen WhatIf működését és a mellékelt réteges csomagpéldát. A windowsos futások ideiglenes junctiont is létrehoznak és eltávolítanak a linkelutasítás ellenőrzéséhez. Nincsenek élő szolgáltatások vagy külső letöltések.

<!-- documentation-anchors:start -->
<a id="doc-operational-packages"></a>
<!-- documentation-anchors:end -->
## Üzemeltetési csomagok

Az `Operations.Tests.ps1` automatikusan fut a fő tesztcsomagban. A PATH-on elérhető Git szükséges; a HTTP-tesztek az Add-Type használatával fordítják a kis `HttpFixture.cs` loopback tesztkörnyezetet, és ideiglenes portot használnak. Internetes végpontokra, Docker daemonra vagy adatbázisra nincs szükség.

A lefedettség tartalmazza az ISO-karakterláncok megtartását (JSON/config/CLI), az üres CLI-réteg elutasítását, a pontos folyamatargumentum-határokat, az stdout/stderr párhuzamos kiolvasását, a kilépési hibákat és időtúllépéseket, a csak gyermekfolyamatra érvényes környezetet, az ellenőrzőösszeges/atomi letöltéseket, a méretkorlátokat, átirányításokat, újrapróbálásokat, lassúválasz-határidőket, TCP-elérhetőséget, valódi Git clone/fetch/checkout műveleteket és a módosított munkafa elutasítását. A Build/NuGet és Docker parancsok felépítését process-függőséget helyettesítő tesztkörnyezet ellenőrzi; valódi SDK-/daemonviselkedésük a telepített eszközöktől függ. A közvetlen adapteres WhatIf is le van fedve.

<!-- documentation-anchors:start -->
<a id="doc-recursive-settings-references"></a>
<!-- documentation-anchors:end -->
## Rekurzív beállításhivatkozások

A `References.Tests.ps1` tényleges réteges CLI-fájlokon keresztül ellenőrzi a közvetett környezeti értékeket, a beágyazott leképezések/tömbök kibontását bemenetmódosítás nélkül, az ismételt testvérhivatkozásokat, a null/false/zero értékeket, a 64 hivatkozásos láncot és mélységkorlátját, az ön-/kölcsönös-/objektumciklusokat, a hiányzó értékeket és a korábbi mellékhatások előtti típushibákat. Ellenőrzi továbbá a korábbi kimenetek kis- és nagybetűtől független aliasait, az előre/önmagára mutató kimenetek elutasítását, a hiányzó futásidejű kimeneti tulajdonságokat és a lépés által visszaadott literális, direktíva alakú adatokat.

<!-- documentation-anchors:start -->
<a id="doc-platform-and-local-integration"></a>
<!-- documentation-anchors:end -->
## Platform és helyi integráció

A Platform.Tests.ps1 a fő tesztcsomagban fut: paraméterezett SQL-/providerszerződések és hibatisztítás, azonosító-/útvonal-idézés, visszaállítási leképezések, felhasználói szerepkörök, korlátos készenlét, közvetlen WhatIf, Compose-argumentumsorrend/-hatókör, IIS-létrehozás/-állapot/-újraindítás tesztkörnyezetei, valódi karbantartási fájlok, hiba utáni helyreállítás és a helyi JSON-híd (catalog/plan/preview/run). Az SQL/IIS providereket itt helyettesítők adják, kivéve a valódi zárt portos SQL-időtúllépési ellenőrzést. Futó szolgáltatás nem szükséges.

Külön bekapcsolható valódi SQL Server / Docker Compose teszt:

```powershell
pwsh -NoProfile -File ./tests/Run-PlatformIntegration.ps1 -RunDocker
powershell.exe -NoProfile -File ./tests/Run-PlatformIntegration.ps1 -RunDocker
```

Docker Compose és helyben meglévő `mcr.microsoft.com/mssql/server:2022-latest` image (vagy -SqlImage) szükséges. Az explicit kapcsoló eldobható SQL Server Developer konténert engedélyez ACCEPT_EULA=Y értékkel. Egyedi Compose-projektet hoz létre, csak ideiglenes loopback portot köt, véletlen jelszót ad át kizárólag a gyermekfolyamat környezetében, és soha nem tölt le image-et vagy csatol meglévő adatot. Ellenőrzi az adatbázis létrehozását, a paraméterezett több eredményhalmazos lekérdezéseket, NULL-okat, fájlméretezést, bejelentkezéseket/felhasználókat, mentést, FILELISTONLY leképezéses visszaállítást és a visszaállított tartalom ellenőrzését, törlést és a Compose életciklusát. Végül csak ezt a Compose-projektet távolítja el a tesztköteteivel és ellenőrzött ideiglenes könyvtárával együtt. Az SQL Server Linux megfelelő Docker-memóriát és indulási időt igényel.

A Windows Forms UI kézi átvételi eljárása a [helyi integrációban](../docs/local-integration-hu.md) található. A valódi IIS-létrehozást eldobható Windows IIS-gépen, WebAdministration használatával kell ellenőrizni; az alapértelmezett tesztcsomag a parancs-/állapotszerződéseit ellenőrzi helyi IIS-módosítás nélkül.

Rejtett GUI-híd smoke teszt Windowson: `pwsh -NoProfile -File ./tests/Run-GuiSmoke.ps1` (powershell.exe is használható). Példányosítja a valódi vezérlőket, STA gyermekfolyamattal végigvezeti a catalog/preview/run műveleteket, feldolgozza a UI-eseményeket, és ellenőrzi a valódi fájlkimenetet ablak megjelenítése nélkül. Nem vizsgálja a vizuális elrendezést, akadálymentességet vagy valódi IIS-t.

<!-- documentation-anchors:start -->
<a id="doc-sensenet-docker-project"></a>
<!-- documentation-anchors:end -->
## SenseNet Docker projekt

A `pwsh -NoProfile -File ./tests/Run-SenseNetExample.ps1` ellenőrzi a hordozható példa 13 natív plotját és a licencelutasítást Docker-hívás nélkül. Ehhez az alkalmazásspecifikus példához PowerShell 7.2 vagy újabb szükséges.

A valódi SenseNet SQL/IdentityServer életciklusteszthez add hozzá a `-RunDocker` kapcsolót. Ez explicit elfogadja az SQL Server Developer licencét egy eldobható fejlesztői tesztkörnyezethez, a példa rögzített publikus image-eit használja (a Docker a hiányzó image-eket letöltheti), és egyedi `pm-sensenet-test-*` névteret foglal két loopback porttal. Ellenőrzi a PKCE adminbejelentkezést, a valódi tartalomlétrehozást és a tartalomazonosító megmaradását stop/start és konténer-újralétrehozás után. A mentésnek/visszaállításnak mind az SQL-ben, mind az App_Data-ban le kell cserélnie a módosított jelölőket; a meg nem erősített visszaállításnak változatlanul kell hagynia őket. Végül ellenőrzi a tulajdonosi címkéket, mielőtt csak a saját konténereit, köteteit, hálózatát és privát runtime-fájljait törli. A megtisztított bizonyíték az `artifacts/sensenet-example-tests/<fixture>/acceptance-evidence.json` alatt marad meg.
