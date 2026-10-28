<!-- documentation-anchors:start -->
<a id="doc-plot-manager-complete-guide-to-the-four-demo-projects"></a>
<!-- documentation-anchors:end -->
# Plot Manager: a négy demóprojekt teljes használati útmutatója

<!-- documentation-navigation -->
[English](management-demo-projects.md) | [Magyar](management-demo-projects-hu.md) · [Dokumentáció](README-hu.md) · [Projekt](../README-hu.md)
<!-- /documentation-navigation -->

Ez a katalógus a telepített alkalmazásban megnyitható négy projektet magyarázza:
mit állítanak elő, melyik plotot mikor válaszd, és mit végez minden lépés.
A forráslinkek a GitHubon is olvashatók; a megértéshez nem kell futó alkalmazás.
A képernyők és kezelőszervek részletes leírása a
[magyar GUI-kézikönyvben](management-user-guide-hu.md) található.

<!-- documentation-anchors:start -->
<a id="doc-contents-and-suggested-order"></a>
<!-- documentation-anchors:end -->
## Tartalom és javasolt sorrend

| Projekt az alkalmazásban | Mit tanít? | Plotok | Külső feltétel |
| --- | --- | --- | --- |
| [01 – Vezetett fájltelepítő](#demo-01) | Wizard → normál beállítás → kétlépéses futás → fájl; korábbi lépés outputjának átadása. | `install` | Nincs. |
| [02 – Rétegek, típusok és hivatkozások](#demo-02) | Default/projekt/environment felülírások, öröklés, `false`, `0`, `null`, `[]`; hibás sorrend felismerése. | `show-settings`, `hibas-sorrend` | Nincs. |
| [03 – JSON, XML és ZIP csomagolás](#demo-03) | Kilenc lépésből álló helyi csomagolás és visszaolvasás; development/production eredmény. | `package` | Nincs. |
| [04 – SenseNet Docker telepítés és menedzsment](#demo-04) | SQL + repository + IdentityServer telepítés, ellenőrzés, tartalom, napi kezelés, mentés/visszaállítás. | 13 plot, lent mind felsorolva. | Docker Linux-konténerekkel, Compose v2, PowerShell 7.2+. |

Az első három projekt forrása az [examples/management-demos](../examples/management-demos/README-hu.md)
könyvtárban van, csak a bemenetekkel. A negyediké az
[examples/sensenet-docker](../examples/sensenet-docker/README-hu.md) könyvtárban.
A futtatás eredményei és titkai nem részei ezeknek a GitHub-mappáknak.

<!-- documentation-anchors:start -->
<a id="doc-how-to-read-the-demos"></a>
<!-- documentation-anchors:end -->
## Hogyan olvasd a demókat?

**Projekt** = hordozható mappa. A `plot-project.json` adja a nevet, a rétegfájlok
elérési útját, az environmenteket és az opcionális wizardot. A **plot** névvel
ellátott, sorrendben végrehajtott lépéssor. Egy sor **invocation ID**-je a ploton
belüli név (`save`); a **Step** a telepített művelet (`filesystem.write`).
Ugyanaz a Step több különböző ID-val és paraméterezéssel is szerepelhet.

Minden demó ezt a rétegezést használja:

```text
default.json → project.json → environments/<kiválasztott environment>.json
```

A későbbi objektummező felülírja az előzőt; az objektumok mezőnként összeolvadnak,
a tömbök egészükben lecserélődnek. A hiányzó mező örököl, az explicit `null`,
`false`, `0`, `[]` tényleges érték. A `Configuration` nyers szerkesztője mindig a
kiválasztott réteget módosítja; az effektív nézet a feloldott összeredmény.

| Amit a JSON-ban látsz | Jelentés |
| --- | --- |
| `{"$ref":"settings.Sample.Message"}` | A rétegekből összeállított beállítás értéke. |
| `{"$ref":"steps.compose.Output.Text"}` | Az **ugyanabban a futásban korábban** lefutott `compose` lépés kimenete. |
| `{"$env":"PLOTMANAGER_SECRET_SENSENET_ADMIN_PASSWORD"}` | A futtató környezeti változója; a GUI-ban Runner secret adhatja. |
| `With` | Az adott invocation paraméterei. |
| `StepDefaults` | Ugyanahhoz a natív Stephez tartozó közös paraméterek; az invocation `With` tovább pontosíthatja. |

**Minden útvonal a szolgáltatás gépére vonatkozik.** A relatív kimenetek a projekt
munkakönyvtárában keletkeznek. Hostolt GUI esetén ez a szerver, nem a böngésző
saját gépe. A desktop és browser külön adattárába felvett másolatok egymástól
függetlenek. A korábbi futások outputja látható a történetben, de nem használható
egy új single-step futás korábbi outputjaként.

**Közös GUI-menetrend:** nyisd meg a projektet, válassz environmentet, a `Plot editor`
oldalon válaszd ki a plotot. Mentsd az esetleges módosítást (`Save layer`, vagy a
mentetlen változás jelzésében `Save selected layer`),
majd `Preflight plot` → `WhatIf preview` → `Run plot`. A `Run history` mutatja az
állapotot, lépéseket, strukturált kimeneteket és a futás azonosítóját.
A preflight és a WhatIf statikus: nem írja meg a fájlt, nem indít Docker stack-et,
nem igazolja a jelszót, portfoglalást vagy a külső szolgáltatás készenlétét.
A valódi futás is teljes preflighttal kezdődik; a lépések végrehajtása ezt követi.

<a id="demo-01"></a>
<!-- documentation-anchors:start -->
<a id="doc-01--guided-file-installer"></a>
<!-- documentation-anchors:end -->
## 01 – Vezetett fájltelepítő

Forrás: [projektleíró és wizard](../examples/management-demos/01-vezetett-telepito/plot-project.json),
[default és lépések](../examples/management-demos/01-vezetett-telepito/default.json),
[projektértékek](../examples/management-demos/01-vezetett-telepito/project.json),
[development](../examples/management-demos/01-vezetett-telepito/environments/development.json).

<!-- documentation-anchors:start -->
<a id="doc-what-do-you-see-and-what-is-the-result"></a>
<!-- documentation-anchors:end -->
### Mit látsz és mi az eredmény?

Ez egy kicsi, valódi fájlíró telepítő. Az `install` egyetlen üzenetet állít össze,
majd UTF-8 fájlba menti. Nincs letöltés, szolgáltatás vagy rendszerszintű telepítés.
A default `hello.txt` / `Hello from Plot Manager` értékeit a projekt felülírja
`udvozlet.txt` / `Szia a Plot Manager demóból!` értékekre. A development réteg üres,
így nem változtat rajtuk. Más előre definiált environment itt nincs.

<!-- documentation-anchors:start -->
<a id="doc-every-step-in-install"></a>
<!-- documentation-anchors:end -->
### Az `install` összes lépése

| Sorrend / ID | Natív Step | Bemenet és tevékenység | Output és függőség |
| --- | --- | --- | --- |
| 1. `compose` | `text.join` | `Items` = egyetlen elem, `settings.Sample.Message`; `Separator` = üres szöveg. Összefűzi az üzenetet. A név itt szövegösszeállítást jelent, nincs Docker Compose. | `Output.Text` = a teljes üzenet. Önállóan is futtatható. |
| 2. `save` | `filesystem.write` | `Path` = `settings.Sample.Target`; `Content` = `steps.compose.Output.Text`; `Overwrite:true`. Megírja vagy felülírja a célfájlt. | `Output.Path`, `Output.Bytes`. A jelen futás `compose` outputját igényli. |

<!-- documentation-anchors:start -->
<a id="doc-a-first-guided-installation"></a>
<!-- documentation-anchors:end -->
### A: első vezetett telepítés

1. Nyisd meg a projektet és a `Guided setup` oldalt.
2. `Target`: ellenőrizd a futtató gépet; a **Fájlnév a projektben** mezőbe például
   `udvozlet.txt` kerüljön. Használj egyszerű fájlnevet; a példában nincs mappalétrehozó lépés.
3. `Continue to settings →`: az **Üzenet** mezőben add meg a kívánt tartalmat.
4. `Save answers →`: a wizard a `project.json` `Sample.Target` és `Sample.Message`
   mezőjét menti. Nem indítja el a telepítést.
5. `Run static preflight` → tekintsd át a két lépést → `Continue to run →` →
   `Run sample installation`.
6. A `Result`/`Run history` eredményében mindkét lépés sikeres. A projektmappában
   ott a célfájl, a megadott üzenettel; a `save` outputjában az elérési út és bájtszám.

<!-- documentation-anchors:start -->
<a id="doc-b-understanding-a-single-step-and-its-dependency"></a>
<!-- documentation-anchors:end -->
### B: egyetlen lépés és a függőség megértése

1. A `Plot editor` oldalon válaszd az `install` plotot, majd a `compose` sort.
2. `Preflight invocation`, majd `Run invocation`: csak a szöveg áll elő, fájl nem.
3. Válaszd a `save` sort, majd `Preflight invocation`: a rendszer elutasítja,
   mert önálló futásban nincs előző `compose` output. Ez akkor is igaz, ha a
   teljes plot korábban sikerült vagy a célfájl már létezik.
4. Az üzenet mentéséhez ismét `Run plot` kell.

**Újrafuttatás:** ugyanazt a fájlt az új tartalom felülírja. A fájlnév átírása új
fájlt hoz létre; a régi célfájl megmarad. **Visszavonás:** a saját létrehozott
fájljaid kézi törlése; a plotnak nincs rollback vagy cleanup lépése. A wizardban
mentett beállításokat külön vissza kell állítani, ha az eredeti példát szeretnéd.

<a id="demo-02"></a>
<!-- documentation-anchors:start -->
<a id="doc-02--layers-types-and-references"></a>
<!-- documentation-anchors:end -->
## 02 – Rétegek, típusok és hivatkozások

Forrás: [projektleíró](../examples/management-demos/02-retegek-es-hivatkozasok/plot-project.json),
[default és mindkét plot](../examples/management-demos/02-retegek-es-hivatkozasok/default.json),
[projekt](../examples/management-demos/02-retegek-es-hivatkozasok/project.json),
[development](../examples/management-demos/02-retegek-es-hivatkozasok/environments/development.json),
[production](../examples/management-demos/02-retegek-es-hivatkozasok/environments/production.json).

<!-- documentation-anchors:start -->
<a id="doc-what-do-you-see-and-what-is-the-result-1"></a>
<!-- documentation-anchors:end -->
### Mit látsz és mi az eredmény?

A `show-settings` a feloldott `Demo` objektumot kiírja `settings-result.json`
néven, majd visszaolvassa. Így az effektív konfigurációt a valódi fájl és a
`read.Output.Value` mellett is összehasonlíthatod. Itt nincs wizard: a tananyag
a `Configuration`, az environmentváltó, a `Plot editor` és a preflight használata.

<!-- documentation-anchors:start -->
<a id="doc-actual-results-for-the-two-environments"></a>
<!-- documentation-anchors:end -->
### A két environment tényleges eredménye

| `Demo` mező | Default → projekt | development eredmény | production eredmény |
| --- | --- | --- | --- |
| `Target` | default: `settings-result.json` | `settings-result.json` | `settings-result.json` |
| `Message` | `Alapértelmezett üzenet` → `Projektből érkező üzenet` | `Projektből érkező üzenet` | `Projektből érkező üzenet` |
| `Scope` | `default` → `project` | `development` | `production` |
| `Enabled` | default: `true` | `false` | `true` |
| `Attempts` | default: `3` | `0` | `2` |
| `Optional` | default: `örökölt érték` | `null` | `örökölt érték` (a production nem adja meg) |
| `Items` | default: `["egy","kettő"]` | `[]` | `["release"]` |
| `Nested.DefaultOnly` | default: `megmarad` | `megmarad` | `megmarad` |
| `Nested.ProjectOnly` | projekt: `hozzáadva` | `hozzáadva` | `hozzáadva` |
| `Nested.Switched` | `default` → `project` | `development` | `production` |

A `VendorMetadata.UnknownFeature.Preserve:true` és
`VendorMetadata.FutureInteger:9007199254740993` is benne van a default rétegben.
Ezek nem a `Demo` részei, így az exportált fájlban nem szerepelnek. A nyers
konfiguráció és a veszteségmentes szerkesztés szemléltetésére szolgálnak: az
ismeretlen mezőt és a JavaScript biztonságos egész tartományán túli számot is
meg kell őrizni. Ne kerekítsd át kézzel a számot.

<!-- documentation-anchors:start -->
<a id="doc-every-invocation-in-both-plots"></a>
<!-- documentation-anchors:end -->
### Minden invocation mindkét plotban

| Plot / sorrend | ID / natív Step | Bemenet és művelet | Eredmény |
| --- | --- | --- | --- |
| `show-settings` 1. | `export` / `json.write` | `Path=settings.Demo.Target`, `Value=settings.Demo`, `Overwrite:true`. | A teljes feloldott Demo objektum fájlba kerül; `Output.Path`. |
| `show-settings` 2. | `read` / `json.read` | `Path=steps.export.Output.Path`. | Az előbb írt fájl objektuma `Output.Value` alatt; a sorrend helyes. |
| `hibas-sorrend` 1. | `read` / `json.read` | Ugyanaz a `steps.export.Output.Path`, de az `export` csak ezután állna elő. | A **teljes plot preflightja elutasítja**, még a fájlolvasás előtt. |
| `hibas-sorrend` 2. | `export` / `json.write` | Ugyanazok a paraméterek, mint a jó plotban. | Nem hajtódik végre, mert az előrefelé mutató outputhivatkozás hibás. |

<!-- documentation-anchors:start -->
<a id="doc-a-comparing-development-and-production"></a>
<!-- documentation-anchors:end -->
### A: development és production összehasonlítása

1. Válaszd a `development` environmentet és a `Configuration` oldalt.
2. Nézd meg egymás után a default, project és development réteget, majd az
   effektív konfigurációt és provenance-t. Vesd össze a fenti táblázattal.
3. `Plot editor` → `show-settings` → `Preflight plot` → `Run plot`.
4. `Run history` → `read` output: látszódjon `false`, `0`, `null`, üres tömb és
   a két örökölt `Nested` mező. A `settings-result.json` ugyanezt tartalmazza.
5. Válts `production` environmentre, majd ismét teljes futás. A fájl lecserélődik
   a production értékeire; az előző development futás outputja a történetben megmarad.

<!-- documentation-anchors:start -->
<a id="doc-b-trying-inheritance-and-the-deliberate-error"></a>
<!-- documentation-anchors:end -->
### B: az öröklés és a szándékos hiba kipróbálása

1. A `Configuration` oldalon kifejezetten a development rétegben távolítsd el
   a `Demo.Attempts` felülírást, ments, és nézd meg az effektív értéket: `3`.
   A `null` beírása nem eltávolítás; az másik explicit érték lenne.
2. Állítsd vissza az eredeti `Attempts:0` értéket és ments.
3. `Plot editor` → `hibas-sorrend` → `Preflight plot`. Elvárt eredmény a sorrendi hiba,
   nem egy sikeres fájlírás. A `Run plot` is a végrehajtás előtt elakadna ezen.
4. Visszatéréshez válaszd a `show-settings` plotot. A tanpélda javításához a
   `read` elé kell kerülni az `export` sornak; a jó plot eleve ezt mutatja.

**Single step:** az `export` külön futtatható, ha a szükséges settings érvényes.
A `read` külön futtatása hiányzó korábbi output miatt elutasított. **Újrafuttatás:**
`settings-result.json` minden alkalommal felülíródik. **Takarítás:** csak ezt a
saját eredményfájlt töröld; a konfigurációs kísérleteket külön állítsd vissza.

<a id="demo-03"></a>
<!-- documentation-anchors:start -->
<a id="doc-03--json-xml-and-zip-packaging"></a>
<!-- documentation-anchors:end -->
## 03 – JSON, XML és ZIP csomagolás

Forrás: [projektleíró](../examples/management-demos/03-json-xml-zip/plot-project.json),
[default és teljes pipeline](../examples/management-demos/03-json-xml-zip/default.json),
[projekt](../examples/management-demos/03-json-xml-zip/project.json),
[development](../examples/management-demos/03-json-xml-zip/environments/development.json),
[production](../examples/management-demos/03-json-xml-zip/environments/production.json).

<!-- documentation-anchors:start -->
<a id="doc-what-do-you-see-and-what-is-the-result-2"></a>
<!-- documentation-anchors:end -->
### Mit látsz és mi az eredmény?

Egyetlen `package` plot épít helyi csomagot. Nem fordít alkalmazást, nem használ
Dockert és nem tölti fel sehová. A sorrend, a különböző fájlformátumok és a
lépésoutputok együttműködése a tananyag. Wizard ehhez a projekthez sincs.

| Sorrend / ID | Natív Step | Paraméterek és a lépés szerepe | Eredmény / függőség |
| --- | --- | --- | --- |
| 1. `directory` | `filesystem.mkdir` | `Path:"build"`; létrehozza a mappát, ha hiányzik. | `Output.Path`, `Created`; a következő fájlok szülőmappája. |
| 2. `template` | `filesystem.write` | `build/app.template.xml`, literal XML-sablon, `Overwrite:true`. A kezdeti Environment érték `unset`. | Az XML forrásfájl elkészül. |
| 3. `configure` | `xml.set` | `Source:"build/app.template.xml"`, `Destination:"build/app.config"`, `XPath:"/configuration/appSettings/add/@value"`, `Value=settings.Release.Environment`, `Overwrite:true`. | Az XML attribútumot a választott environmentre állítja; a sablon változatlan marad. |
| 4. `manifest` | `json.write` | `Path:"build/manifest.json"`, `Value=settings.Release.Manifest`, `Overwrite:true`. | A feloldott manifest JSON-fájl. Az `Environment` benne is `settings.Release.Environment` hivatkozás. |
| 5. `readme` | `filesystem.write` | `Path:"build/README.txt"`, `Content=settings.Release.Readme`, `Overwrite:true`. | Rövid magyar leírás a csomagban. |
| 6. `pack` | `archive.pack` | `Source:"build"`, `Destination:"demo-bundle.zip"`, `Overwrite:true`. | A build mappa ZIP-be kerül. `Output.Path`, `Files`, `Bytes`. |
| 7. `unpack` | `archive.unpack` | `Source=steps.pack.Output.Path`, `Destination:"expanded"`, `Overwrite:true`. | A ZIP tartalma az expanded mappában, bejegyzések és célútvonalak ellenőrzésével. A `pack` korábbi outputját igényli. |
| 8. `checksum` | `filesystem.hash` | `Path=steps.pack.Output.Path`. | `Output.Algorithm:"SHA256"`, `Output.Hash`; a kész ZIP ellenőrzőösszege. A `pack` outputját igényli. |
| 9. `verify` | `json.read` | `Path:"expanded/manifest.json"`. | A kibontott manifest `Output.Value` értéke visszaolvasható; a fájlnak már léteznie kell. |

Tiszta projektből a következő eredmény várható:

```text
build/
  app.template.xml   # Environment="unset"
  app.config         # Environment="development" vagy "production"
  manifest.json
  README.txt
demo-bundle.zip      # a build négy fájlja
expanded/
  app.template.xml
  app.config
  manifest.json
  README.txt
```

A manifest közös értékei: `Application:"Demo artifact pipeline"` (project
felülírás), `Attempts:0`, `Optional:null`, `Enabled:false`. Developmentben
`Environment:"development"`, `Features:["debug","local"]`; productionben
`Environment:"production"`, `Features:["release"]`. A README közös:
`Ez egy általános, helyi Plot Manager demócsomag.`

<!-- documentation-anchors:start -->
<a id="doc-a-building-and-inspecting-a-package"></a>
<!-- documentation-anchors:end -->
### A: csomag építése és megvizsgálása

1. `development` environment → `Plot editor` → `package`.
2. `Preflight plot`: kilenc sor, a `pack → unpack` és `pack → checksum`
   outputfüggőségekkel. `WhatIf preview` után még nincs új fájl.
3. `Run plot`, majd `Run history`: mind a kilenc lépés sikeres legyen.
4. Nézd meg a `checksum.Output.Hash` értékét és a `verify.Output.Value` manifestet.
   A fájlokat a szolgáltatás projektmappájában vagy a ZIP-et megnyitva is ellenőrizheted.
5. Válts `production` environmentre, futtasd újra. Az XML és a manifest most
   productiont, a feature tömb csak `release` értéket tartalmazzon.

<!-- documentation-anchors:start -->
<a id="doc-b-why-does-a-single-steps-prior-state-matter"></a>
<!-- documentation-anchors:end -->
### B: miért számít az egyedi lépés előzménye?

A `directory` önállóan biztonságosan létrehozza a mappát. A `template`,
`configure`, `manifest`, `readme`, `pack`, `verify` paramétereiben nincs korábbi
outputhivatkozás, ezért statikusan választhatók single stepként; tényleges sikerük
az adott mappák/fájlok meglététől is függ. Például a `verify` csak egy már létező
`expanded/manifest.json` fájlt olvas, akár egy régebbi futásét. Ezzel szemben az
`unpack` és a `checksum` single-step preflightja elutasított a `pack` output
hiánya miatt. A teljes csomagépítéshez a teljes plotot használd.

**Újrafuttatás:** a felsorolt kimeneti fájloknál explicit a felülírás.
Az előzőleg kézzel a `build` alá másolt extra fájl is belekerülne a ZIP-be;
az `expanded` idegen többletfájljait a kibontás nem törli. Ez nem tisztára törlő
release pipeline. **Takarítás:** csak a saját `build`, `expanded` mappát és
`demo-bundle.zip` fájlt távolítsd el; a következő teljes futás újra létrehozza.
A checksum kiszámítása önmagában nem hasonlítja össze egy előre ismert hash-sel,
a `verify` pedig visszaolvas, nem futtat alkalmazástesztet.

<a id="demo-04"></a>
<!-- documentation-anchors:start -->
<a id="doc-04--sensenet-docker-installation-and-management"></a>
<!-- documentation-anchors:end -->
## 04 – SenseNet Docker telepítés és menedzsment

Forrás: [projektleíró és wizard](../examples/sensenet-docker/plot-project.json),
[default, StepDefaults és 13 plot](../examples/sensenet-docker/default.json),
[projekt](../examples/sensenet-docker/project.json),
[development](../examples/sensenet-docker/environments/development.json),
[Compose-topológia](../examples/sensenet-docker/compose.yaml),
[Manage-SenseNet.ps1](../examples/sensenet-docker/scripts/Manage-SenseNet.ps1).
További üzemeltetési részletek: [SenseNet README](../examples/sensenet-docker/README-hu.md),
[korábbi valódi ellenőrzés bizonyítéka](../examples/sensenet-docker/VALIDATION-hu.md).

<!-- documentation-anchors:start -->
<a id="doc-the-stack-and-data-locations"></a>
<!-- documentation-anchors:end -->
### A stack és az adatok helye

Ez már tényleges, helyi fejlesztői telepítés. A forrás alapértékei:
`pm-sensenet-demo`, API HTTPS port `18160`, Identity HTTPS port `18161`.
A telepített demómásolatok saját neveket/portokat használhatnak: a GUI-ban látható
projektbeállítás és a futás outputja az irányadó. Egy új másolatban egyedi nevet
és két szabad portot válassz. A név és portok, továbbá az image-digestek az első
`prepare` után rögzítettek. Új telepítéshez új mappa és saját stack szükséges.

| Compose szolgáltatás | Mit csinál? | Elérés és megmaradó adatok |
| --- | --- | --- |
| `snsql` | SQL Server Developer; SQL `SELECT 1` healthcheck. | Nincs hostra publikált SQL-port. `<stack>_db-data` volume: `/var/opt/mssql`. |
| `db-init` | A SQL készenléte után egyszer létrehozza a `<stack>-sndb` adatbázist, ha hiányzik. | Egyszeri segédkonténer; sikeres befejezése normális állapot. |
| `snapp` | SenseNet repository API, SQL-adattárral. | `https://localhost:<ApiPort>`; `<stack>_app-data` volume: `/app/App_Data`. |
| `snis` | A repositoryhoz tartozó IdentityServer. | `https://localhost:<IdentityPort>`; bejelentkezéshez. |

A hostportok csak `127.0.0.1` interfészre vannak kötve. A projekt saját `.local`
mappája őrzi a runtime-envet, a localhost PFX-t, a prepared állapotot és a
mentéseket; tulajdonosra korlátozott jogosultsággal. Ezek érzékenyek, nem valók
GitHubra vagy másik projektbe. A Docker-volume-ok a Docker adattárában élnek.
A konténer eltávolítása és az adat törlése külön dolog.

PowerShell 7.2+, Linux-konténereket futtató Docker és Compose v2 kell **a
Plot Manager szolgáltatás gépén**, megfelelő memóriával és lemezhellyel. Az első
indítás image-letöltést és többperces adatbázis-/repository-inicializálást végezhet.
A SQL Developer licencet a használónak el kell fogadnia; a forrásban a kapcsoló
alapértéke `false`. Ez fejlesztői minta; a beépített új repository `admin/admin`
belépése és a saját localhost tanúsítvány nem éles használatra készült.

<!-- documentation-anchors:start -->
<a id="doc-every-plot-in-actual-execution-order"></a>
<!-- documentation-anchors:end -->
### Az összes plot, a tényleges végrehajtási sorrenddel

**Minden plot ugyanazzal a három invocationnel kezdődik.** A táblázatban a
közös 1–3 mindig az alábbi három valódi sort jelenti, nem rejtett vagy külön
motorfunkciót:

| Sorrend / ID | Natív Step | Pontos feladat |
| --- | --- | --- |
| 1. `runtime-directory` | `filesystem.mkdir` | `Path:".local"`; létrehozza a helyi runtime mappát. |
| 2. `configuration` | `json.write` | `Path:".local/settings.json"`, `Value=settings.SenseNet`, `Overwrite:true`; a rétegezett publikus telepítési értékeket exportálja. Az `Authentication` és a `Restore` objektum nem kerül ebbe a fájlba. |
| 3. `prepare` | `process.run` | `pwsh -NoProfile -File scripts/Manage-SenseNet.ps1 -Action prepare`; validálja a licencelfogadást, neveket, portokat, digesteket és tulajdonlást. Első alkalommal saját véletlen SQL-jelszó, repository API-key, PFX és runtime-env készül; később ellenőrzi és megőrzi őket. |

Minden további `process.run` az alábbi helper actiont hívja ugyanazzal a `pwsh
-NoProfile -File scripts/Manage-SenseNet.ps1` indítással. A timeout a konfigurált
process/Compose sorokban 900 másodperc; a helper készenlétre alapból legfeljebb
600 másodpercet vár. A Compose sorok a StepDefaults alapján a projekt `compose.yaml`
és `.local/runtime.env` fájlját, valamint `settings.SenseNet.StackName` projektnevet
használják. Így a soronkénti `With` csak a művelet saját argumentumait tartalmazza.

| Plot | Sorrendben a közös 1–3 után következő **összes** ID / Step | Tevékenység és használati cél |
| --- | --- | --- |
| `prepare` | Nincs további sor (összesen 3). | Csak helyi runtime-előkészítés; nem hoz fel szolgáltatást. Docker-tulajdonlást is ellenőriz, ezért Docker-elérés kell. |
| `install` | 4. `validate-compose` / `compose.config` (`--quiet`); 5. `start-services` / `compose.up` (`--wait --wait-timeout 240`); 6. `verify-repository-and-login` / `process.run`, action `verify`. | Compose-validálás, konténerek létrehozása/indítása, majd tényleges repository- és adminlogin-teszt. |
| `start` | 4. `start-services` / `compose.up` (ugyanaz a wait); 5. `verify-repository-and-login` / `process.run`, `verify`. | Meglévő telepítés indítása; a hiányzó konténereket is létrehozhatja. |
| `verify` | 4. `verify-repository-and-login` / `process.run`, `verify`. | A futó stack hitelesített kapcsolattesztje. Nem indít konténereket. |
| `demo-content` | 4. `create-or-read-demo-folder` / `process.run`, `demo-content`. | Login után `/Root/Content/PlotManagerDemo` mappa létrehozása, ha hiányzik, majd visszaolvasás. Meglévő mappánál az ID megmarad. |
| `verify-demo-content` | 4. `verify-persistent-demo-folder` / `process.run`, `verify -ExpectedContentPath /Root/Content/PlotManagerDemo`. | Login mellett a korábban létrehozott mappa és ID/Path meglétét ellenőrzi; nem pótolja a hiányzó tartalmat. |
| `status` | 4. `service-status` / `compose.ps` (`--all`). | A saját stack összes konténerének pillanatnyi állapota, a leálltaké is. A plot sikere azt jelenti, hogy a lekérdezés sikerült; az egyes szolgáltatásállapotokat az outputban olvasd. |
| `logs` | 4. `service-logs` / `compose.logs` (`--tail 80 --no-color`). | Szolgáltatásonként legfeljebb az utolsó 80 sor; nem folyamatos logkövetés. |
| `stop` | 4. `stop-services-keep-data` / `compose.stop` (`--timeout 30`). | Saját konténerek leállítása; konténerek és volume-ok megmaradnak. |
| `restart` | 4. `stop-services-keep-data` / `compose.stop` (`--timeout 30`); 5. `start-services` / `compose.up` (wait); 6. `verify-repository-and-login` / `process.run`, `verify`. | Leállítás → indítás → valódi működésellenőrzés. |
| `backup` | 4. `offline-consistent-backup` / `process.run`, `backup`. | Saját szolgáltatások leállítása, két volume hidegmentése, private runtime-fájlok másolása és SHA-256 manifest. Végül a korábban futó saját szolgáltatásokat indítja vissza. |
| `restore` | 4. `restore-confirmed-backup` / `process.run`, `restore -BackupPath settings.Restore.BackupPath -ConfirmRestore settings.Restore.ConfirmStackName`; 5. `start-services` / `compose.up` (wait); 6. `verify-repository-and-login` / `process.run`, `verify`. | A megerősített mentés a jelenlegi saját SQL/App_Data-adatokat **lecseréli**, majd a plot indít és ellenőriz. |
| `remove-containers-keep-data` | 4. `remove-containers-keep-volumes` / `compose.down` (üres `With`, nincs `--volumes`). | Saját konténerek és Compose-hálózat eltávolítása. Named volume-ok, `.local`, mentések megmaradnak; később `install` újra létrehozza a konténereket. |

A `process.run` outputjában `ExitCode`, `StandardOutput`, `StandardError` és
időtartam szerepel; a Compose output ugyanezt a folyamatmodellt használja.
A helper értelmezhető sikerüzenetet ír: URL-ek, ellenőrzött content path/ID,
mentési útvonal. A generált jelszavakat és tokeneket nem kell kiolvasni hozzá.

<!-- documentation-anchors:start -->
<a id="doc-what-does-the-helper-do-for-each-action"></a>
<!-- documentation-anchors:end -->
### Mit végez a helper az egyes actionök alatt?

| Helper action | Belső folyamat és korlát |
| --- | --- |
| `prepare` | A `pm-sensenet-…` név, két különböző 1024–65535 port, explicit licenc és SHA-256 image-digest ellenőrzése. A matching konténerek munkamappája és a volume-ok tulajdonosjelölése meg kell egyezzen. Saját runtime-fájlok generálása egyszer; az eltérő kötés vagy sérült/hiányos korábbi runtime hibát ad, nem írja felül csendben. |
| `verify` | A projekt tanúsítványára rögzített HTTPS-klienssel értelmes `/Root` OData-tartalom, OpenID discovery és signing keys; adminui kliensmetaadatok; valódi admin bejelentkezés authorization code + PKCE-vel; access tokennel az Admin(Id=1) tartalom olvasása. A callback címét adatként olvassa, nem navigál külső oldalra. `ExpectedContentPath` esetén a megadott tartalmat is visszaolvassa. |
| `demo-content` | Ugyanaz az adminlogin; a saját mintamappát lekéri, csak 404 esetén hozza létre Folderként, majd ellenőrzi a visszaolvasott pozitív ID-t és pontos Path-t. Nem általános import vagy minden tartalmat módosító művelet. |
| `backup` | Tulajdonlás és befejezett telepítés ellenőrzése, stack leállítása, a két saját volume tar.gz mentése hálózat nélküli átmeneti segédkonténerrel, a már helyben lévő rögzített SQL-image-ből. Runtime-titkok és tanúsítvány másolása; méret/hash lista. A korábban futó szolgáltatásokat visszaindítja. A mentés idején kiesés van. |
| `restore` | Csak e projekt `.local/backups` alatti könyvtár; pontos stacknév-megerősítés; egyező binding, image-ek, tanúsítvány, öt fájl neve/mérete/hash-e. Mindez az adatcsere előtt ellenőrződik. A saját leállított volume-ok tartalmát kicseréli és a private fájlokat visszaállítja. Részleges hiba esetén a szolgáltatásokat leállítva hagyja. A teljes plot később indít és loginellenőrzést végez. |

<!-- documentation-anchors:start -->
<a id="doc-a-first-installation-from-the-gui"></a>
<!-- documentation-anchors:end -->
### A: első telepítés a GUI-ból

1. Nyisd meg a negyedik projektet → `development` → `Guided setup`.
2. `Target`: ellenőrizd a futtató hostot. Adj meg egyedi `pm-sensenet-…` nevet,
   szabad API- és Identity-portot. Ne használd egy másik másolat stacknevét.
3. `Settings`: olvasd el és csak elfogadás esetén jelöld a SQL Developer licencet.
4. `Save answers →` a `project.json` `SenseNet` felülírásait menti.
5. `Run static preflight` → `Continue to run →` → `Run sample installation`.
   A statikus siker még nem bizonyítja, hogy a Docker fut vagy a port szabad.
6. `Run history`: hat sor; a végső `verify-repository-and-login` sikerüzenete
   igazolja a valódi OData- és adminlogin-ellenőrzést. Hiba esetén `status`, majd
   `logs` plot segít a diagnózisban. Az első indítást ne szakítsd meg csak azért,
   mert a repository-inicializálás több percet vesz igénybe.
7. Nyisd meg az outputban közölt API/Identity localhost URL-t. A saját
   tanúsítvány nincs automatikusan az OS megbízható tárolójába telepítve, ezért a
   böngésző figyelmeztetése várható. Az API-oldal nem egy külön telepített Admin UI.

<!-- documentation-anchors:start -->
<a id="doc-b-daily-management-and-data-persistence"></a>
<!-- documentation-anchors:end -->
### B: napi kezelés és adatmegmaradás

1. `Plot editor` → `demo-content` → preflight → teljes futás. Jegyezd fel a
   `/Root/Content/PlotManagerDemo` pozitív ID-jét.
2. Futtasd újra a `demo-content` plotot: ugyanazt a mappát olvassa, ugyanazzal az ID-val.
3. `stop` → `status`: a szolgáltatások leállnak, adatok megmaradnak.
4. `start` → `verify-demo-content`: a mappa ugyanazzal az ID-val elérhető.
5. Szükség esetén `restart`, majd `logs`. A naplóolvasás nem javítja a hibát;
   a `verify` az alkalmazásszintű működésellenőrzés.
6. A konténerek eltávolításának próbájához `remove-containers-keep-data` →
   `install` → `verify-demo-content`. Ez is adatmegőrző folyamat; nincs reset plot.

<!-- documentation-anchors:start -->
<a id="doc-c-backup-and-deliberate-restore"></a>
<!-- documentation-anchors:end -->
### C: mentés és tudatos visszaállítás

1. Előbb legyen sikeres telepítés és `demo-content`. Ne indíts párhuzamos
   író/menedzsment műveleteket ugyanarra a stackre.
2. `backup` → siker után a futási outputból jegyezd fel a létrehozott
   `.local/backups/<UTC-időpont>-<azonosító>` könyvtárat. A mentésben
   `db-data.tar.gz`, `app-data.tar.gz`, `runtime.env`, `snapp.pfx`, `prepared.json`
   és az ezeket felsoroló `manifest.json` van. Ez nem egy sima SQL `.bak` fájl.
3. Visszaállítás előtt értsd meg: a mentés utáni saját adatok elvesznek a
   visszaállítandó stackben. A `Configuration` **project** rétegébe, a meglévő
   mezők megőrzésével add hozzá:

   ```json
   {
     "Restore": {
       "BackupPath": ".local/backups/A-MENTES-KONYVTARA",
       "ConfirmStackName": "pm-sensenet-a-sajat-stack-neve"
     }
   }
   ```

4. `Save selected layer` → `restore` → preflight → teljes futás. A névnek
   karakterre pontosan az előkészített stack nevének kell lennie; az üres
   forrásértékekkel a valódi restore hibával megáll. A statikus preflight nem
   ellenőrzi egy mentés fájljait vagy a megerősítés értelmét.
5. Siker után `verify-demo-content`, ha a mappa a mentéskor már létezett. A
   `restore` végső alapellenőrzése csak a repository/login működést vizsgálja.
6. Töröld a két Restore felülírást vagy állítsd üresre, és ments. Egy véletlen
   későbbi újrafuttatás így nem állítja vissza újra ugyanazt a mentést.

Ez a változat azonos stackhez, azonos rögzített image-ekhez tartozó helyi mentést
támogat. Nem másik gépre migráló vagy verziófrissítő eszköz; hash-ellenőrzése a
sérülést jelzi, nem helyettesít külső digitális aláírást. A mentés jelszavakat is
tartalmaz: tartsd meg a korlátozott hozzáférést, ne töltsd a PR-ba.

<!-- documentation-anchors:start -->
<a id="doc-single-step-environment-rerun-and-cleanup"></a>
<!-- documentation-anchors:end -->
### Single step, environment, újrafuttatás és takarítás

A SenseNet plotokban nincs `steps.…Output` referencia; a sorrend nagy része
fájlokon és külső állapoton alapul. Egy `start-services` single-step statikus
sikere ezért nem állítja elő a hiányzó `.local/runtime.env` fájlt. A teljes
plotok adják a szükséges előkészítést. A `backup` és `restore` sem válik ártalmatlan
tesztté attól, hogy egyetlen process sorból áll: az action minden belső művelete lefut.

A forrásnak egyetlen `development` environmentje van, üres felülírással; a project
réteg is üres a friss mintában. Nincs kész production profil, automatikus
image-frissítés vagy üzemi telepítés. Újrafuttatáskor a `.local/settings.json`
frissül, a generált titkok és tanúsítvány megmaradnak, az `install` a meglevő
volume-okkal indul. A `backup` minden alkalommal új mentési könyvtárat készít.

Géplekapcsolás előtt a `stop` állítja le a saját stack-et; a Plot Manager ablak
bezárása ezt nem teszi meg. A `remove-containers-keep-data` erősebb takarítás,
de szándékosan megőrzi az adatot, image-eket és mentéseket. Teljes adatelpusztító
takarító plot nincs. Ne töröld a `.local` mappát egy később folytatandó
telepítésből: az adatvolume-ok mellé a hozzájuk tartozó helyi titkok is kellenek.
A `Run history` **Request stop · terminate worker** gombja a worker leállítását
kéri, nem Docker-rollback.

Megváltoztatott repository adminjelszó esetén a Runner secret neve legyen
`SENSENET_ADMIN_PASSWORD`, a projektbeállítás pedig:

```json
{
  "Authentication": {
    "AdminPassword": {"$env":"PLOTMANAGER_SECRET_SENSENET_ADMIN_PASSWORD"}
  }
}
```

Ez a beállítás az ellenőrző kliensnek adja át a már létező jelszót; magát a
SenseNet-fiókot nem módosítja. A nyers JSON-ba ne ments új valódi jelszót.

<!-- documentation-anchors:start -->
<a id="doc-cli-the-same-layers-and-engine"></a>
<!-- documentation-anchors:end -->
## CLI: ugyanazok a rétegek, ugyanaz a motor

A GUI a natív Plot Manager motort használja. A következő parancsokat a checkout
gyökeréből futtasd. Más projektmásolat esetén **mindhárom konfigurációs útvonal
és a WorkDirectory is ugyanarra a másolatra** mutasson. A CLI közvetlen futása
nem hoz létre a GUI szolgáltatásában Run history rekordot.

<!-- documentation-anchors:start -->
<a id="doc-01-guided-file-installer"></a>
<!-- documentation-anchors:end -->
### 01: vezetett fájltelepítő

```powershell
pwsh -NoProfile -File ./src/Deployment/Scripts/Run.ps1 install `
  -DefaultConfigPath ./examples/management-demos/01-vezetett-telepito/default.json `
  -ConfigPath ./examples/management-demos/01-vezetett-telepito/project.json `
  -EnvironmentConfigPath ./examples/management-demos/01-vezetett-telepito/environments/development.json `
  -WorkDirectory ./examples/management-demos/01-vezetett-telepito
```

<!-- documentation-anchors:start -->
<a id="doc-02-exporting-development-settings"></a>
<!-- documentation-anchors:end -->
### 02: development beállítások exportja

```powershell
pwsh -NoProfile -File ./src/Deployment/Scripts/Run.ps1 show-settings `
  -DefaultConfigPath ./examples/management-demos/02-retegek-es-hivatkozasok/default.json `
  -ConfigPath ./examples/management-demos/02-retegek-es-hivatkozasok/project.json `
  -EnvironmentConfigPath ./examples/management-demos/02-retegek-es-hivatkozasok/environments/development.json `
  -WorkDirectory ./examples/management-demos/02-retegek-es-hivatkozasok
```

A fájlnévben `development` helyett `production` a másik környezet. A plot neve
helyére `hibas-sorrend` írva az elvárt függőségi hibát kapod.

<!-- documentation-anchors:start -->
<a id="doc-03-production-package"></a>
<!-- documentation-anchors:end -->
### 03: production csomag

```powershell
pwsh -NoProfile -File ./src/Deployment/Scripts/Run.ps1 package `
  -DefaultConfigPath ./examples/management-demos/03-json-xml-zip/default.json `
  -ConfigPath ./examples/management-demos/03-json-xml-zip/project.json `
  -EnvironmentConfigPath ./examples/management-demos/03-json-xml-zip/environments/production.json `
  -WorkDirectory ./examples/management-demos/03-json-xml-zip
```

<!-- documentation-anchors:start -->
<a id="doc-04-sensenet-static-preview"></a>
<!-- documentation-anchors:end -->
### 04: SenseNet statikus előnézet

```powershell
pwsh -NoProfile -File ./src/Deployment/Scripts/Run.ps1 install `
  -DefaultConfigPath ./examples/sensenet-docker/default.json `
  -ConfigPath ./examples/sensenet-docker/project.json `
  -EnvironmentConfigPath ./examples/sensenet-docker/environments/development.json `
  -WorkDirectory ./examples/sensenet-docker -WhatIf
```

Az első három parancshoz is hozzáadható `-WhatIf`; `-Explain` a tervet és az
értékek forrását írja ki végrehajtás nélkül. A SenseNet valódi `install` futása
előtt töltsd ki a project réteget, fogadd el a licencet és ellenőrizd a helyi
feltételeket; ezután a `-WhatIf` elhagyható. A plotnév bármelyik dokumentált
SenseNet plotra cserélhető. A CLI `-Step` egy natív Step külön futtatására való,
nem egy már meglévő plot invocation-ID-jének kiválasztója.

<!-- documentation-anchors:start -->
<a id="doc-relationship-between-github-source-and-installed-copies"></a>
<!-- documentation-anchors:end -->
## A GitHub-forrás és a telepített másolat kapcsolata

Az első három forrásprojekt 14 JSON-bemenete az alkalmazásban korábban létrehozott
demók eredeti bemenetével byte/hash szinten egyező másolat. A GitHubról letöltött
friss példány még nem tartalmazza a helyi eredményfájlokat vagy futástörténetet.
A negyedik forrásának SQL-licencelfogadása szándékosan nincs előre bekapcsolva.
A helyi másolatban a wizarddal megváltoztatott érték ettől eltérhet.

Új gépen a teljes projektmappát másold a futtató szolgáltatás engedélyezett
projektgyökere alá, és az alkalmazás **Open project** műveletével vedd fel. Ne
próbáld egy másik futó példány teljes adattárát megnyitni egyszerre. A projektek
egymástól függetlenek; egyik sem követeli meg az előző demó kimenetét.
