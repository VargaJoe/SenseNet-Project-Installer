<!-- documentation-anchors:start -->
<a id="doc-story-07---cloud-platform-integration"></a>
<!-- documentation-anchors:end -->
# Story 07 - Felhőplatform-integráció

<!-- documentation-navigation -->
[English](story07-cloud-platform-integration.md) | [Magyar](story07-cloud-platform-integration-hu.md) · [Dokumentáció](../README-hu.md) · [Projekt](../../README-hu.md)
<!-- /documentation-navigation -->

<!-- documentation-anchors:start -->
<a id="doc-overview"></a>
<!-- documentation-anchors:end -->
## Áttekintés
A felhőplatform-támogatás bővítése az Azure-on túl AWS-re, Google Cloudra és többfelhős telepítési forgatókönyvekre fejlett felhőnatív funkciókkal.

<!-- documentation-anchors:start -->
<a id="doc-goals"></a>
<!-- documentation-anchors:end -->
## Célok
- AWS-telepítésautomatizálási támogatás hozzáadása
- Google Cloud Platform-integráció megvalósítása
- Többfelhős telepítési stratégiák támogatása
- Felhőnatív szolgáltatások integrálása (adatbázisok, tárhely, monitorozás)

<!-- documentation-anchors:start -->
<a id="doc-acceptance-criteria"></a>
<!-- documentation-anchors:end -->
## Elfogadási feltételek
- AWS-telepítésautomatizálás CloudFormation/CDK használatával
- Google Cloud-telepítés Deployment Manager/Terraform használatával
- Többfelhős konfiguráció- és telepítéstámogatás
- Felhőnatív adatbázis-integráció (RDS, Cloud SQL stb.)
- Felhőtárhely-integráció (S3, Azure Blob, GCS)
- Felhőmonitorozás- és riasztásintegráció

<!-- documentation-anchors:start -->
<a id="doc-tasks"></a>
<!-- documentation-anchors:end -->
## Feladatok
- AWS PowerShell-modulintegráció megvalósítása
- CloudFormation-sablonok létrehozása AWS-telepítésekhez
- AWS CDK támogatás hozzáadása infrastruktúra-kódként kezeléshez
- Google Cloud PowerShell-cmdletek megvalósítása
- Google Cloud Deployment Manager-sablonok létrehozása
- Terraform-támogatás hozzáadása többfelhős infrastruktúrához
- Felhőnatív adatbázis-szolgáltatások integrálása
- Felhőtárhely-automatizáció megvalósítása
- Felhőmonitorozás és riasztásbeállítás hozzáadása
- Felhőköltség-optimalizálási stratégiák létrehozása
- Felhőbiztonsági bevált gyakorlatok megvalósítása
- Többfelhős failover és katasztrófa-helyreállítás hozzáadása

<!-- documentation-anchors:start -->
<a id="doc-business-value"></a>
<!-- documentation-anchors:end -->
## Üzleti érték
- Szállítófüggetlenség és rugalmasság
- A felhőnatív architektúra előnyei
- Globális telepítési képességek
- Jobb ellenálló képesség és katasztrófa-helyreállítás

<!-- documentation-anchors:start -->
<a id="doc-dependencies"></a>
<!-- documentation-anchors:end -->
## Függőségek
- Story 01 (Alapozás meglévő Azure-támogatással)
- Story 06 (A konténervezérlés támogatja a felhőtelepítéseket)

<!-- documentation-anchors:start -->
<a id="doc-estimated-effort"></a>
<!-- documentation-anchors:end -->
## Becsült ráfordítás
Nagy (2 hét) - Több felhőplatform integrációja

<!-- documentation-anchors:start -->
<a id="doc-status"></a>
<!-- documentation-anchors:end -->
## Állapot
Tervezett
