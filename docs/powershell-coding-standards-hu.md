<!-- documentation-anchors:start -->
<a id="doc-powershell-conventions"></a>
<!-- documentation-anchors:end -->
# PowerShell-konvenciók

<!-- documentation-navigation -->
[English](powershell-coding-standards.md) | [Magyar](powershell-coding-standards-hu.md) · [Dokumentáció](README-hu.md) · [Projekt](../README-hu.md)
<!-- /documentation-navigation -->

Ezek a konvenciók a natív futtatókörnyezetre és csomagokra vonatkoznak. A történeti AutoExt scriptek a kifejezett kompatibilitási futtató mögött maradnak.

- Támogasd a PowerShell 5.1-et és 7-et a motorhoz szükséges külső eszközök nélkül.
- Használj jóváhagyott Verb-Noun függvényneveket; a plotlépés-azonosítókat tartsd külön a függvénynevektől.
- Csak a csomagmanifesztben deklarált parancsokat exportáld.
- Validált Settings értéket és kis Context objektumot fogadj; kerüld a globális változókat.
- A sikercsatornán strukturált adatot adj vissza. Hiba esetén dobj kivételt.
- A natív futtatható fájlok kilépési kódját azonnal ellenőrizd, a hibákat alakítsd leállító hibává.
- Diagnosztikához használj Write-Verbose/Write-Information hívásokat. Konfigurációkat és hitelesítőadatokat soha ne írj ki.
- Az állapotmódosító parancsokat védd SupportsShouldProcess és valódi ShouldProcess hívással.
- A csomagimportot kizárólag definíciót betöltő műveletként kezeld.
- A csomagerőforrásokat a Context.PackageRoot, az operátori fájlútvonalakat a Context.WorkDirectory alapján oldd fel.
- A paramétertípusokat és alapértékeket a manifesztben definiáld. Jelenlét ellenőrzésére kerüld a false/zero igazságérték-vizsgálatokat.
- Őrizd meg a bemeneti beállításokat; független másolatokba fésülj, dokumentált tömb-/nullviselkedéssel.
- Adj teszteket a viselkedéshez, hibautakhoz, csomagizolációhoz és CLI-eredményekhez.
- Minden PowerShell-fájl maradjon parse-olható, beleértve a megtartott kompatibilitási fájlokat.

[Szerzői útmutató](custom-steps-hu.md) · [Beállítási szerződés](settings-hu.md) · [Tesztparancsok](../tests/README-hu.md)

A repository jelenleg függőségmentes futásidejű tesztcsomagot és parserellenőrzéseket használ. A PSScriptAnalyzer nincs becsomagolva; a csomagot nem szabad teljes analyzerellenőrzésként leírni.
