<!-- documentation-anchors:start -->
<a id="doc-how-to-execute-a-plot"></a>
<!-- documentation-anchors:end -->
# „Plot” végrehajtása

<!-- documentation-navigation -->
[English](how-to-execute-a-plot.md) | [Magyar](how-to-execute-a-plot-hu.md) · [Dokumentáció](../README-hu.md) · [Projekt](../../README-hu.md)
<!-- /documentation-navigation -->

Ahogy korábban említettük, a megoldás fő célja meghatározott feladatok szinkron végrehajtása. A forgatókönyv neve „plot”, a végrehajtható feladaté „step”. Mivel a „plot” legtöbbször több lépésből álló feladatokat automatizál, időt takarítva meg, az alapforgatókönyvekben (például a fejlesztői környezet létrehozása vagy frissítése) a „plot” kap nagyobb szerepet. A forgatókönyvek a beállítási fájlban vannak deklarálva, amely tárolja az adott plot lépéseit. Jó példa a 'fullinstall', amely a nulláról telepíti a sensenetet az adott projekthez konfigurálva. E plot a következő lépésekből áll (természetesen projektenként eltérhet):
- leállítja a site-ot (ha korábban már telepítve volt)
- letölti a projektben deklarált NuGet-csomagokat
- létrehozza a szükséges assemblyfájlokat (azaz lefordítja a solutiont)
- törli az adatbázist
- létrehozza az új adatbázist, és telepíti az [sn-services](https://github.com/SenseNet/sensenet) csomagot
- telepíti az [sn-webpages](https://github.com/SenseNet/sn-webpages) csomagot
- eltávolítja a demótartalmat
- előre definiált felhasználókat ad a repositoryhoz
- telepíti az egyedi, projekthez kapcsolódó tartalmakat
- beállítja a projektspecifikus URL-eket a repository megfelelő site-jain
- feltölti a Lucene-indexet
- létrehozza a site-ot IIS-ben
- hozzáadja a megadott URL-eket a helyi gép HOST fájljához
- elindítja az IIS-site-ot

E rövid áttekintés után nézzük a tényleges végrehajtást. Ha egy projekt megfelelően konfigurált és előkészített, és a végrehajtás összes előfeltétele teljesül, a fejlesztőnek – aki tegyük fel, most csatlakozott a projekthez – csak le kell kérnie a kódot, megnyitnia egy PowerShell-ablakot, és végrehajtania ezt:

```powershell
.\Run.ps1 -Legacy fullinstall
```

A fenti kód a „fullinstall” forgatókönyvet futtatja a „Project” konfigurálásához a „local” beállításokkal, vagyis létrehozza a helyi fejlesztői környezetet (ebben az esetben egy sensenet site-ot).
Ilyenkor a script minimális visszajelzést ad, csak a segédeszközök által visszaadott üzenetek látszanak. Ha további információ kell, a script készítői által fontosnak tartott visszajelzések ezzel a kiegészítéssel érhetők el:

```powershell
.\Run.ps1 -Legacy fullinstall -Verbose
```

Ha a segédeszközök visszajelző üzeneteit szeretnéd kihagyni, használd ezt:

```powershell
.\Run.ps1 -Legacy fullinstall -ShowOutput false
```

A fenti példák csak előre definiált forgatókönyvek helyi környezetben történő végrehajtásához elegendők, de egyedi forgatókönyvek, nem helyi környezetek (például tesztszerver) és több projekt kezelése is lehetséges. Ilyenkor a paramétereket részletesebben kell ismerni. A fenti második példa így is kinézhet:

```powershell
.\Run.ps1 -Legacy -Plot fullinstall:Project -Settings local -ShowOutput true -Verbose
```

Tegyük fel, hogy egy 'Custom' nevű projekt egyedi projekttartalmát szeretnénk frissíteni egy elosztott tesztszerveren, saját beállítási fájllal. Ez így történhet:

```powershell
.\Run.ps1 -Legacy -Plot updatetestsite -Settings custom -ShowOutput true -Verbose
```
