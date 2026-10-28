<!-- documentation-anchors:start -->
<a id="doc-story-04---comprehensive-testing-framework"></a>
<!-- documentation-anchors:end -->
# Story 04 - Átfogó tesztelési keretrendszer

<!-- documentation-navigation -->
[English](story04-testing-framework.md) | [Magyar](story04-testing-framework-hu.md) · [Dokumentáció](../README-hu.md) · [Projekt](../../README-hu.md)
<!-- /documentation-navigation -->

<!-- documentation-anchors:start -->
<a id="doc-overview"></a>
<!-- documentation-anchors:end -->
## Áttekintés
Átfogó tesztelési keretrendszer megvalósítása PowerShell-scriptekhez, Angular frontendhez, integrációs tesztekhez és automatizált CI/CD-validációhoz.

<!-- documentation-anchors:start -->
<a id="doc-goals"></a>
<!-- documentation-anchors:end -->
## Célok
- Automatizált tesztelés kialakítása PowerShell automatizációs scriptekhez
- Angular-egységtesztek és integrációs tesztek megvalósítása
- Végponttól végpontig tartó tesztelés létrehozása teljes munkafolyamatokhoz
- Folyamatos integrációs pipeline beállítása

<!-- documentation-anchors:start -->
<a id="doc-acceptance-criteria"></a>
<!-- documentation-anchors:end -->
## Elfogadási feltételek
- PowerShell-egységtesztek Pester keretrendszerrel
- Angular-egységtesztek jó lefedettséggel (>80%)
- Integrációs tesztek a fő automatizációs munkafolyamatokhoz
- Végponttól végpontig tartó tesztek teljes telepítési forgatókönyvekhez
- CI/CD-pipeline automatizált teszteléssel
- Tesztjelentések és lefedettségi metrikák

<!-- documentation-anchors:start -->
<a id="doc-tasks"></a>
<!-- documentation-anchors:end -->
## Feladatok
- Pester tesztelési keretrendszer beállítása PowerShell-scriptekhez
- Egységtesztek létrehozása az alap PowerShell-függvényekhez
- Mock keretrendszerek megvalósítása külső függőségekhez
- Angular-egységtesztek hozzáadása komponensekhez és szolgáltatásokhoz
- Integrációs tesztek létrehozása adatbázis-műveletekhez
- Teljes plotok végponttól végpontig tartó tesztjeinek fejlesztése
- Tesztadatkezelés és takarítás beállítása
- GitHub Actions- vagy Azure DevOps-pipeline konfigurálása
- Automatizált tesztvégrehajtás megvalósítása PR/commit esetén
- Kódlefedettség-jelentések hozzáadása
- Tesztelési dokumentáció és irányelvek létrehozása
- Teljesítménytesztelés beállítása nagy telepítésekhez

<!-- documentation-anchors:start -->
<a id="doc-business-value"></a>
<!-- documentation-anchors:end -->
## Üzleti érték
- A telepítések nagyobb megbízhatósága és biztonsága
- Gyorsabb fejlesztési ciklusok automatizált validációval
- Kevesebb kézi tesztelési ráfordítás
- Regressziók korai felismerése

<!-- documentation-anchors:start -->
<a id="doc-dependencies"></a>
<!-- documentation-anchors:end -->
## Függőségek
- Story 03 (Az egységes kód megkönnyíti a tesztelést)

<!-- documentation-anchors:start -->
<a id="doc-estimated-effort"></a>
<!-- documentation-anchors:end -->
## Becsült ráfordítás
Nagy (1-2 hét) - Átfogó tesztelési környezet kialakítása több technológián

<!-- documentation-anchors:start -->
<a id="doc-status"></a>
<!-- documentation-anchors:end -->
## Állapot
Tervezett
