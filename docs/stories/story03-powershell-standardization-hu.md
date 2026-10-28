<!-- documentation-anchors:start -->
<a id="doc-story-03---powershell-code-standardization"></a>
<!-- documentation-anchors:end -->
# Story 03 - PowerShell-kód egységesítése

<!-- documentation-navigation -->
[English](story03-powershell-standardization.md) | [Magyar](story03-powershell-standardization-hu.md) · [Dokumentáció](../README-hu.md) · [Projekt](../../README-hu.md)
<!-- /documentation-navigation -->

<!-- documentation-anchors:start -->
<a id="doc-overview"></a>
<!-- documentation-anchors:end -->
## Áttekintés
A PowerShell-kódbázis egységesítése következetes formázással, modern gyakorlatokkal, hibakezeléssel és az elavult minták eltávolításával az automatizációs scriptekben.

<!-- documentation-anchors:start -->
<a id="doc-goals"></a>
<!-- documentation-anchors:end -->
## Célok
- Következetes kódformázás megvalósítása minden PowerShell-scriptben
- PowerShell-szintaxis és bevált gyakorlatok modernizálása
- Hibakezelés és naplózás javítása
- Elavult minták eltávolítása és karbantarthatóság javítása

<!-- documentation-anchors:start -->
<a id="doc-acceptance-criteria"></a>
<!-- documentation-anchors:end -->
## Elfogadási feltételek
- Következetes kódformázás alkalmazva minden PowerShell-fájlra
- Modern PowerShell-szintaxis bevezetve (az örökölt minták kerülésével)
- Egységes hibakezelés megfelelő try/catch blokkokkal
- Következetes paramétervalidáció és dokumentáció
- Javított naplózás strukturált kimenettel
- Kódelemzési szabályok megvalósítva, ellenőrzésük sikeres

<!-- documentation-anchors:start -->
<a id="doc-tasks"></a>
<!-- documentation-anchors:end -->
## Feladatok
- A jelenlegi PowerShell-kódbázis következetlenségeinek elemzése
- PowerShell-kódolási szabványok dokumentumának definiálása
- PSScriptAnalyzer-szabályok és konfiguráció megvalósítása
- Függvényelnevezési konvenciók egységesítése (Verb-Noun minta)
- Minden függvény frissítése megfelelő [CmdletBinding] attribútumokkal
- Paraméterdefiníciók és validáció egységesítése
- Következetes hibakezelési minták megvalósítása
- Átfogó súgódokumentáció hozzáadása a függvényekhez
- Változóelnevezési konvenciók frissítése
- Elavult PowerShell-szintaxis eltávolítása
- Strukturált naplózás megvalósítása súlyossági szintekkel
- Kódreview-ellenőrzőlista létrehozása a jövőbeli változtatásokhoz

<!-- documentation-anchors:start -->
<a id="doc-business-value"></a>
<!-- documentation-anchors:end -->
## Üzleti érték
- Jobb kódkarbantarthatóság és olvashatóság
- Rövidebb hibakeresési idő jobb hibakezeléssel
- Könnyebb betanulás új fejlesztőknek
- Megbízhatóbb automatizált végrehajtás

<!-- documentation-anchors:start -->
<a id="doc-dependencies"></a>
<!-- documentation-anchors:end -->
## Függőségek
- Story 01 (Az alapozás stabil alapot biztosít a refaktorhoz)

<!-- documentation-anchors:start -->
<a id="doc-estimated-effort"></a>
<!-- documentation-anchors:end -->
## Becsült ráfordítás
Közepes (1 hét) - Rendszeres refaktor több scriptfájlban

<!-- documentation-anchors:start -->
<a id="doc-status"></a>
<!-- documentation-anchors:end -->
## Állapot
Tervezett
