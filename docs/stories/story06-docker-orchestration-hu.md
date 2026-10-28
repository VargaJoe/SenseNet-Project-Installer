<!-- documentation-anchors:start -->
<a id="doc-story-06---docker-orchestration-and-container-management"></a>
<!-- documentation-anchors:end -->
# Story 06 - Docker-vezérlés és konténerkezelés

<!-- documentation-navigation -->
[English](story06-docker-orchestration.md) | [Magyar](story06-docker-orchestration-hu.md) · [Dokumentáció](../README-hu.md) · [Projekt](../../README-hu.md)
<!-- /documentation-navigation -->

<!-- documentation-anchors:start -->
<a id="doc-overview"></a>
<!-- documentation-anchors:end -->
## Áttekintés
A Docker-támogatás bővítése átfogó konténervezérléssel, Docker Compose-konfigurációkkal és fejlett konténeres telepítési forgatókönyvekkel.

<!-- documentation-anchors:start -->
<a id="doc-goals"></a>
<!-- documentation-anchors:end -->
## Célok
- Docker Compose-vezérlés megvalósítása több szolgáltatásos telepítésekhez
- Kubernetes-telepítési támogatás hozzáadása
- Konténerhálózat és szolgáltatásfelderítés javítása
- Konténermonitorozás és állapotellenőrzések biztosítása

<!-- documentation-anchors:start -->
<a id="doc-acceptance-criteria"></a>
<!-- documentation-anchors:end -->
## Elfogadási feltételek
- Docker Compose-konfigurációk fejlesztéshez és éles környezethez
- Kubernetes-telepítési manifesztek és Helm chartok
- Konténerállapot-ellenőrzések és monitorozás
- Fejlett hálózatkezelés szolgáltatásfelderítéssel
- Konténerregistry-integráció
- Automatizált konténerimage-build és -telepítés

<!-- documentation-anchors:start -->
<a id="doc-tasks"></a>
<!-- documentation-anchors:end -->
## Feladatok
- Docker Compose-fájlok létrehozása több szolgáltatásos forgatókönyvekhez
- Kubernetes-telepítési manifesztek fejlesztése
- Helm chartok létrehozása Kubernetes-telepítésekhez
- Konténerállapot-ellenőrzések és készenléti próbák megvalósítása
- Konténermonitorozás hozzáadása Prometheus/Grafana használatával
- Automatizált konténerimage-build beállítása
- Konténerregistry-integráció megvalósítása (Docker Hub/ACR)
- Konténerhálózat- és service mesh támogatás hozzáadása
- Konténerbiztonsági szkennelés létrehozása
- Gördülő frissítések és blue-green telepítések megvalósítása
- Konténernapló-aggregáció és -kezelés hozzáadása
- Konténertelepítési minták dokumentálása

<!-- documentation-anchors:start -->
<a id="doc-business-value"></a>
<!-- documentation-anchors:end -->
## Üzleti érték
- Modern konténeres telepítési képességek
- Skálázható és megbízható felhőnatív architektúra
- Jobb egyezés a fejlesztői és éles környezet között
- Jobb üzemeltetési hatékonyság

<!-- documentation-anchors:start -->
<a id="doc-dependencies"></a>
<!-- documentation-anchors:end -->
## Függőségek
- Story 01 (Az alapozás biztosítja az alap Docker-képességeket)
- Story 04 (A tesztelés validálja a konténeres telepítéseket)

<!-- documentation-anchors:start -->
<a id="doc-estimated-effort"></a>
<!-- documentation-anchors:end -->
## Becsült ráfordítás
Közepes (1 hét) - A meglévő Docker-alapokra építve

<!-- documentation-anchors:start -->
<a id="doc-status"></a>
<!-- documentation-anchors:end -->
## Állapot
Tervezett
