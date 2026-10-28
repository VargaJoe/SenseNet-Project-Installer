<!-- documentation-anchors:start -->
<a id="doc-management-application-acceptance"></a>
<!-- documentation-anchors:end -->
# A management alkalmazás átvétele

<!-- documentation-navigation -->
[English](management-acceptance.md) | [Magyar](management-acceptance-hu.md) · [Dokumentáció](README-hu.md) · [Projekt](../README-hu.md)
<!-- /documentation-navigation -->

Használj új projektet és kizárólag ehhez a gyakorlathoz fenntartott könyvtárat. A
minta csak szöveg- és fájlrendszercsomagokat használ; nincs szüksége adatbázisra, konténerre,
céges konfigurációra, privát végpontra vagy rendszergazdai jogokra.

1. Kövesd a [build és indítás](management-deployment-hu.md) útmutatóját a helyi böngészős módhoz,
   vagy telepítsd a fejlesztői asztali csomagot. Ellenőrizd, hogy a fejléc azonosítja
   a szolgáltatás gazdagépét és a futásidejű identitást. A hosztolt módnak a szervert kell azonosítania.
2. Hozz létre projektet a **generic file installer** sablonnal. Válaszd a Guided
   setup lehetőséget, adj meg `acceptance.txt` fájlnevet és felismerhető üzenetet, mentsd a válaszokat,
   futtass statikus preflightot, majd hajtsd végre a mintát. Ellenőrizd a valódi UTF-8 fájlt
   a megjelenített projektkönyvtárban és a strukturált kimenetet a Run history alatt.
3. Nyisd meg újra a futás URL-jét, vagy töltsd újra az oldalt egy hosszabb, jóváhagyott helyi teszt közben.
   Ellenőrizd az azonos Run ID-t, az újrajátszott lépéseseményeket és a tárolt eredményt. A böngészőlap bezárása
   nem szakíthatja meg a kezelt futást. Az asztali alkalmazás bezárása a megjelenített
   megerősítés után kifejezetten leállítja saját szolgáltatását.
4. A Configuration oldalon kifejezetten válaszd ki a projekt- vagy környezeti réteget. Add hozzá:
   `"Acceptance":{"nil":null,"off":false,"zero":0,"empty":[],"extension":"kept"}`.
   Mentsd és töltsd újra. Vizsgáld meg a nyers rétegeket és az effektív fájleredeteket. Írj felül
   egy alapértelmezett üzenetet a környezetben, majd töröld a felülírást az öröklés
   visszaállításához. A preflight részleteiben ellenőrizd a pontos fájl-, motorbeállítási réteg- és hivatkozási eredeteket.
   Egy réteget sem helyettesíthet az effektív, összefésült konfiguráció.
5. Nyisd meg ugyanazt a kiválasztott réteget két böngésző-munkamenetben. Ments az egyikben, majd próbáld
   menteni az elavult módosításokat a másikban. Ütközést és a helyi módosítások megőrzését várjuk.
   Ha egy futás birtokolja projektje zárolását, a szerkesztési vagy ütköző futásindítási kísérletnek
   szintén láthatóan meg kell hiúsulnia.
6. A Plot editor oldalon mozgasd a `save` elemet a `compose` elé, ments, majd futtass preflightot.
   Korábbi kimenettől való függőségi hibát várunk bármilyen művelet előtt. Állítsd vissza a sorrendet.
   Válaszd a `compose` elemet, és csak azt a hívást futtasd. Válaszd önmagában a `save` elemet, és várj
   függőségi elutasítást. A teljes plot mindkettőt egymás után hajtsa végre.
   Másolj/adj hozzá/távolíts el hívásokat, és vizsgáld meg stabil, különböző azonosítóikat.
7. A WhatIf Skipped natív lépéseket mutasson, és ne módosítson fájlokat. Ez
   nem bizonyítja a szolgáltatás elérhetőségét. Kifejezett HTTP/TCP/SQL készenléti lépést
   csak akkor futtass, ha az adott célpont aktív tesztelése engedélyezett.
8. Tárolj szintetikus hitelesítőadatot a Runner secrets alatt, és használd annak `$env` hivatkozását.
   Ellenőrizd, hogy az értékek sosem jönnek vissza a titoklistázó API-ból, és nem jelennek meg a futáskimenetben.
   Állíts le egy szándékosan hosszú, elkülönített folyamatlépést. Cancelled állapotot és arra vonatkozó
   figyelmeztetést várunk, hogy a befejezett/külső hatások nem gördülnek vissza. Megszakítás tesztelésére soha ne használj
   valódi telepítést.

A CLI-egyezéshez állítsd a `$project` értékét az újonnan létrehozott projekt könyvtárára, és futtasd
a forráscheckoutból Windowson vagy Linuxon PowerShell 7-ben:

```powershell
pwsh -NoProfile -File ./src/Deployment/Scripts/Run.ps1 install `
  -DefaultConfigPath "$project/default.json" `
  -ConfigPath "$project/project.json" `
  -EnvironmentConfigPath "$project/environments/development.json" `
  -WorkDirectory "$project"
```

Ez ugyanazokat a közönséges fájlokat és natív plotot olvassa, mint a GUI. Környezet nélküli
projektnél hagyd el a környezeti argumentumot. A hívásonkénti `-Params` felülírásokat lásd
a [konfigurációnál](settings-hu.md). A takarításhoz állítsd le a gyakorlat szolgáltatását,
ellenőrizd, hogy a mintakönyvtár kizárólag ehhez a gyakorlathoz létrehozott erőforrásokat tartalmaz,
majd távolítsd el azt és privát tesztállapotát. Meglévő
projektet vagy más futtatói adatot ne távolíts el.

Az automatizált parancsok és platformbizonyítékok a [telepítésnél](management-deployment-hu.md)
és a [teszteknél](../tests/README-hu.md) találhatók. A sikeres telepítőbuild, a rejtett natív
WebView végrehajtási smoke tesztje, a tiszta felhasználói gépre történő telepítés és az emberi vizuális
átvétel külön ellenőrzés. A CI-artefaktumok a pontos forráscommitjukhoz tartoznak.

Az első futtató a szolgáltatás gazdagépén hajt végre. A többgépes kimenő ügynökök,
feltételes/párhuzamos gráfok, újrapróbálkozás, rollback, aláírt kiadások, felügyelet nélküli jogosultságemelés,
tetszőleges reverse proxy TLS-terminálás és széles Linux-disztribúciós csomagolás
kívül esik ezen a szállításon. A meglévő forrás-CLI/legacy kompatibilitás megmarad;
a hordozható management disztribúció csak a natív motort tartalmazza.
