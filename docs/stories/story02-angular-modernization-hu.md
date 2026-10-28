<!-- documentation-anchors:start -->
<a id="doc-story-02---angular-frontend-modernization"></a>
<!-- documentation-anchors:end -->
# Story 02 - Angular frontend modernizálása

<!-- documentation-navigation -->
[English](story02-angular-modernization.md) | [Magyar](story02-angular-modernization-hu.md) · [Dokumentáció](../README-hu.md) · [Projekt](../../README-hu.md)
<!-- /documentation-navigation -->

<!-- documentation-anchors:start -->
<a id="doc-overview"></a>
<!-- documentation-anchors:end -->
## Áttekintés
Az Angular 5 frontend frissítése a legújabb Angular-verzióra (15+) modern függőségekkel, javított biztonsággal és jobb felhasználói élménnyel.

<!-- documentation-anchors:start -->
<a id="doc-goals"></a>
<!-- documentation-anchors:end -->
## Célok
- Az Angular keretrendszer modernizálása az aktuális verzióra
- Minden függőség frissítése a legújabb stabil verzióra
- A UI/UX javítása modern tervezési mintákkal
- A biztonság és teljesítmény javítása

<!-- documentation-anchors:start -->
<a id="doc-acceptance-criteria"></a>
<!-- documentation-anchors:end -->
## Elfogadási feltételek
- Angular frissítve v5-ről v15+-ra (legújabb LTS)
- Minden függőség kompatibilis modern verzióra frissítve
- Buildfolyamat modern Angular CLI-re optimalizálva
- A UI modern Bootstrap 5+-szal és jobb reszponzív kialakítással frissítve
- Biztonsági sérülékenységek megoldva
- Teljesítményjavítások megvalósítva

<!-- documentation-anchors:start -->
<a id="doc-tasks"></a>
<!-- documentation-anchors:end -->
## Feladatok
- A jelenlegi Angular 5 kódbázis és függőségek auditja
- Migrációs stratégia tervezése Angular 5-ről Angular 15+-ra
- package.json frissítése modern Angularra és függőségekre
- Az elavult @angular/http migrálása HttpClientre
- Komponensszintaxis és életciklushookok frissítése
- Az elavult ng2-toastr cseréje modern értesítési rendszerre
- Bootstrap frissítése v4-ről v5+-ra modern rácsrendszerrel
- Modern Angular routing és lazy loading megvalósítása
- TypeScript strict módnak való megfelelés hozzáadása
- Build- és fejlesztői scriptek frissítése
- Minden GUI-funkció tesztelése migráció után
- Az új fejlesztői környezet dokumentációjának frissítése

<!-- documentation-anchors:start -->
<a id="doc-business-value"></a>
<!-- documentation-anchors:end -->
## Üzleti érték
- Jobb biztonság a legújabb keretrendszer-javításokkal
- Jobb fejlesztői élmény modern eszközökkel
- Jobb teljesítmény és felhasználói élmény
- Jövőálló technológiai stack

<!-- documentation-anchors:start -->
<a id="doc-dependencies"></a>
<!-- documentation-anchors:end -->
## Függőségek
- Story 01 (Az alapozó munka stabil alapot biztosít)

<!-- documentation-anchors:start -->
<a id="doc-estimated-effort"></a>
<!-- documentation-anchors:end -->
## Becsült ráfordítás
Nagy (1-2 hét) - Gondos migrációt igénylő jelentős keretrendszer-frissítés

<!-- documentation-anchors:start -->
<a id="doc-status"></a>
<!-- documentation-anchors:end -->
## Állapot
Tervezett
