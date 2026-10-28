<!-- documentation-anchors:start -->
<a id="doc-implementation-tasks-and-project-analysis"></a>
<!-- documentation-anchors:end -->
# Megvalósítási feladatok és projektelemzés

<!-- documentation-navigation -->
[English](implementation-tasks.md) | [Magyar](implementation-tasks-hu.md) · [Dokumentáció](README-hu.md) · [Projekt](../README-hu.md)
<!-- /documentation-navigation -->

> 2026-09-14: a natív csomag-/futtatókörnyezet-refaktor megvalósult. Lásd a [futtatókörnyezet állapotát](powershell-standards-implementation-plan-hu.md) és a [teszteket](../tests/README-hu.md). Az alábbi történetlista a tágabb történeti útiterv; nem állítja, hogy minden régi lépés vagy a GUI migrálva lett.


<!-- documentation-anchors:start -->
<a id="doc-project-overview"></a>
<!-- documentation-anchors:end -->
## A projekt áttekintése
A Plot Manager átfogó PowerShell-alapú automatizációs keretrendszer üzemeltetési feladatkezeléshez és telepítésvezérléshez. Eredetileg SenseNet CMS-telepítésekhez készült, majd általános automatizációs platformmá fejlődött, amely sokféle üzemeltetési munkafolyamatot képes kezelni, beleértve a konténeres telepítéseket, felhőautomatizációt és vállalati alkalmazás-életciklus-kezelést.

<!-- documentation-anchors:start -->
<a id="doc-story-driven-development-progress"></a>
<!-- documentation-anchors:end -->
## Történetvezérelt fejlesztési előrehaladás

<!-- documentation-anchors:start -->
<a id="doc-completed-stories"></a>
<!-- documentation-anchors:end -->
### Befejezett történetek

<!-- documentation-anchors:start -->
<a id="doc-story-01---foundation-transformation-"></a>
<!-- documentation-anchors:end -->
#### Story 01 - Az alapok átalakítása ✅
**Cél**: A projekt átalakítása általános célú Plot Managerré megfelelő dokumentációval és licenceléssel
**Állapot**: 100%-ban kész
- [x] A projektstruktúra és architektúra elemzése
- [x] A develop és master ágak összehasonlítása
- [x] Feature ág létrehozása: feature/foundation-improvements
- [x] A README átírása Plot Manager automatizációs keretrendszerként
- [x] A licenc egységesítése MIT-re minden komponensben
- [x] A docs/settings.md angolra fordítása és modernizálása
- [x] A GUI package.json márkanevének frissítése "plot-manager-gui" értékre
- [x] Az alapfejlesztések commitolása (ddf76c38)
- [x] A projektáttekintés hivatkozásainak frissítése Plot Managerre
- [x] Történetvezérelt fejlesztéskövetési rendszer létrehozása

<!-- documentation-anchors:start -->
<a id="doc-in-progress-stories"></a>
<!-- documentation-anchors:end -->
### Folyamatban lévő történetek

<!-- documentation-anchors:start -->
<a id="doc-story-03---powershell-code-standardization-"></a>
<!-- documentation-anchors:end -->
#### Story 03 - PowerShell-kód egységesítése 🚧
**Cél**: A kódformázás, modern gyakorlatok és hibakezelés egységesítése
**Prioritás**: Magas - A megbízható automatizáció alapja
**Ráfordítás**: Közepes (1 hét)
- [ ] A jelenlegi PowerShell-kódbázis következetlenségeinek elemzése (feature/powershell-standardization ág)
- [ ] PowerShell-kódolási szabványok dokumentumának definiálása
- [ ] PSScriptAnalyzer-szabályok és konfiguráció megvalósítása
- [ ] Függvényelnevezési konvenciók egységesítése (Verb-Noun minta)
- [ ] Minden függvény frissítése megfelelő [CmdletBinding] attribútumokkal
- [ ] Paraméterdefiníciók és validáció egységesítése
- [ ] Következetes hibakezelési minták megvalósítása
- [ ] Átfogó súgódokumentáció hozzáadása a függvényekhez
- [ ] Változóelnevezési konvenciók frissítése
- [ ] Elavult PowerShell-szintaxis eltávolítása
- [ ] Strukturált naplózás megvalósítása súlyossági szintekkel
- [ ] Kódreview-ellenőrzőlista létrehozása a jövőbeli változtatásokhoz

<!-- documentation-anchors:start -->
<a id="doc-planned-stories"></a>
<!-- documentation-anchors:end -->
### Tervezett történetek

<!-- documentation-anchors:start -->
<a id="doc-story-02---angular-frontend-modernization"></a>
<!-- documentation-anchors:end -->
#### Story 02 - Angular frontend modernizálása
**Cél**: Angular 5 frissítése a legújabb verzióra (15+) modern függőségekkel és biztonsággal
**Prioritás**: Magas - Kritikus a biztonság és karbantarthatóság szempontjából
**Ráfordítás**: Nagy (1-2 hét)
- [ ] A jelenlegi Angular 5 kódbázis és függőségek auditja
- [ ] Migrációs stratégia tervezése Angular 5-ről Angular 15+-ra
- [ ] package.json frissítése modern Angularra és függőségekre
- [ ] Az elavult @angular/http migrálása HttpClientre
- [ ] Komponensszintaxis és életciklushookok frissítése
- [ ] Az elavult ng2-toastr cseréje modern értesítési rendszerre
- [ ] Bootstrap frissítése v4-ről v5+-ra modern rácsrendszerrel
- [ ] Modern Angular routing és lazy loading megvalósítása
- [ ] TypeScript strict módnak való megfelelés hozzáadása
- [ ] Build- és fejlesztői scriptek frissítése
- [ ] Minden GUI-funkció tesztelése migráció után
- [ ] Az új fejlesztői környezet dokumentációjának frissítése

<!-- documentation-anchors:start -->
<a id="doc-story-04---comprehensive-testing-framework"></a>
<!-- documentation-anchors:end -->
#### Story 04 - Átfogó tesztelési keretrendszer
**Cél**: Automatizált tesztelés megvalósítása PowerShell-scriptekhez és Angular frontendhez
**Prioritás**: Magas - Kritikus a megbízhatóság szempontjából
**Ráfordítás**: Nagy (1-2 hét)
- [ ] Pester tesztelési keretrendszer beállítása PowerShell-scriptekhez
- [ ] Egységtesztek létrehozása az alap PowerShell-függvényekhez
- [ ] Mock keretrendszerek megvalósítása külső függőségekhez
- [ ] Angular-egységtesztek hozzáadása komponensekhez és szolgáltatásokhoz
- [ ] Integrációs tesztek létrehozása adatbázis-műveletekhez
- [ ] Teljes plotok végponttól végpontig tartó tesztjeinek fejlesztése
- [ ] Tesztadatkezelés és takarítás beállítása
- [ ] GitHub Actions- vagy Azure DevOps-pipeline konfigurálása
- [ ] Automatizált tesztvégrehajtás megvalósítása PR/commit esetén
- [ ] Kódlefedettség-jelentések hozzáadása
- [ ] Tesztelési dokumentáció és irányelvek létrehozása
- [ ] Teljesítménytesztelés beállítása nagy telepítésekhez

<!-- documentation-anchors:start -->
<a id="doc-story-05---enhanced-security-and-authentication"></a>
<!-- documentation-anchors:end -->
#### Story 05 - Fejlettebb biztonság és hitelesítés
**Cél**: Szerepköralapú hozzáférés, biztonságos hitelesítőadatok és auditnaplózás megvalósítása
**Prioritás**: Közepes - Fontos a vállalati bevezetéshez
**Ráfordítás**: Nagy (2 hét)
- [ ] Felhasználói szerepkör- és jogosultságrendszer tervezése
- [ ] Hitelesítés megvalósítása az Angular frontendben
- [ ] JWT-tokenalapú API-hitelesítés hozzáadása
- [ ] Windows Credential Manager integrálása biztonságos tároláshoz
- [ ] Azure Key Vault támogatás hozzáadása felhőtelepítésekhez
- [ ] Átfogó auditnaplózás megvalósítása
- [ ] Biztonsági fejlécek és HTTPS-kikényszerítés hozzáadása
- [ ] Biztonságos konfigurációfájl-titkosítás létrehozása
- [ ] Bemenetvalidáció és szanitizálás megvalósítása
- [ ] Biztonsági szkennelés hozzáadása a CI/CD-pipeline-hoz
- [ ] Biztonsági dokumentáció és irányelvek létrehozása
- [ ] Munkamenet-kezelés és időtúllépés megvalósítása

<!-- documentation-anchors:start -->
<a id="doc-story-06---docker-orchestration-and-container-management"></a>
<!-- documentation-anchors:end -->
#### Story 06 - Docker-vezérlés és konténerkezelés
**Cél**: Fejlettebb Docker-támogatás vezérléssel és Kubernetesszel
**Prioritás**: Közepes - A meglévő Docker-képességekre épít
**Ráfordítás**: Közepes (1 hét)
- [ ] Docker Compose-fájlok létrehozása több szolgáltatásos forgatókönyvekhez
- [ ] Kubernetes-telepítési manifesztek fejlesztése
- [ ] Helm chartok létrehozása Kubernetes-telepítésekhez
- [ ] Konténerállapot-ellenőrzések és készenléti próbák megvalósítása
- [ ] Konténermonitorozás hozzáadása Prometheus/Grafana használatával
- [ ] Automatizált konténerimage-build beállítása
- [ ] Konténerregistry-integráció megvalósítása (Docker Hub/ACR)
- [ ] Konténerhálózat- és service mesh támogatás hozzáadása
- [ ] Konténerbiztonsági szkennelés létrehozása
- [ ] Gördülő frissítések és blue-green telepítések megvalósítása
- [ ] Konténernapló-aggregáció és -kezelés hozzáadása
- [ ] Konténertelepítési minták dokumentálása

<!-- documentation-anchors:start -->
<a id="doc-story-07---cloud-platform-integration"></a>
<!-- documentation-anchors:end -->
#### Story 07 - Felhőplatform-integráció
**Cél**: AWS- és Google Cloud-támogatás hozzáadása a meglévő Azure-integráció mellé
**Prioritás**: Közepes - Többfelhős rugalmasság
**Ráfordítás**: Nagy (2 hét)
- [ ] AWS PowerShell-modulintegráció megvalósítása
- [ ] CloudFormation-sablonok létrehozása AWS-telepítésekhez
- [ ] AWS CDK támogatás hozzáadása infrastruktúra-kódként kezeléshez
- [ ] Google Cloud PowerShell-cmdletek megvalósítása
- [ ] Google Cloud Deployment Manager-sablonok létrehozása
- [ ] Terraform-támogatás hozzáadása többfelhős infrastruktúrához
- [ ] Felhőnatív adatbázis-szolgáltatások integrálása
- [ ] Felhőtárhely-automatizáció megvalósítása
- [ ] Felhőmonitorozás és riasztásbeállítás hozzáadása
- [ ] Felhőköltség-optimalizálási stratégiák létrehozása
- [ ] Felhőbiztonsági bevált gyakorlatok megvalósítása
- [ ] Többfelhős failover és katasztrófa-helyreállítás hozzáadása

<!-- documentation-anchors:start -->
<a id="doc-story-08---monitoring-and-observability-platform"></a>
<!-- documentation-anchors:end -->
#### Story 08 - Monitorozási és megfigyelhetőségi platform
**Cél**: Átfogó naplózás, monitorozás és teljesítményinformációk
**Prioritás**: Közepes - Üzemeltetési kiválóság
**Ráfordítás**: Közepes (1 hét)
- [ ] Központosított naplózási infrastruktúra beállítása (ELK/EFK stack)
- [ ] Strukturált naplózás megvalósítása PowerShell-scriptekben
- [ ] Alkalmazásteljesítmény-monitorozási (APM) integráció hozzáadása
- [ ] Egyedi metrikák és KPI-k létrehozása automatizációs munkafolyamatokhoz
- [ ] Infrastruktúra-monitorozás megvalósítása (CPU, memória, lemez, hálózat)
- [ ] Riasztási szabályok és értesítési csatornák beállítása
- [ ] Monitorozási dashboardok létrehozása Grafanával vagy hasonló eszközzel
- [ ] Elosztott trace-elés megvalósítása összetett telepítésekhez
- [ ] Naplókorrelációs és elemzési képességek hozzáadása
- [ ] Automatizált incidensreakciós munkafolyamatok létrehozása
- [ ] Monitorozás-kódként megvalósítása verziókezeléssel
- [ ] Kapacitástervezés és trendelemzés hozzáadása

<!-- documentation-anchors:start -->
<a id="doc-story-09---plugin-architecture-and-extensibility"></a>
<!-- documentation-anchors:end -->
#### Story 09 - Pluginarchitektúra és bővíthetőség
**Cél**: Külső bővítmények engedélyezése az alapkód módosítása nélkül
**Prioritás**: Alacsony - Hosszú távú ökoszisztéma-növekedés
**Ráfordítás**: Nagy (2 hét)
- [ ] Pluginarchitektúra és interfészek tervezése
- [ ] Plugin-alaposztályok és szerződések létrehozása
- [ ] Pluginfelderítő és -betöltő rendszer megvalósítása
- [ ] Pluginéletciklus-kezelés hozzáadása (telepítés, engedélyezés, tiltás, eltávolítás)
- [ ] Pluginfejlesztő SDK és eszközök létrehozása
- [ ] Pluginverziózás és függőségfeloldás megvalósítása
- [ ] Pluginbiztonsági validáció és sandbox hozzáadása
- [ ] Pluginsablonok létrehozása gyakori forgatókönyvekhez
- [ ] Plugindokumentáció és oktatóanyagok fejlesztése
- [ ] Pluginpiactér vagy -regiszter megvalósítása
- [ ] Plugintesztelési és -validációs keretrendszer hozzáadása
- [ ] Bemutató mintapluginok létrehozása

<!-- documentation-anchors:start -->
<a id="doc-story-10---configuration-management-enhancement"></a>
<!-- documentation-anchors:end -->
#### Story 10 - Konfigurációkezelés fejlesztése
**Cél**: Fejlett konfigurációvalidáció, sablonkezelés és eltérésészlelés
**Prioritás**: Alacsony - Használhatósági fejlesztések
**Ráfordítás**: Közepes (1 hét)
- [ ] JSON-sémák létrehozása konfigurációvalidációhoz
- [ ] Konfigurációvalidáció megvalósítása az indulási folyamatban
- [ ] Konfigurációsablon-rendszer tervezése
- [ ] Konfigurációváltozók és behelyettesítés támogatásának hozzáadása
- [ ] Konfigurációöröklési hierarchiák megvalósítása
- [ ] Környezetek közötti továbbemelési munkafolyamatok létrehozása
- [ ] Konfiguráció-diff és összehasonlító eszközök hozzáadása
- [ ] Konfigurációeltérés-észlelés megvalósítása
- [ ] Konfigurációmentési és visszaállítási képességek hozzáadása
- [ ] Érzékeny konfigurációs adatok titkosítása
- [ ] Konfigurációdokumentáció-generátor létrehozása
- [ ] Konfigurációtesztelés és -validáció megvalósítása
