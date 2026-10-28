<!-- documentation-anchors:start -->
<a id="doc-runtime-refactor-status"></a>
<!-- documentation-anchors:end -->
# A futtatókörnyezet-refaktor állapota

<!-- documentation-navigation -->
[English](powershell-standards-implementation-plan.md) | [Magyar](powershell-standards-implementation-plan-hu.md) · [Dokumentáció](README-hu.md) · [Projekt](../README-hu.md)
<!-- /documentation-navigation -->

A natív futtatókörnyezet refaktorja megvalósult a feature/powershell-standardization ágon.

Leszállítva:
- Kifejezett csomagregiszter, ütközésfelismerés, függőségellenőrzés és elkülönített modulhívás.
- Validált hívásonkénti beállítások, mélymásolatos összefésülés, hivatkozások és forrásdiagnosztika.
- Ismételt lépéshívások külön bemenetekkel és azonosítókkal.
- CLI-tervezés, WhatIf, strukturált eredmények és kilépési kódok.
- Önállóan telepíthető text, filesystem és IIS csomagok.
- Külön folyamatos legacy belépési pont, a történeti munkafolyamatok megőrzésével.
- IIS-polling javítása, backup parser javítása és legacy false/zero felülírás javítása.
- Automatizált futásidejű tesztek PowerShell 5.1-hez és 7-hez, valamint CI-workflow.

A történeti AutoExt lépések a kifejezetten dokumentált javításokon kívül megtartják eredeti megvalósításukat. Nem importálódnak automatikusan az új regiszterbe. A régi GUI külön marad. Ezeket a határokat a [futtatókörnyezet architektúrája](plot-manager-runtime-hu.md) írja le.

A következő repositoryk közötti összehasonlítás csak e refaktor ellenőrzése után kezdődhet. Cégspecifikus konfigurációkat és Git-előzményeket nem szabad ebbe a repositoryba másolni.
