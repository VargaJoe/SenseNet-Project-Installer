# Plot Manager – magyar felhasználói dokumentáció

Ez a belépőoldal a közös asztali és böngészős Plot Manager jelenlegi változatához
tartozik. A négy demó, a projektfájlok és az útmutatók a repóban vannak: az
olvasásukhoz nem kell futnia a fejlesztői gépnek vagy a helyi szolgáltatásnak.
A műveletek tényleges kipróbálásához természetesen szükséges egy futó Plot Manager.

## Mit érdemes először megnyitni?

| Kérdés | Olvasnivaló |
|---|---|
| Mit jelent a projekt, a plot, a step és a konfigurációs réteg? | [A teljes GUI-útmutató](management-user-guide-hu.md) eleje. |
| Melyik oldal, gomb és panel mire való? | [A teljes GUI-útmutató](management-user-guide-hu.md): az angol képernyőfeliratok magyar magyarázattal. |
| Mit csinál a négy konkrét demó, és mit kell látnom futtatás után? | [Demóprojektek és forgatókönyvek](management-demo-projects-hu.md). |
| Hol van az első három demó tényleges konfigurációja? | [A három általános demó](../examples/management-demos/README.md) – tiszta projektfájlok, generált kimenetek nélkül. |
| Hol van a SenseNet Docker projekt? | [SenseNet használat](../examples/sensenet-docker/README.md), [konfiguráció](../examples/sensenet-docker/default.json), [Compose-fájl](../examples/sensenet-docker/compose.yaml). |
| Hogyan telepíthetem vagy indíthatom a kezelőfelületet? | [Build, desktop és böngészős telepítés](management-deployment.md) – technikai útmutató, angolul. |
| Hogyan működik a natív JSON, az öröklés és a hivatkozás? | [Settings](settings.md), [natív motor](plot-manager-runtime.md) – részletes technikai háttér. |
| Mely működést ellenőriztük ténylegesen? | [Kezelőfelület ellenőrzése](management-validation.md), [SenseNet projekt ellenőrzése](../examples/sensenet-docker/VALIDATION.md). |

## A négy demó szerepe

| Projekt | Ezzel tanulható meg | Külső függőség / hatás |
|---|---|---|
| **01 – Vezetett fájltelepítő** | A kérdésekből hogyan lesz beállítás, két egymásra épülő step és egy tényleges fájl. | Szöveget ír a saját projektkönyvtárába. |
| **02 – Rétegek, típusok és hivatkozások** | Default → projekt → development/production, felülírás, öröklés és az effektív érték eredete. | JSON-eredményfájlt ír a saját projektkönyvtárába. |
| **03 – JSON, XML és ZIP csomagolás** | Hosszabb, sorrendi folyamat, korábbi step outputja, fájlgenerálás, csomagolás, ellenőrzés. | Saját build-, ZIP- és kibontott fájlokat készít. |
| **04 – SenseNet Docker telepítés és menedzsment** | Egy alkalmazás valódi telepítési és üzemeltetési folyamata ugyanazzal a motorral. | Saját Docker stack, SQL és App_Data volume-ok, helyi HTTPS, mentés és visszaállítás. |

A [demókatalógus](management-demo-projects-hu.md) minden projektnél külön felsorolja
a plotokat, az invocation ID-ket, a meghívott stepet, a bemeneteket, a kimeneteket,
a sorrendi függéseket és a kipróbálható forgatókönyveket.

## Javasolt tanulási sorrend

1. Olvasd el a GUI-útmutató fogalmait és a képernyőtérképet.
2. Nyisd meg az **01** projektet. Kövesd a vezetett beállítást, majd nézd meg,
   hogy a válaszok a **Configuration** oldalon melyik fájlba kerültek.
3. Ugyanezt a plotot nézd meg a **Plot editor** oldalon: a két invocation és az
   outputhivatkozás mutatja a motor alapötletét. A mentett verziót ellenőrizd és
   futtasd, majd olvasd el a **Run history** részletes eredményét.
4. A **02** projektben válts environmentet, és hasonlítsd össze a forrásréteget az
   effektív konfigurációval. Próbáld ki egy felülírás eltávolítását is.
5. A **03** projektben kövesd végig, honnan származik a JSON, az XML és a ZIP;
   figyeld meg, miért nem indítható minden outputfüggő step önállóan.
6. A **04** projektet akkor indítsd, amikor a Docker és a fejlesztői SQL feltételei
   rendelkezésre állnak. A restore forgatókönyv adatot cserél: a dokumentált
   mentést és pontos stacknév-megerősítést használd.

## Ellenőrzés csak GitHubról

A PR-ban a **Files changed** nézet a változtatásokat mutatja. Egy hosszabb útmutató
kényelmesebb olvasásához nyisd meg magát a Markdown-fájlt, és válaszd a formázott
nézetet. A fenti relatív linkek ugyanannak a branchnek a fájljaira vezetnek.

A GUI a **PR #32** része. A SenseNet projekt, az első három demó verziózott
definíciói és ez a teljes dokumentáció a ráépülő **PR #33** része. Amíg ezek
nincsenek mergelve, a default branch dokumentációja eltérhet: a PR branchét vagy
az átadásban hivatkozott commitot nézd.

| Mit tudsz futtatás nélkül is ellenőrizni? | Hol látszik? |
|---|---|
| Melyik projekt hogyan nevezi a plotokat és stepeket? | `default.json` → `Plots` → `Steps`, valamint a demókatalógus invocation-táblái. |
| Mely értékek öröklődnek és melyek felülírások? | Az adott projekt `default.json`, `project.json` és `environments/*.json` fájljainak összevetésével. |
| Mit kérdez a vezetett telepítő? | `plot-project.json` → `wizard.groups[].fields[]`. A `settingPath` mondja meg, hova mentődik a válasz. |
| Mit csinál egy általános step? | A demókatalógus magyarázata és a step [csomagmanifestje](../src/Deployment/Scripts/Auto/). |
| Mit csinál a SenseNet előkészítés vagy restore? | A [projekthez tartozó script](../examples/sensenet-docker/scripts/Manage-SenseNet.ps1), a külön használati leírás és a katalógus. |
| Miből készült a GUI pontos gomb- és panelleírása? | [App.tsx](../src/Management/Web/src/App.tsx), [paramétermezők](../src/Management/Web/src/components.tsx), a kapcsolódó szerver- és motorlogika. |

GitHub nem futtatja ezeket a plotokat, és a lekapcsolt gép localhost címei onnan
nem érhetők el. A tartós futástörténet az alkalmazás saját adattárában marad;
a repóba a hordozható bemenetek és az ellenőrzések leírása kerül.

## Rövid átvételi lista

- [ ] A négy projekt célját és fő kimenetét meg tudom nevezni.
- [ ] Megtalálom az egyes plotok lépéssorrendjét és az outputfüggéseket.
- [ ] Meg tudom különböztetni a szerkesztett forrásréteget a mentett effektív konfigurációtól.
- [ ] Tudom, mi a különbség a preflight, a WhatIf és a valódi futás között.
- [ ] Tudom, hol látszik a futtató gép, a futás állapota és az egyes stepek eredménye.
- [ ] Tudom, mit jelent a megszakítás és milyen külső hatások maradhatnak meg.
- [ ] Tudom, hol vannak a projektek, a titkok és a mentések, és mely másolatot szerkesztem.
- [ ] A SenseNet restore előtt értem, melyik saját stack adatait fogja lecserélni.
