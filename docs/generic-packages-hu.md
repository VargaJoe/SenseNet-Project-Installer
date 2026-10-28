<!-- documentation-anchors:start -->
<a id="doc-general-purpose-packages"></a>
<!-- documentation-anchors:end -->
# Általános célú csomagok

<!-- documentation-navigation -->
[English](generic-packages.md) | [Magyar](generic-packages-hu.md) · [Dokumentáció](README-hu.md) · [Projekt](../README-hu.md)
<!-- /documentation-navigation -->

Ezek a natív csomagok explicit bemenetekkel és strukturált kimenetekkel dolgoznak. PowerShell/.NET és helyi fájlok használatára épülnek; nincs szükségük rendszergazdai jogosultságra, külső parancssori eszközökre, globális legacy beállításokra vagy alkalmazásspecifikus erőforrásokra. Minden csomagkönyvtár önállóan telepíthető.

<!-- documentation-anchors:start -->
<a id="doc-filesystem"></a>
<!-- documentation-anchors:end -->
## Fájlrendszer

| Lépés | Bemenetek | Kimenet |
| --- | --- | --- |
| filesystem.write | Path, Content (alapérték: üres), Overwrite (alapérték: false) | Path, Bytes |
| filesystem.copy | Source fájl, Destination fájl, Overwrite (alapérték: false) | Path, Bytes |
| filesystem.read | Path (UTF-8 szöveg) | Path, Content |
| filesystem.mkdir | Path | Path, Created |
| filesystem.copy-tree | Source könyvtár, Destination könyvtár, Overwrite (alapérték: false) | Path, Files |
| filesystem.remove | Path, Root, Recurse (alapérték: false), MissingOk (alapérték: false) | Path, Removed |
| filesystem.hash | Path | Path, Algorithm (SHA256), Hash (kisbetűs hexadecimális) |

Az útvonalak literálisak, nem helyettesítő karakteres kifejezések. A relatív útvonalak a WorkDirectory alapján oldódnak fel. Fájlíráshoz és másoláshoz a szülőkönyvtárnak már léteznie kell; létrehozásához használd a mkdir lépést.

A copy-tree a Source **tartalmát** másolja, a rejtett fájlokkal és üres könyvtárakkal együtt. A meglévő cél tartalmával összefésül, és nem törli az attól független fájlokat. A forrás és a cél nem fedheti át egymást, és mindkettőnek a fájlrendszer gyökere alatt kell lennie. Az összes ismert célütközést az első fájl másolása előtt ellenőrzi. A faműveletek elutasítják a linkeket/junctionöket. Ez tartalommásolás, nem ACL-ek, alternatív adatfolyamok vagy fájlrendszer-metaadatok biztonsági mentése.

A remove explicit Root értéket igényel. A Path-nak szigorúan ezen a gyökéren belül kell lennie; magát a Root értéket és az abból kilépő útvonalakat elutasítja. Nem üres könyvtáraknál Recurse szükséges. A MissingOk hiányzó cél esetén Removed=false értékkel tér vissza. A linkeken/junctionökön keresztüli bejárást elutasítja. Root-ként egy konkrét munkaterületet vagy kimeneti könyvtárat adj meg.

<!-- documentation-anchors:start -->
<a id="doc-zip-archives"></a>
<!-- documentation-anchors:end -->
## ZIP archívumok

| Lépés | Bemenetek | Kimenet |
| --- | --- | --- |
| archive.pack | Source könyvtár, Destination ZIP fájl, Overwrite (alapérték: false) | Path, Files, Bytes |
| archive.unpack | Source ZIP fájl, Destination könyvtár, Overwrite (alapérték: false) | Path, Files |

A pack a könyvtár tartalmát csomagolja, a rejtett fájlokkal és üres könyvtárakkal együtt. A ZIP-nek a Source könyvtáron kívül kell lennie, és a szülőkönyvtárának léteznie kell. A cél mellett ideiglenes fájlt ír, majd elérhetővé teszi a kész archívumot. Meglévő ZIP-fájlhoz explicit Overwrite szükséges.

Az unpack létrehozza a célkönyvtárat. Írás előtt ellenőrzi a bejegyzéseket és a célütközéseket: elutasítja a könyvtárból kilépő és abszolút útvonalakat, a linkeket, az ismétlődő célokat és a fájl-könyvtár ütközéseket. Meglévő fájlokhoz Overwrite szükséges; az egyéb célfájlok megmaradnak. Ez ZIP-támogatás, nem általános 7-Zip formátumkezelő burkolat.

Az ellenőrzés utáni I/O-hiba részleges kimenetet hagyhat másoláskor vagy kibontáskor. Ezek nem tranzakciós könyvtártelepítések. Megbízhatónak tekintett helyi fájlrendszerállapoton dolgoznak; nem jelentenek elkülönítési határt az egyidejű fájlrendszerváltozásokkal szemben.

<!-- documentation-anchors:start -->
<a id="doc-json"></a>
<!-- documentation-anchors:end -->
## JSON

| Lépés | Bemenetek | Kimenet |
| --- | --- | --- |
| json.read | Path | Path, Value |
| json.write | Path, Value (objektum), Overwrite (alapérték: false) | Path, Bytes |
| json.merge | Paths (fájlútvonalak nem üres, rendezett tömbje) | Paths, Value |

A JSON gyökerének objektumnak kell lennie. A kulcsok a PowerShell kis- és nagybetűt nem megkülönböztető leképezési szabályait követik. A merge sorrendben olvassa a fájlokat: az objektumok rekurzívan összefésülődnek, a tömbök teljesen lecserélődnek, az explicit null/false/zero pedig érték marad. Nem módosítja a bemeneti fájlokat, és nem értelmezi a bennük szereplő Plot Manager-direktívákat.

Mentéshez a merge kimenetét add át a json.write Value paraméterének. A write BOM nélküli UTF-8-at használ, és a cél módosítása előtt szerializál; a szülőkönyvtárnak már léteznie kell. Meglévő fájlokhoz Overwrite szükséges. Az írás a cél melletti ideiglenes fájlt használ, és csak sikeres szerializálás után cseréli le a célt.

A motor konfigurációs rétegei és a json.merge külön funkciók: a konfigurációs rétegek a futást határozzák meg; a json.merge futás közben tetszőleges, objektum alakú JSON-dokumentumokat dolgoz fel.

<!-- documentation-anchors:start -->
<a id="doc-xml"></a>
<!-- documentation-anchors:end -->
## XML

Az xml.set paraméterei: Source, Destination, XPath, Value, opcionális Namespaces (prefix–URI leképezés) és Overwrite (alapérték: false). A kimenete Path és Updated=1.

Az XPath-nak pontosan egy attribútumot vagy levélelemet kell kiválasztania. Az értékadás az XML API-n keresztül történik, ezért az XML-karakterek helyes escape-elést kapnak. Alapértelmezett XML-névtérnél adj prefixet a névtérhez a Namespaces értékében, és ezt használd az XPath-ban. A DTD-ket és külső entitásokat elutasítja. A cél szülőkönyvtárának léteznie kell. A Source helyben történő frissítéséhez Destination=Source és Overwrite=true szükséges.

Ez meglévő csomópontot frissít; nem hoz létre sémát, nem talál ki hiányzó csomópontokat, és nem végez teljes XML-dokumentumon szöveges cserét. A kimenet UTF-8; a szemantikai tartalmat és whitespace-t lehetőség szerint megtartja, de nem biztosít bájtazonos formázást.

<!-- documentation-anchors:start -->
<a id="doc-preview-and-composition"></a>
<!-- documentation-anchors:end -->
## Előnézet és összeállítás

A natív futtató WhatIf módja minden lépésfüggvényt kihagy. Minden módosító függvény ShouldProcess támogatást is megvalósít a közvetlen WhatIf hívásokhoz. A kimeneti hivatkozások korábban befejeződött hívásokra mutatnak; egy sikertelen lépés leállítja a plot hátralévő részét. Nincs automatikus visszaállítás vagy finally/takarítási fázis.

A csomagok nem naplózzák a dokumentumok tartalmát. A read/merge kimenetek szándékosan adatokat tartalmaznak, amelyeket a CLI szerializál; a megjelenített eredményekbe ne kerüljenek titkok.

<!-- documentation-anchors:start -->
<a id="doc-complete-local-example"></a>
<!-- documentation-anchors:end -->
## Teljes helyi példa

A példa három konfigurációs fájlt egyesít, JSON/XML fájlokat generál, előkészít egy könyvtárat, ZIP-et készít és állít vissza, két hash-t jelent, majd csak az előkészítési könyvtárat törli.

A repository gyökeréből **új** kimeneti könyvtárral futtasd:

~~~powershell
$example = './src/Deployment/Scripts/Examples/layered-artifact'
$work = Join-Path ([IO.Path]::GetTempPath()) ('plot-example-' + [guid]::NewGuid().ToString('N'))
$null = New-Item -ItemType Directory -Path $work
./src/Deployment/Scripts/Run.ps1 layered-artifact -DefaultConfigPath "$example/default.json" -ConfigPath "$example/project.json" -EnvironmentConfigPath "$example/environment.json" -WorkDirectory $work
~~~

Elvárt eredmény: Succeeded; a restored/report.json értékei Label=Example project, Environment=preview, Enabled=false, Iterations=0 és Formatting.Keep=inherited. Az originalHash és restoredHash kimenetek egyeznek. A kimenetben bundle-input/, restored/ és bundle.zip található; a staging/ siker esetén törlődik.

A rétegfájlok sorrendjének és a paraméterforrásoknak a vizsgálatához add hozzá az -Explain kapcsolót; a műveletek kihagyásához az -WhatIf kapcsolót. A generált könyvtár takarításához az útvonal ellenőrzése után használd a filesystem.remove lépést Path=$work, Root=[IO.Path]::GetTempPath() és Recurse=true értékekkel. Ugyanabban a kimeneti könyvtárban az ismételt futtatás a meglévő kimeneti fájlok miatt sikertelen lesz.

<!-- documentation-anchors:start -->
<a id="doc-migration-status"></a>
<!-- documentation-anchors:end -->
## Migrációs állapot

Ez az első csomagcsoport újrahasználható fájl-/könyvtár-, ZIP- és JSON/XML-műveleteket valósít meg natív csomagokként. Új általános szerződésekről van szó, nem a történeti telepítési függvények aliasairól. A legacy szkriptek továbbra is csak legacy módban érhetők el.

A következő általános csoport már része a rendszernek: [process, HTTP/TCP, Git, build/NuGet és Docker](operations-packages-hu.md). Az [SQL Server, IIS-létrehozás, webes karbantartás és Compose](platform-packages-hu.md) szintén elérhető natív lépésekként, [helyi GUI/integrációs szerződéssel](local-integration-hu.md). Az alkalmazásspecifikus telepítők, chartok, környezeti beállítások és adatok ezen a munkán kívül maradnak.
