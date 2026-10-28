<!-- documentation-anchors:start -->
<a id="doc-plot-configuration"></a>
<!-- documentation-anchors:end -->
# Plot-konfiguráció

<!-- documentation-navigation -->
[English](settings.md) | [Magyar](settings-hu.md) · [Dokumentáció](README-hu.md) · [Projekt](../README-hu.md)
<!-- /documentation-navigation -->

A konfiguráció JSON-objektum. A CLI legfeljebb három fájlt olvas ebben a sorrendben:

1. `-DefaultConfigPath`: közös alapkonfiguráció.
2. `-ConfigPath`: projektkonfiguráció. Alternatívaként a `-Settings name` a `Settings/project-name.json` fájlt választja ki.
3. `-EnvironmentConfigPath`: környezetspecifikus felülírások.

Minden réteg opcionális; az explicit megadott fájloknak létezniük kell, és JSON-objektumot kell tartalmazniuk. A későbbi fájlok rekurzívan felülírják a korábbiakat. A kihagyott tulajdonságok öröklődnek; a tömbök lecserélődnek, az üres tömböket is beleértve, a null/false/zero értékek pedig megmaradnak. Ugyanezek a szabályok érvényesek a beállításokra és a plotdefiníciókra. A betöltő minden lépés végrehajtása előtt befejezi a munkáját.

```powershell
./src/Deployment/Scripts/Run.ps1 build-report -DefaultConfigPath ./default.json -ConfigPath ./project.json -EnvironmentConfigPath ./production.json
```

A `-ConfigPath` és a `-Settings` a projektréteg kiválasztásának egymást kizáró módjai. Mindkettő kombinálható alap- és környezeti réteggel. A meglévő egyfájlos hívások továbbra is működnek. A fájlútvonalak a hívás munkakönyvtárához képest oldódnak fel; a `-WorkDirectory` a lépések fájlműveleteit szabályozza, nem a konfigurációs fájlok felderítését. A natív mód nem tölti be implicit a legacy `Settings/project-default.json` fájlt; a kívánt natív alapkonfigurációt explicit válaszd ki.

A modul API-ján keresztül tetszőleges számú fájl adható meg prioritási sorrendben:

```powershell
$config = Read-PlotConfiguration -Path @('./default.json', './project.json', './production.json')
```

A már memóriában lévő konfigurációs objektumokhoz a `Merge-PlotSettings -Layers` parancsot használd. Az `-Explain` sorrendben felsorolja a betöltött ConfigurationFiles fájlokat és a hívásparaméterek forráscímkéit; a `-Verbose` értékek nélkül naplózza a betöltött útvonalakat. A paraméterforrás-címkék a hívás rétegeit írják le, nem az egyes forrás-JSON-fájlokat.

A fájlrétegek összefésülése után az alábbi hívási prioritás érvényesül. Az explicit `-Params` felülírások továbbra is elsőbbséget élveznek. A környezeti fájl az egyező JSON-tulajdonságútvonalakat írja felül; egy globális alapérték nem ír felül egy specifikusabb hívásszintű `With` értéket. Lásd a teljes [réteges csomagpéldát](generic-packages-hu.md#doc-complete-local-example).

```json
{
  "Message": { "Name": "operator" },
  "Plots": {
    "hello": {
      "Steps": [
        {
          "Id": "compose",
          "Step": "text.join",
          "With": {
            "Items": ["Hello", { "$ref": "settings.Message.Name" }],
            "Separator": ", "
          }
        },
        {
          "Id": "save",
          "Step": "filesystem.write",
          "With": {
            "Path": "hello.txt",
            "Content": { "$ref": "steps.compose.Output.Text" }
          }
        }
      ]
    }
  }
}
```

A lépésazonosító egy definíciót azonosít; a hívásazonosító egy ploton belüli előfordulást. Ugyanaz a lépés tetszőleges számú alkalommal szerepelhet. A hívásazonosítónak betűvel kell kezdődnie, és betűket, számokat, aláhúzásokat vagy kötőjeleket tartalmazhat. A kihagyott azonosítók `step1`, `step2` stb. értéket kapnak; hivatkozásokhoz célszerű explicit azonosítókat használni.

<!-- documentation-anchors:start -->
<a id="doc-precedence"></a>
<!-- documentation-anchors:end -->
## Prioritás

A későbbi rétegek felülírják a korábbiakat:

1. A lépés paramétersémájának alapértékei.
2. A konfiguráció `Defaults` értéke.
3. A konfiguráció `StepDefaults["package.step"]` értéke.
4. A hívás által kiválasztott felső szintű `Section`, ha van ilyen.
5. A plot `Defaults` értéke.
6. A hívás `With` értéke.
7. Explicit futási felülírások, hívásazonosító szerint kulcsolva.

Az alapértékek csak a megfelelő helyen alkalmazhatók: egy közös Defaults leképezés csak minden érintett lépés által elfogadott paramétereket tartalmazhat. Heterogén plotokhoz StepDefaults vagy explicit With leképezéseket használj. Az ismeretlen paraméterneveket a rendszer elutasítja.

```powershell
# Override only one invocation. JSON values retain their types.
./src/Deployment/Scripts/Run.ps1 hello -ConfigPath ./hello.json -Params '{"save":{"Path":"other.txt","Overwrite":true}}'
```

Az objektumok rekurzívan összefésülődnek. A tömbök egészükben lecserélődnek, az üres tömböt is beleértve. Az explicit null lecseréli az értéket; a sémának engedélyeznie kell a null értéket. A false és a zero érték, nem hiányzó beállítás. Minden hívás mély másolatot kap, ezért annak módosítása nem változtathatja meg az alapkonfigurációt vagy egy másik hívás bemenetét.

<!-- documentation-anchors:start -->
<a id="doc-references"></a>
<!-- documentation-anchors:end -->
## Hivatkozások

- A `{"$ref":"settings.Message.Name"}` egy konfigurációs értéket választ ki.
- A `{"$ref":"steps.compose.Output.Text"}` egy korábbi hívás kimenetét választja ki.
- A `{"$env":"MY_SETTING"}` explicit kiolvas egy környezeti változót.

A hivatkozásobjektumoknak pontosan egy direktívát kell tartalmazniuk. Értékhivatkozások, nem PowerShell-kifejezések vagy karakterlánc-interpolációk. A tulajdonságútvonalak pontokat használnak; a pontot tartalmazó kulcsok ezzel a szintaxissal nem címezhetők. Kimenetre csak korábbi hívás esetén lehet hivatkozni. A tényleges kimeneti tulajdonságot és végleges típust közvetlenül a fogyasztó lépés futása előtt ellenőrzi a rendszer.

A beállításhivatkozások tervezéskor rekurzívan feloldódnak. Egy kiválasztott érték tartalmazhat újabb beállításhivatkozást, környezeti hivatkozást vagy hivatkozásokat tartalmazó beágyazott objektumokat/tömböket. Külön mezőkben az ismételt hivatkozások megengedettek. A körkörös hivatkozások a hivatkozási útvonal feltüntetésével, még bármely lépés végrehajtása előtt hibát okoznak; egy lánc legfeljebb 64 beállításhivatkozást tartalmazhat a kibontás korlátozása érdekében. A hiányzó értékek és a statikusan érvénytelen paramétertípusok szintén végrehajtás előtt hibát okoznak.

Például egy közös `"Values": {"Message": {"$env":"MESSAGE_TEXT"}}` értéket a `"Content": {"$ref":"settings.Values.Message"}` használhat. Ez a Content karakterláncként történő ellenőrzése előtt olvassa ki a MESSAGE_TEXT értékét.

Egy beállításalias korábbi lépés kimeneti hivatkozását is kiválaszthatja. A motor ezt a hivatkozást a fogyasztó végrehajtásáig késleltetve tartja; az előre mutató vagy önmagára hivatkozó kimeneti hivatkozások továbbra is érvénytelenek. A lépéskimenet végleges adat: a lépés által visszaadott `$ref`/`$env` alakú objektumokat a motor nem értelmezi új konfigurációs direktívaként.

A környezeti hivatkozások a tervezés során oldódnak fel, beleértve a beállításokon át közvetett hivatkozásokat is. Natív módban nincs rejtett környezeti ráfedés. A hiányzó változók ellenőrzési hibát okoznak; a karakterláncok csak deklarált int/bool paraméterekhez konvertálódnak. A logikai karakterláncok csak true vagy false értékűek lehetnek, ezért a "false" soha nem válik igazzá egy karakterlánc-cast miatt.

<!-- documentation-anchors:start -->
<a id="doc-schema-validation"></a>
<!-- documentation-anchors:end -->
## Sémaellenőrzés

Típusok: `string`, `int`, `bool`, `array`, `object` (leképezés). A paraméterek deklarálhatják a `Required`, `Default`, `AllowNull`, `ValidateSet`, numerikus `Minimum`/`Maximum` és `Secret` tulajdonságokat.

A hiányzó kötelező beállítások, ismeretlen paraméterek, érvénytelen skalártípusok és érvénytelen statikus hivatkozások az előzetes ellenőrzésben hibát okoznak, mielőtt bármely lépés futna. A késleltetett kimeneti hivatkozásokat az őket előállító lépés után ellenőrzi a motor, mert az értékük az előzetes ellenőrzéskor még nem létezik.

<!-- documentation-anchors:start -->
<a id="doc-inspection"></a>
<!-- documentation-anchors:end -->
## Megvizsgálás

Az `-Explain` hívásazonosítókat, feloldott lépésazonosítókat és paraméterforrás-címkéket ad vissza csomagparancsok végrehajtása nélkül. A `-Verbose` naplózza a kiválasztott lépést és a forráscímkéket; a beállításértékeket nem írja ki. Az `-WhatIf` kihagyott eredményeket ad vissza, és egyetlen csomagparancsot sem hív meg.

A deklarált titkos skalárértékek kitakarásra kerülnek, ha lépéskivétel üzenetében fordulnak elő. Ez nem általános adatvesztés-megelőzési határ: a csomagkészítők soha nem írhatnak titkokat saját kimeneteikbe, naplóikba vagy kivételrekordjaikba.

<!-- documentation-anchors:start -->
<a id="doc-compatibility-forms"></a>
<!-- documentation-anchors:end -->
## Kompatibilitási formák

A plot közvetlenül tömböt is használhat. A karakterlánc-bejegyzések `package.step:Section` formában választhatnak ki beállításszakaszt:

```json
{
  "Chosen": { "Items": ["one", "two"], "Separator": "-" },
  "Plots": { "example": ["text.join:Chosen"] }
}
```

Ezek a karakterláncok natív lépésazonosítókra vagy regisztrált aliasokra hivatkoznak. A történeti `Step-*` függvényekhez `-Legacy` szükséges; a konfigurációikat a történeti betöltő kezeli. Lásd a [legacy konfigurációt](legacy/settings-hu.md).

A JSON-karakterláncok karakterláncok maradnak, beleértve az időzóna-eltolást tartalmazó ISO-időbélyegeket is. Ez a konfigurációs rétegekre, a `-Params` értékére és a JSON csomagra egyaránt érvényes. Az explicit megadott üres vagy csak whitespace-t tartalmazó konfigurációs útvonal hiba; egy opcionális réteg kihagyásához magát az argumentumot hagyd el.
