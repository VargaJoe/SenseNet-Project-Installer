<!-- documentation-anchors:start -->
<a id="doc-local-gui-and-structured-integration"></a>
<!-- documentation-anchors:end -->
# Helyi GUI és strukturált integráció

<!-- documentation-navigation -->
[English](local-integration.md) | [Magyar](local-integration-hu.md) · [Dokumentáció](README-hu.md) · [Projekt](../README-hu.md)
<!-- /documentation-navigation -->

A `Show-PlotRunner.ps1` a natív futtatókörnyezet kis Windows Forms hostja. Windows PowerShell 5.1-ből (vagy Windows Forms támogatással rendelkező Windows PowerShell 7 telepítésből) indítsd:

```powershell
powershell.exe -NoProfile -STA -File ./src/Deployment/Scripts/Show-PlotRunner.ps1
```

1. Add meg az abszolút konfigurációs útvonalakat, soronként egyet, default -> project -> environment sorrendben.
2. Az útvonalak alatti szövegmezőben állítsd be az abszolút munkakönyvtárat.
3. Kattints a **Load plots** gombra, és válassz plotot.
4. A **Preview** gombbal végezz előzetes ellenőrzést, és kérj Skipped eredményt lépéshívások nélkül.
5. A **Run** gombbal indítsd a végrehajtást. Az ablak válaszképes marad, és megjeleníti a gyermekfolyamat végső JSON-kimenetét és kilépési kódját.

Az ablak ugyanazt a PowerShell-végrehajthatót használja, amely elindította. Nem kér automatikusan magasabb jogosultságot. Futás közben a vezérlők le vannak tiltva, és a bezárás az eredmény elkészültéig blokkolt. A kimenetet a befejezésig gyűjti; ez nem folyamatos naplónézegető. Megszakítást vagy visszaállítást nem támogat. Az eszközszintű határidők továbbra is érvényesek. Külső felügyeletet igénylő automatizáláshoz a CLI-t használd.

A régi Angular-kliens és kísérleti HTTP-listener történeti kód marad. Nem kapcsolódnak a natív motorhoz, és nem szabad őket távoli parancsvégrehajtási végpontként kitenni. Az új host helyi gyermekfolyamatot és ideiglenes kérésfájlt használ; nem indít hálózati listenert. Csak megbízható csomagmappákat, plotokat, szkripteket és eszközargumentumokat tölts be, a műveleteik elvégzésére jogosult operációsrendszer-identitással.

<!-- documentation-anchors:start -->
<a id="doc-json-request-protocol-version-1"></a>
<!-- documentation-anchors:end -->
## JSON-kérésprotokoll, 1. verzió

A hostfüggetlen híd: `Core/PlotIntegration.psm1` -> `Invoke-PlotRequest`. A CLI-burkolat:

```powershell
./src/Deployment/Scripts/Invoke-Request.ps1 -RequestPath ./request.json
```

Példakérés:

```json
{
  "Operation": "run",
  "ConfigurationFiles": ["C:/work/default.json", "C:/work/project.json", "C:/work/test.json"],
  "Plot": "deploy",
  "WorkDirectory": "C:/work",
  "Overrides": {"copy": {"Overwrite": true}},
  "WhatIf": true
}
```

- Az Operation értéke `catalog`, `plan` vagy `run`. Az ismeretlen mezőket elutasítja.
- A ConfigurationFiles opcionális rendezett tömb, amely pontosan a natív mély összefésülési/hivatkozási szabályokat használja. A relatív konfigurációs útvonalak a hívó aktuális könyvtárához képest oldódnak fel. GUI-hívóknál abszolút útvonalak ajánlottak.
- A Catalog ProtocolVersion=1 értéket, lépésazonosítókat/csomagokat/verziókat/paramétersémákat és plotneveket ad vissza. A titkos paraméterek alapértékeit kihagyja; tényleges konfigurációs értékeket soha nem ad vissza.
- A Plan pontosan egy Plot vagy Step értéket igényel. Hívásazonosítókat, kanonikus lépésazonosítókat és paraméterforrás-címkéket ad vissza feloldott beállításértékek nélkül. A statikus hivatkozásokat és típusokat providerszintű hívás nélkül ellenőrzi.
- A Run pontosan egy Plot vagy Step értéket igényel. Az Overrides hívásazonosító szerint kulcsolt objektum; Step esetén a `single` kulcsot használd. A WhatIf értékének JSON-logikai értéknek kell lennie. Ugyanazt a Status/Steps eredményt adja vissza, mint a Run.ps1; az előnézet eredménye Skipped. A korábbi lépések késleltetett kimeneti értékei csak végrehajtáskor oldódnak fel.
- A CLI stdout egyetlen JSON-dokumentumot tartalmaz, előnézetkor is. A 0 kilépési kód sikert/előnézetet, az 1 ellenőrzési vagy végrehajtási hibát jelent. Az ellenőrzési hibák az stderr-re kerülnek, a végrehajtási hibák strukturált eredmények. A sikeres lépéskimenetek szándékosan tartalmazhatnak érzékeny adatokat.

Nincs tetszőleges parancsszöveg-mező, szkriptkiértékelés vagy távolról kiválasztható modulútvonal. Ez megbízható helyi hívónak szánt integrációs szerződés, nem hitelesítési határ. Egy asztali alkalmazás folyamatargumentum-tömbbel meghívhatja a szkriptet és feldolgozhatja az stdout-ot; egy távoli szolgáltatásnak továbbra is saját hitelesítésre, jogosultságkezelésre, kéréskorlátokra és elkülönítésre lenne szüksége.

<!-- documentation-anchors:start -->
<a id="doc-acceptance-check"></a>
<!-- documentation-anchors:end -->
## Átvételi ellenőrzés

A meglévő layered-artifact példát használd újonnan létrehozott ideiglenes munkakönyvtárral. Az `Examples/layered-artifact` könyvtárból ebben a sorrendben töltsd be a default.json, project.json és environment.json fájlokat. Az előnézetnek változatlanul kell hagynia a könyvtárat; a Run létrehozza a dokumentált kimeneteket, és Succeeded állapotot mutat. Ismételt futtatáskor a meglévő fájlokra vonatkozó szokásos viselkedésnek kell megjelennie. A fő regressziós tesztcsomag mindkét támogatott PowerShell hoston ellenőrzi a kérésprotokollt; a `tests/Run-GuiSmoke.ps1` a valódi vezérlőket és az aszinkron gyermekfolyamat-végrehajtást is ellenőrzi látható ablak nélkül. A vizuális Windows Forms-interakció ehhez a kézi ellenőrzéshez kötött.
