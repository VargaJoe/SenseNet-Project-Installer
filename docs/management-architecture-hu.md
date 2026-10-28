<!-- documentation-anchors:start -->
<a id="doc-shared-management-architecture"></a>
<!-- documentation-anchors:end -->
# A közös kezelőalkalmazás architektúrája

<!-- documentation-navigation -->
[English](management-architecture.md) | [Magyar](management-architecture-hu.md) · [Dokumentáció](README-hu.md) · [Projekt](../README-hu.md)
<!-- /documentation-navigation -->

A kezelőalkalmazás a meglévő natív PowerShell-motort veszi körül. A React/TypeScript kliens, az ASP.NET Core 8 szolgáltatás és a Tauri 2 asztali host közös originről kiszolgált webes felületet használ. Továbbra is a motor felel az objektumok összefésüléséért, a teljes tömbök lecseréléséért, a hivatkozások feloldásáért, a sémaellenőrzésért, az előzetes ellenőrzésért és a szekvenciális végrehajtásért. Nincs független JavaScript/C# konfigurációs motor.

<!-- documentation-anchors:start -->
<a id="doc-components-and-contracts"></a>
<!-- documentation-anchors:end -->
## Összetevők és szerződések

| Összetevő | Hely / felelősség |
| --- | --- |
| Natív CLI és végrehajtómotor | `src/Deployment/Scripts/Run.ps1`, `Core/PlotManager.psm1` |
| Megtartott JSON-híd / WinForms | `Core/PlotIntegration.psm1`, `Invoke-Request.ps1`, `Show-PlotRunner.ps1` |
| Felügyelt workerhíd | `Core/PlotManagement.psm1`, `Invoke-ManagedRequest.ps1` |
| Projekt- és futásszolgáltatás | `src/Management/Server/` |
| Közös böngészős és asztali UI | `src/Management/Web/` |
| Asztali szolgáltatás életciklusa | `src/Desktop/` |
| Reprodukálható build és indítás | `scripts/management/` |

Lásd az [API 1. protokollját](management-api-hu.md), a [telepítést](management-deployment-hu.md), a [felhasználói útmutatót](management-user-guide-hu.md) és a [migrációs térképet](migration-map-hu.md).

A worker explicit kérésfájlt olvas, és JSON-válaszfájlt ír. A lépésesemények bekövetkezésükkor külön, csak hozzáfűzhető NDJSON-fájlba kerülnek. A szabványos kimenet nem a szolgáltatásban futó naplók átviteli csatornája: a csomagok tetszőleges adatot írhatnak ki. A megtartott JSON-híd kompatibilis marad a korábbi hívóival.

<!-- documentation-anchors:start -->
<a id="doc-configuration-and-editing"></a>
<!-- documentation-anchors:end -->
## Konfiguráció és szerkesztés

A hordozható projektdefiníciók a projekthez képest relatívan hivatkoznak konfigurációs fájlokra. A géphez kötött tulajdonjog, tárológyökerek, workerútvonalak, identitás és hitelesítő adatok a szolgáltatás konfigurációjához tartoznak. A fájlok sorrendje: alap, projekt, majd a kiválasztott környezet; a hívásonkénti futási felülírások a legmagasabb prioritásúak. A motor beállítási prioritása változatlan: lépésséma-alapértékek, konfigurációs alapértékek, lépéskonfiguráció, szakasz, plotalapértékek, hívás, futási felülírások.

Csak a kiválasztott nyers réteg mentődik. Egy felülírás eltávolítása visszaállítja az öröklődést. A hiányzó érték, null, false, zero, üres tömbök és ismeretlen bővítő tulajdonságok megmaradnak. A mentéshez a szerkesztő által olvasott verzió szükséges. Az aktív futási zárolások és az optimista verzióellenőrzés elutasítják az ütköző módosításokat. A fájlok külső szerkesztése továbbra is megköveteli a szolgáltatás tárolási/hozzáférési konvencióinak betartását.

A vizsgálat visszaadja a tényleges konfigurációt, az eredeti rétegeket és minden levél forrásfájlját (egy teljes tömbnek egyetlen forrása van). A tervek a konvertált tényleges hívásparamétereket, azok motorbeli beállításrétegét, forrásfájlját/útvonalát és a beállítási/környezeti/kimeneti hivatkozások rekurzív eredetét adják vissza. A titkos értékek kitakartak; a hivatkozásnevek láthatók maradnak.

<!-- documentation-anchors:start -->
<a id="doc-execution-and-durability"></a>
<!-- documentation-anchors:end -->
## Végrehajtás és tartósság

Minden futás az első lépés meghívása előtt teljes statikus plotellenőrzést végez. A WhatIf ugyanazt a tervet használja, és Skipped lépéseket bocsát ki; nem hív lépésfüggvényeket és nem teszteli szolgáltatáskapcsolataikat. Aktív kapcsolatteszt csak egy készenléti lépés explicit futtatásával végezhető. Egy egyedi hívás ugyanazt a teljes plotra kiterjedő előzetes ellenőrzést használja, és elutasításra kerül, ha feloldott bemeneteihez korábbi kimenetek szükségesek. Az előfeltételek soha nem futnak implicit módon.

A szolgáltatás a klienskapcsolatoktól függetlenül birtokolja a workerfolyamatokat és a tartós futási állapotot. Végrehajtás előtt pillanatképet készít a rendezett konfigurációról és a natív csomag-/core-fájlokról, és rögzíti a hash-eiket. Az élő események kurzor alapján visszajátszhatók; az egyetlen szolgáltatáshoston futó végrehajtóhoz elegendő egy tartós csatorna lekérdezése. Újraindítás utáni helyreállításkor a befejezetlen futások Interrupted állapotot kapnak a hatások megismétlése helyett.

A Cancel leállítja a saját workerfolyamat teljes fáját. Nem kompenzálja a befejezett lépéseket, nem állít helyre fájlokat és nem von vissza adatbázis-/konténerműveleteket. A már elküldött külső művelet a kliensfolyamat megszűnése után is folytatódhat. Az alkalmazás leállítása és a szolgáltatáshost hibája különbözik egy böngészőlap bezárásától.

<!-- documentation-anchors:start -->
<a id="doc-execution-boundary"></a>
<!-- documentation-anchors:end -->
## A végrehajtás határa

Az 1. protokoll egyetlen futtatót, annak operációs rendszerét, futási identitását és célját azonosítja. Helyi böngészős és asztali módban a végrehajtás a helyi szolgáltatáshoston történik; hostolt módban a szerveren, a beállított identitással. A kizárólag windowsos csomagok továbbra is kizárólag Windowson használhatók. A szükséges telepített végrehajthatókat a jegyzékfájl-katalógus mutatja; puszta jelenlétük nem bizonyít hitelesítést vagy készenlétet.

Egy hitelesített üzemeltető a szolgáltatás identitásával hajthatja végre a telepített csomagokat, a process.run lépést is beleértve. A projekttulajdonos-ellenőrzések hozzáférés-szabályozások, nem operációsrendszer-szintű sandboxok egymásban nem bízó szkriptkészítők között. A szolgáltatás felesleges jogosultságok nélkül fusson, a tárolója legyen korlátozott, és eltérő bizalmi határokhoz külön szolgáltatáspéldányok tartozzanak. Nincs implicit jogosultságnövelés.

A további gépeken történő távoli végrehajtás későbbi feladat: verziózott futtatóinterfészt és kifelé irányuló, hitelesített agentkapcsolatot használjon. A hostolt böngészők soha nem érnek el tetszőleges localhost-szolgáltatásokat. Ez az átadás nem állít távoli agentflotta-, elágazás-, párhuzamoslépés-, újrapróbálás- vagy automatikus visszaállítás-támogatást.

A GUI/API TLS-e és az üzemeltető hitelesítése, egy lépés célrendszerének TLS-/kliensidentitása, valamint a telepített alkalmazás tanúsítványai külön beállítások a saját gépeiken. Konfigurálásukat a telepítési dokumentáció ismerteti.
