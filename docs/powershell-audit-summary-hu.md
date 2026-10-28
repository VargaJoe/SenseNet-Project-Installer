<!-- documentation-anchors:start -->
<a id="doc-powershell-codebase-audit-summary"></a>
<!-- documentation-anchors:end -->
# A PowerShell-kódbázis auditjának összefoglalója

<!-- documentation-navigation -->
[English](powershell-audit-summary.md) | [Magyar](powershell-audit-summary-hu.md) · [Dokumentáció](README-hu.md) · [Projekt](../README-hu.md)
<!-- /documentation-navigation -->

<!-- documentation-anchors:start -->
<a id="doc-audit-date"></a>
<!-- documentation-anchors:end -->
## Az audit dátuma
2025-07-07

<!-- documentation-anchors:start -->
<a id="doc-scope"></a>
<!-- documentation-anchors:end -->
## Hatókör
Minden PowerShell-script a `src/Deployment/Scripts/` alatt

<!-- documentation-anchors:start -->
<a id="doc-key-findings"></a>
<!-- documentation-anchors:end -->
## Fő megállapítások

<!-- documentation-anchors:start -->
<a id="doc-1-function-naming"></a>
<!-- documentation-anchors:end -->
### 1. Függvényelnevezés
- Következetlen elnevezés: egyesek `Function fnName`, mások `function Verb-Noun` alakot használnak (az ajánlott PowerShell-stílus).
- Néhány függvény neve nem világos vagy nem leíró.

<!-- documentation-anchors:start -->
<a id="doc-2-cmdletbinding-usage"></a>
<!-- documentation-anchors:end -->
### 2. CmdletBinding használata
- A `[CmdletBinding()]` sok scriptben jelen van, de nem mindegyikben.
- Egyes függvényekből hiányoznak a fejlett függvényfunkciók (például paramétervalidáció, közös paraméterek).

<!-- documentation-anchors:start -->
<a id="doc-3-parameter-blocks"></a>
<!-- documentation-anchors:end -->
### 3. Paraméterblokkok
- A paraméterblokkok (`param(...)`) jelen vannak, de nem mindig egységesek.
- Egyes scriptek inline paramétereket, mások fejlett paraméterattribútumokat használnak.
- A kötelező/opcionális jelleg és a típusok megadása következetlen.

<!-- documentation-anchors:start -->
<a id="doc-4-error-handling"></a>
<!-- documentation-anchors:end -->
### 4. Hibakezelés
- A hibakezelésben a `throw` és a `Write-Verbose`/`Write-Error` is használatos.
- Nincs egységes hibakezelési minta.

<!-- documentation-anchors:start -->
<a id="doc-5-logging"></a>
<!-- documentation-anchors:end -->
### 5. Naplózás
- A naplózás következetlen: egyes scriptek `Write-Verbose`-t, mások egyedi naplózást vagy semmit sem használnak.
- Nincs strukturált naplózás vagy súlyossági szint.

<!-- documentation-anchors:start -->
<a id="doc-6-help-documentation"></a>
<!-- documentation-anchors:end -->
### 6. Súgódokumentáció
- Sok függvényből hiányzik a megjegyzésalapú súgó vagy használati példa.

<!-- documentation-anchors:start -->
<a id="doc-7-variable-naming"></a>
<!-- documentation-anchors:end -->
### 7. Változóelnevezés
- A változóelnevezés következetlen (camelCase, PascalCase és csupa kisbetű keveréke).
- Egyes globális változók nincsenek egyértelműen megjelölve.

<!-- documentation-anchors:start -->
<a id="doc-8-deprecated-syntax"></a>
<!-- documentation-anchors:end -->
### 8. Elavult szintaxis
- Kulcsszó alapján nem találtunk elavult PowerShell-szintaxist, de néhány örökölt minta létezhet.

<!-- documentation-anchors:start -->
<a id="doc-9-plotstep-structure"></a>
<!-- documentation-anchors:end -->
### 9. Plot-/lépésstruktúra
- A plotok és lépések nincsenek logikailag csoportosítva (például rendszer, Docker, Kubernetes stb.).
- Néhány lépés olyan extra paramétereket/beállításokat igényel, amelyek nem egységesek minden lépésben.

<!-- documentation-anchors:start -->
<a id="doc-recommendations"></a>
<!-- documentation-anchors:end -->
## Ajánlások
- Vezessünk be szigorú Verb-Noun elnevezési konvenciót minden függvényhez.
- Követeljünk meg `[CmdletBinding()]` attribútumot és fejlett paraméterblokkot minden függvényhez.
- Egységesítsük a hibakezelést (try/catch, Write-Error, szükség szerint throw).
- Vezessünk be strukturált naplózást súlyossági szintekkel.
- Adjunk megjegyzésalapú súgót minden függvényhez.
- Egységesítsük a változóelnevezést (például camelCase a helyi, PascalCase a globális változókhoz).
- Csoportosítsuk a plotokat/lépéseket logikai terület szerint (rendszer, Docker, Kubernetes stb.).
- Tervezzünk beállításinjektálási mechanizmust az extra paraméteres lépésekhez.

---

Lásd még: `docs/powershell-coding-standards.md` (folyamatban)
