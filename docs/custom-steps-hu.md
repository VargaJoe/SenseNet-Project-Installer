<!-- documentation-anchors:start -->
<a id="doc-author-a-step-package"></a>
<!-- documentation-anchors:end -->
# Lépéscsomag készítése

<!-- documentation-navigation -->
[English](custom-steps.md) | [Magyar](custom-steps-hu.md) · [Dokumentáció](README-hu.md) · [Projekt](../README-hu.md)
<!-- /documentation-navigation -->

Az üzemeltető a csomag teljes könyvtárának egy Auto mappába másolásával telepíti a csomagot. A felderítés a közvetlen alkönyvtárakban keresi a `package.psd1` fájlt. Az erőforrások útvonalai a csomaghoz képest legyenek relatívak; ne függjenek a repository aktuális könyvtárától vagy globális változóktól.

Példa a felépítésre:

```text
Auto/
  Example/
    package.psd1
    Plot.Example.psm1
```

<!-- documentation-anchors:start -->
<a id="doc-manifest"></a>
<!-- documentation-anchors:end -->
## Jegyzékfájl

```powershell
@{
    Name = 'example'
    Version = '1.0.0'
    RootModule = 'Plot.Example.psm1'
    Dependencies = @() # Installed package names; cycles are rejected.
    Steps = @{
        greet = @{
            Command = 'Get-ExampleGreeting'
            Aliases = @('greet')
            Parameters = @{
                Name = @{ Type='string'; Required=$true }
                Prefix = @{ Type='string'; Default='Hello' }
            }
        }
    }
}
```

A kanonikus lépésazonosító `example.greet`. A csomagnevek, kanonikus azonosítók és aliasok összehasonlítása nem különbözteti meg a kis- és nagybetűket. Egy alias kanonikus névvel is ütközhet, ezért a rendszer a modulok importálása előtt minden nevet együtt ellenőriz. Az ismétlődést jelző hibák mindkét forrásjegyzékfájlt megnevezik.

A Name és a lépések kulcsai betűvel kezdődnek, és betűket, számokat vagy kötőjeleket tartalmazhatnak. A Version értékének .NET Version típusként értelmezhetőnek kell lennie. A RootModule a csomagon belüli psm1 fájlt jelöli. Az opcionális Platform értéke Any vagy Windows.

A Dependencies a szükséges telepített csomagokat és az importálási sorrendet adja meg. A lépés megkapja a `Context.Dependencies` értéket is: ez a közvetlenül deklarált függőségek kanonikus lépésazonosítóit tartalmazza, mindegyiknél egy `Command` értékkel (az elkülönített exportált függvényobjektummal) és egy friss `Defaults` leképezéssel. Ez nem tesz elérhetővé privát függvényeket, és nem hoz létre globális értékeket. A `process.run` hívására a Git/build/Docker adapterek adnak példát. Az adapterek átadják a teljes beállításleképezést, ellenőrzik a saját bemeneteiket, és a hívás előtt tiszteletben tartják a ShouldProcess döntését; a közvetlen függőséghívások nem futtatják a motor előzetes ellenőrzését, és nem hoznak létre további plot-eredménybejegyzéseket. Külön plot-hívásokat célszerű használni, ha az üzemeltetőnek külön eredményekre vagy konfigurációs rétegekre van szüksége.

<!-- documentation-anchors:start -->
<a id="doc-module"></a>
<!-- documentation-anchors:end -->
## Modul

```powershell
function Get-ExampleGreeting {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][hashtable]$Settings,
        [Parameter(Mandatory)]$Context
    )
    [pscustomobject]@{ Text="$($Settings.Prefix), $($Settings.Name)" }
}
Export-ModuleMember -Function Get-ExampleGreeting
```

Az exportált parancsnak fogadnia kell a Settings és Context paramétereket. A regiszter a függvényobjektumot hívja meg, ezért külön modulok azonos belső függvényneveket is használhatnak. Ne exportálj és ne definiálj globális függvényeket vagy változókat.

A Context tartalma: RunId, InvocationId, PackageRoot, WorkDirectory és Dependencies. A függőség parancsa a hívó kontextusát kapja; a saját erőforrásokkal rendelkező függőség a saját moduljának PSScriptRoot értékét használja. A Settings kizárólag az adott híváshoz feloldott és ellenőrzött paramétereket tartalmazza.

Az adatokat a sikeres kimeneti adatfolyamon add vissza. Hiba esetén dobj kivételt. Diagnosztikához a Write-Verbose/Write-Information használható; soha ne írd ki teljes egészében a beállításokat vagy hitelesítő adatokat. Külső végrehajtható program használatakor azonnal ellenőrizd a LASTEXITCODE értékét, és hiba esetén dobj kivételt; a natív program nem nulla kilépési kódja nem minden támogatott futtatókörnyezetben válik automatikusan PowerShell-kivétellé.

<!-- documentation-anchors:start -->
<a id="doc-operations-and-whatif"></a>
<!-- documentation-anchors:end -->
## Műveletek és WhatIf

Az állapotot módosító függvény deklarálja a SupportsShouldProcess támogatást, és a tényleges műveletet a `$PSCmdlet.ShouldProcess(...)` döntésével védje. A motor minden lépéshívást külön is véd, ezért a natív plot WhatIf egyetlen lépésfüggvényt sem hajt végre. A függvény szintű védelem a közvetlen hívásokat védi.

Példákat a filesystem és IIS csomagokban találsz. A filesystem írója alapértelmezés szerint CreateNew módot használ, hogy ne cseréljen le észrevétlenül meglévő fájlokat. Az IIS csak tényleges művelet kérésekor importálja a WebAdministration modult.

A csomag importálásakor lefut a PowerShell-modul inicializáló kódja. A telepített csomagok megbízhatónak tekintett végrehajtható kódok: az importálás csak függvénydefiníciókat és helyi inicializálást végezzen, telepítési, fájl- vagy hálózati műveletek nélkül. A jegyzékfájl statikus ellenőrzése nem jelent sandboxot.

<!-- documentation-anchors:start -->
<a id="doc-testing"></a>
<!-- documentation-anchors:end -->
## Tesztelés

Futtasd a `./tests/Run-Tests.ps1` parancsot PowerShell 5.1 és 7 alatt. Csomagparancsok hozzáadásakor adj hozzá viselkedést ellenőrző teszteket is. A csomagot külön Auto könyvtárban teszteld, hogy kiderüljenek a teljes repositoryra való véletlen függések.

A történeti AutoExt lépéskonvenciókat a [legacy/custom-steps-hu.md](legacy/custom-steps-hu.md) ismerteti. Ezek a külön kompatibilitási futtatóhoz tartoznak.
