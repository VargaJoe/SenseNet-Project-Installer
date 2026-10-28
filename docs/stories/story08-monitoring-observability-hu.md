<!-- documentation-anchors:start -->
<a id="doc-story-08---monitoring-and-observability-platform"></a>
<!-- documentation-anchors:end -->
# Story 08 - Monitorozási és megfigyelhetőségi platform

<!-- documentation-navigation -->
[English](story08-monitoring-observability.md) | [Magyar](story08-monitoring-observability-hu.md) · [Dokumentáció](../README-hu.md) · [Projekt](../../README-hu.md)
<!-- /documentation-navigation -->

<!-- documentation-anchors:start -->
<a id="doc-overview"></a>
<!-- documentation-anchors:end -->
## Áttekintés
Átfogó monitorozási, naplózási és megfigyelhetőségi funkciók megvalósítása, amelyek részletes betekintést adnak a Plot Manager műveleteibe és a telepítések állapotába.

<!-- documentation-anchors:start -->
<a id="doc-goals"></a>
<!-- documentation-anchors:end -->
## Célok
- Központosított naplózás és naplóaggregáció
- Alkalmazásteljesítmény-monitorozás (APM)
- Infrastruktúra-monitorozás és riasztás
- Elosztott trace-elés összetett munkafolyamatokhoz

<!-- documentation-anchors:start -->
<a id="doc-acceptance-criteria"></a>
<!-- documentation-anchors:end -->
## Elfogadási feltételek
- Központosított naplózás ELK stackkel vagy hasonlóval
- Alkalmazásteljesítmény-monitorozási integráció
- Infrastruktúra-monitorozás metrikákkal és riasztással
- Elosztott trace-elés a teljes munkafolyamat átláthatóságához
- Egyedi dashboardok és jelentések
- Automatizált incidensreakció és értesítések

<!-- documentation-anchors:start -->
<a id="doc-tasks"></a>
<!-- documentation-anchors:end -->
## Feladatok
- Központosított naplózási infrastruktúra beállítása (ELK/EFK stack)
- Strukturált naplózás megvalósítása PowerShell-scriptekben
- Alkalmazásteljesítmény-monitorozási (APM) integráció hozzáadása
- Egyedi metrikák és KPI-k létrehozása automatizációs munkafolyamatokhoz
- Infrastruktúra-monitorozás megvalósítása (CPU, memória, lemez, hálózat)
- Riasztási szabályok és értesítési csatornák beállítása
- Monitorozási dashboardok létrehozása Grafanával vagy hasonló eszközzel
- Elosztott trace-elés megvalósítása összetett telepítésekhez
- Naplókorrelációs és elemzési képességek hozzáadása
- Automatizált incidensreakciós munkafolyamatok létrehozása
- Monitorozás-kódként megvalósítása verziókezeléssel
- Kapacitástervezés és trendelemzés hozzáadása

<!-- documentation-anchors:start -->
<a id="doc-business-value"></a>
<!-- documentation-anchors:end -->
## Üzleti érték
- Proaktív hibafelismerés és -megoldás
- Jobb üzemeltetési átláthatóság és információk
- Gyorsabb hibaelhárítás és hibakeresés
- Adatalapú optimalizálási lehetőségek

<!-- documentation-anchors:start -->
<a id="doc-dependencies"></a>
<!-- documentation-anchors:end -->
## Függőségek
- Story 06 (A konténervezérlés lehetővé teszi a modern monitorozást)
- Story 07 (A felhőplatformok monitorozási szolgáltatásokat biztosítanak)

<!-- documentation-anchors:start -->
<a id="doc-estimated-effort"></a>
<!-- documentation-anchors:end -->
## Becsült ráfordítás
Közepes (1 hét) - Meglévő monitorozási megoldások felhasználása

<!-- documentation-anchors:start -->
<a id="doc-status"></a>
<!-- documentation-anchors:end -->
## Állapot
Tervezett
