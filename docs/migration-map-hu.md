<!-- documentation-anchors:start -->
<a id="doc-component-and-migration-map"></a>
<!-- documentation-anchors:end -->
# Komponens- és migrációs térkép

<!-- documentation-navigation -->
[English](migration-map.md) | [Magyar](migration-map-hu.md) · [Dokumentáció](README-hu.md) · [Projekt](../README-hu.md)
<!-- /documentation-navigation -->

A forrás megőrzésének referenciája a management UI munka előtt:
[`98b483e4214a4299e30e70ba90f71f51eed953d8`](https://github.com/VargaJoe/SenseNet-Project-Installer/tree/98b483e4214a4299e30e70ba90f71f51eed953d8).
Ez az előkészítés egyetlen történeti komponenst sem távolít el.

| Komponens | Kezelés | Helyettesítés / határ |
| --- | --- | --- |
| `Core/PlotManager.psm1`, natív `Auto/*/package.psd1` | Megtartva, mérvadó | A CLI és a management UI által közösen használt konfigurációfeloldás, validáció és soros végrehajtás |
| `Run.ps1`, JSON plot-/beállításformátum | Megtartva, kompatibilis | Támogatott PowerShell 5.1 / 7 CLI |
| `Core/PlotIntegration.psm1`, `Invoke-Request.ps1` | Megtartva, bővítve | A meglévő v1 katalógus-/terv-/futáshívások használhatók maradnak |
| `Show-PlotRunner.ps1` | Megtartva, átmeneti | Windows Forms indító; tervezett utódja a közös management UI |
| Történeti Angular GUI és HTTP-listener | Megtartva, új munkához elavult | Új `src/Management/` React és ASP.NET Core megvalósítás; a történeti kliensek nem az új API |
| `Run-Legacy.ps1`, `AutoExt/`, eredeti telepítőállományok | Megtartva a felhasználói átvételig | Külön folyamatos kompatibilitás, meglévő Windows-/eszköz-/adminelőfeltételek; teljes natív egyezést nem állítunk |
| `docs/legacy/` | Történeti referenciaként megtartva | A jelenlegi belépési pont a `docs/README.md` |
| `src/Management/Server/` | Új komponens helye | Hitelesített helyi/hosztolt API, projekt- és futáséletciklus, elkülönített natív workerek |
| `src/Management/Web/` | Új komponens helye | Közös React/TypeScript UI |
| `src/Desktop/` | Új komponens helye | Tauri Windows/Linux csomagolás és helyi szolgáltatás-életciklus |

A legacy kivezetése és a repository átnevezése külön, későbbi döntések a felhasználói
átvétel után. A natív plotok sorosak maradnak; párhuzamosságot, elágazást, újrapróbálkozást és
távoli ügynökös végrehajtást tényleges motortámogatás nélkül nem szabad hirdetni.
Ebbe a személyes repositoryba nem kerülhet céges forrás, konfiguráció,
hitelesítőadat, előzmény vagy alkalmazásspecifikus telepítési állomány.
