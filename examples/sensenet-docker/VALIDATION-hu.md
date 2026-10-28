<!-- documentation-anchors:start -->
<a id="doc-verification--2026-10-22"></a>
<!-- documentation-anchors:end -->
# Ellenőrzés — 2026-10-22

<!-- documentation-navigation -->
[English](VALIDATION.md) | [Magyar](VALIDATION-hu.md) · [Dokumentáció](../../docs/README-hu.md) · [Projekt](../../README-hu.md)
<!-- /documentation-navigation -->

Ez a jelentés a hordozható példát fedi le, a meglévő közös kezelőalkalmazás átadásától függetlenül. A motor, az API és a frontend kódja nem változott.

<!-- documentation-anchors:start -->
<a id="doc-actual-execution"></a>
<!-- documentation-anchors:end -->
## Tényleges végrehajtás

- Windows PowerShell7.6.6 natív regressziós tesztcsomag:110/110 sikeres.
- Windows PowerShell5.1 natív regressziós tesztcsomag:109/109 sikeres. Maga a példa PowerShell7.2+ verziót igényel; ezek az ellenőrzések a motor régebbi hostját őrzik meg.
- `tests/Run-SenseNetExample.ps1`:14/14 ellenőrzés Docker-hívás nélkül: mind a13 natív plot előzetes ellenőrzése és a licencelutasítás a segéd futásidejű hatásai előtt.
- `tests/Run-SenseNetExample.ps1 -RunDocker`:30/30 ellenőrzés. Új, véletlenszerű nevű, kizárólag loopbacken elérhető stack, rögzített publikus image-ek, tényleges Root-válasz, discovery, szigorú PKCE adminbejelentkezés, hitelesített Admin-olvasás és valódi Folder-létrehozás. Ugyanaz a tartalomazonosító megmaradt stop/start, konténer-újralétrehozás és visszaállítás után. A meg nem erősített visszaállítás megőrizte a módosított jelölőket. A megerősített visszaállítás **mind** az SQL átvételi adatbázisban, **mind** az App_Data-ban lecserélte a módosított jelölőket az eredeti mentési értékeikre. A tulajdonjogot ellenőrző takarítás eltávolította az eldobható konténereket, két kötetet, hálózatot és privát helyi fájlokat.
- Tényleges helyi böngészős alkalmazás:15 sikeres kezelt futás, köztük install-előnézet, teljes install, tartalom, status/logs, mentés, stop/start, újralétrehozás, visszaállítás és hitelesített ellenőrzés. A meglévő három projekt és előzményeik megmaradtak. A negyedik projekt telepítve és futva maradt.
- Tényleges asztali alkalmazás adattára: a varázsló mentése a támogatott API-n keresztül, install-előnézet, ismételt prepare és status sikeres. Saját névtere és portjai vannak; második tartós SQL-stacket szándékosan nem telepítettünk.
- Ubuntu26.04 / PowerShell7.6.6: a tényleges projekt-előkészítés és localhost-tanúsítvány létrehozása, a csak tulajdonosnak hozzáférhető700/600 könyvtár-/fájlmódok és mind a13 natív előnézet sikeres. Teljes Linux-hostos telepítést/mentést/visszaállítást **nem** futtattunk. A fenti teljes Docker-életciklus Windowsról futott Linux-konténerek ellen.

A megtisztított helyi bizonyíték a figyelmen kívül hagyott `artifacts/sensenet-example-tests/<fixture>/acceptance-evidence.json` és `artifacts/management/sensenet-project-20261022/` alatt található. Egyik könyvtár sem kötelező projektbemenet vagy commitolt hitelesítőadat-tár. Az eldobható bizonyíték a fenti két tesztparanccsal újragenerálható.

<!-- documentation-anchors:start -->
<a id="doc-reproduced-corrections"></a>
<!-- documentation-anchors:end -->
## Reprodukált javítások

- Egy helyi API-build digestje nem volt feloldható a publikus registryben. A példa a helyi image helyett közzétett, megváltoztathatatlan API-digestet rögzít.
- A külön konfigurált, csak localhostra érvényes kliens elkerüli az alapértelmezett kliens inicializálási függőségét. RequirePkce=true esetén a sikeres IdentityServer-bejelentkezés200 HTML Redirect nézetet is visszaadhat. A segéd HTML/JavaScript végrehajtása nélkül olvassa ki annak helyi data-url értékét, ellenőrzi az identitás-callbacket és az állapotot, majd beváltja az engedélyezési kódot.
- A jelenlegi API elfogadja a közvetlen JSON-tartalommodellt. A legacy form/models szintaxis figyelmen kívül hagyta a kért Name értéket; a javított kezdeti adatfeltöltés visszaolvassa a pontos nevű Folder tartalmat, és nem bízik kizárólag a létrehozási válaszban.
- Az ismételt PowerShell Set-Acl SeSecurityPrivilege jogosultságot kért egy védett könyvtáron. Az explicit FileSystemAclExtensions.SetAccessControl csak a DACL-t módosítja, és a normál felhasználói tokennel ismételten is működik.

<!-- documentation-anchors:start -->
<a id="doc-scope"></a>
<!-- documentation-anchors:end -->
## Hatókör

Ez helyi fejlesztői példa a hivatalos kezdeti admin/admin fiókkal. Nem konfigurál külső Admin UI callbacket, éles hitelesítést, image-frissítést vagy eltérő verziójú adatbázis migrációját. A segéd csak a projekthez generált tanúsítványt fogadja el; nem módosítja az OS bizalmi tárát, és nem tiltja le globálisan a tanúsítványellenőrzést.
