<!-- documentation-anchors:start -->
<a id="doc-plot-manager"></a>
<!-- documentation-anchors:end -->
# Plot Manager

<!-- documentation-navigation -->
[English](README.md) | [Magyar](README-hu.md) · [Dokumentáció](docs/README-hu.md) · [Projekt](README-hu.md)
<!-- /documentation-navigation -->

A Plot Manager kis, paraméterezett lépésekből állít össze szkriptelhető feladatokat. A plot a lépéshívásokat és bemeneteiket írja le. Az operátor csak a szükséges képességcsomagokat telepíti, könyvtáraikat a `src/Deployment/Scripts/Auto/` alá másolva.

A repó történelmi neve, **SenseNet-Project-Installer**, az első felhasználási esetét írja le. A SenseNet telepítése az egyik megőrzött régi munkafolyamat, nem a motor korlátozása.

Dokumentáció: [itt kezdd, válassz olvasási útvonalat](docs/management-guide-index-hu.md),
[teljes dokumentációs tartalomjegyzék](docs/README-hu.md), [komponensek és migráció](docs/migration-map-hu.md).

A [teljes GUI-kézikönyv](docs/management-user-guide-hu.md) minden oldalt,
gombot, nézetet és panelt elmagyaráz. A [négy demó katalógusa](docs/management-demo-projects-hu.md)
minden forgatókönyvet, plotot és lépést leír. A repó minden dokumentációs oldalának
van angol és magyar változata; a lap tetején lévő nyelvi hivatkozásokkal válthatsz.

<!-- documentation-anchors:start -->
<a id="doc-shared-management-application"></a>
<!-- documentation-anchors:end -->
## Közös kezelőalkalmazás

A React/TypeScript kezelőfelület helyi böngészőben, hitelesített szerveren vagy
a Windows/Linux Tauri asztali gazdaalkalmazásban fut. Hordozható projekteket,
explicit konfigurációs rétegeket, sorrendi plotokat, általános vezetett telepítőt
és a natív motor tartósan követett futásait kezeli. Lásd a [buildet, asztali csomagolást és telepítést](docs/management-deployment-hu.md),
a [felhasználói útmutatót](docs/management-user-guide-hu.md) és az [architektúrát](docs/management-architecture-hu.md).

A hordozható [SenseNet Docker projekt](examples/sensenet-docker/README-hu.md)
vezetett helyi telepítést, perzisztens SQL/repository adatokat, hitelesített
ellenőrzést, életciklus-parancsokat és ellenőrzött mentést/visszaállítást ad ugyanazzal a motorral.

<!-- documentation-anchors:start -->
<a id="doc-run-a-plot"></a>
<!-- documentation-anchors:end -->
## Plot futtatása

PowerShell 5.1 vagy PowerShell 7 szükséges. A motorhoz, a text és filesystem csomaghoz nem kell rendszergazdai jog vagy külső modul. Az IIS-lépések tényleges végrehajtásához Windows és WebAdministration kell.

A repó gyökeréből:

```powershell
# Discover the installed steps.
./src/Deployment/Scripts/Run.ps1 -Help steps

# Resolve and validate the example without executing steps.
./src/Deployment/Scripts/Run.ps1 compose-files -ConfigPath ./src/Deployment/Scripts/Examples/compose-files.json -Explain

# WorkDirectory must exist. This example creates greeting.txt and farewell.txt.
New-Item -ItemType Directory ./plot-output
./src/Deployment/Scripts/Run.ps1 compose-files -ConfigPath ./src/Deployment/Scripts/Examples/compose-files.json -WorkDirectory ./plot-output

# WhatIf skips every step, including steps that consume earlier results.
./src/Deployment/Scripts/Run.ps1 compose-files -ConfigPath ./src/Deployment/Scripts/Examples/compose-files.json -WhatIf
```

A példa kétszer hívja a `text.join` lépést eltérő bemenetekkel, majd kimeneteiket két `filesystem.write` hívásnak adja át. A meglévő fájlokat megtartja, hacsak nincs explicit `Overwrite: true` paraméter.

A CLI sikerkódja 0, validációs vagy végrehajtási hibánál 1. A végrehajtott futás JSON-ban adja vissza a futásazonosítót, a plot állapotát és minden végrehajtott lépés kimenetét, hibáját, időtartamát. A végrehajtás az első hibánál megáll.

<!-- documentation-anchors:start -->
<a id="doc-packages-and-configuration"></a>
<!-- documentation-anchors:end -->
## Csomagok és konfiguráció

- `Auto/<package>/package.psd1`: a csomag azonosítója, verziója, modulja, függőségei és exportált lépéssémái.
- `Auto/<package>/*.psm1`: elkülönített PowerShell-függvények. A csomag importálása csak függvényeket definiálhat és helyi állapotot inicializálhat.
- `Core/PlotManager.psm1`: felderítés, névütközések ellenőrzése, paraméterfeloldás és végrehajtás.
- `Examples/compose-files.json`: hordozható példa külön konfigurált lépéshívásokkal.
- `Run-Legacy.ps1` és `AutoExt/`: a megőrzött történelmi végrehajtási út.

Telepített natív csomagok: **text**, **filesystem**, **archive**, **json**, **xml**, **process**, **http**, **git**, **build**, **docker**, **iis**, **sqlserver**, **compose**, **web** (49 lépés). Lásd az [általános csomagkatalógust és teljes helyi példát](docs/generic-packages-hu.md). Másik Auto könyvtárba a teljes csomagmappát másold, modullal és erőforrásokkal együtt; ezt a `-AutoPath` választja ki. A hiányzó függőségeket és ismétlődő neveket a rendszer importálás előtt elutasítja. A kanonikus lépésazonosítók csomagnévvel minősítettek, például `filesystem.copy`. Ugyanaz a lépés külön invocation ID-kkel többször szerepelhet egy plotban.

Lásd a [konfigurációt és végrehajtást](docs/settings-hu.md), [csomagkészítést](docs/custom-steps-hu.md), [architektúrát és kompatibilitást](docs/plot-manager-runtime-hu.md), valamint a [tesztelést](tests/README-hu.md).

<!-- documentation-anchors:start -->
<a id="doc-layered-configuration"></a>
<!-- documentation-anchors:end -->
## Rétegzett konfiguráció

A default beállításokat a projekt örökli, majd a kiválasztott környezet felülírja. Az explicit futásparaméterek felülírják a feloldott lépéshívás-beállításokat.

```powershell
./src/Deployment/Scripts/Run.ps1 my-plot -DefaultConfigPath ./default.json -ConfigPath ./project.json -EnvironmentConfigPath ./environment.json
```

A rétegek opcionálisak. A beágyazott objektumok összeolvadnak, a tömbök lecserélődnek, az explicit null, false és nulla érték marad. A meglévő egyfájlos parancsok változatlanul működnek. A [rétegzett artefaktumpélda](docs/generic-packages-hu.md#doc-complete-local-example) valódi JSON/XML-, könyvtár-, ZIP- és hash-műveletekkel mutatja be a rétegeket.

<!-- documentation-anchors:start -->
<a id="doc-historical-workflows"></a>
<!-- documentation-anchors:end -->
## Történelmi munkafolyamatok

A meglévő szekciós/globális változós szkriptek külön PowerShell-folyamatban elérhetők:

```powershell
./src/Deployment/Scripts/Run.ps1 -Legacy -Help steps
./src/Deployment/Scripts/Run.ps1 -Legacy -Plot fullinstall -Settings local
```

Végrehajtás előtt nézd át a kiválasztott legacy konfigurációt: ezek a munkafolyamatok IIS-t, adatbázisokat és telepítéseket módosíthatnak. A kompatibilitási futtató megtartja platform-/eszközfeltételeiket és a végrehajtás rendszergazdai követelményét. A történelmi lépések nem natív csomagok, natív plotba nem keverhetők. A legacy előnézetet a rendszer elutasítja, mert ezek a szkriptek nem valósítják meg következetesen a WhatIf támogatást.

Használd az [SQL/IIS/Compose csomagokat és telepítési forgatókönyveket](docs/platform-packages-hu.md), valamint a [helyi Windows GUI / JSON integrációt](docs/local-integration-hu.md). Az Angular GUI és a kísérleti HTTP-listener történelmi kliens. A natív CLI/API nem függ tőlük. Az eredeti történelmi útmutatók a [docs/legacy](docs/README-hu.md#doc-historical-guides) részben találhatók.

<!-- documentation-anchors:start -->
<a id="doc-development"></a>
<!-- documentation-anchors:end -->
## Fejlesztés

```powershell
pwsh -NoProfile -File ./tests/Run-Tests.ps1
powershell.exe -NoProfile -File ./tests/Run-Tests.ps1
```

A tesztcsomag PowerShell/.NET és helyi Git segítségével ellenőrzi a konfigurációt, csomagizolációt, CLI-kilépési kódokat, ideiglenes fájlokat, gyermekfolyamatokat, loopback HTTP/TCP-t, valódi helyi Git-műveleteket és mockolt IIS/CLI-adaptereket. Telepített infrastruktúrán nem végez műveletet. [MIT-licenc](LICENSE).
