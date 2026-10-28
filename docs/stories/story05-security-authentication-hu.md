<!-- documentation-anchors:start -->
<a id="doc-story-05---enhanced-security-and-authentication"></a>
<!-- documentation-anchors:end -->
# Story 05 - Fejlettebb biztonság és hitelesítés

<!-- documentation-navigation -->
[English](story05-security-authentication.md) | [Magyar](story05-security-authentication-hu.md) · [Dokumentáció](../README-hu.md) · [Projekt](../../README-hu.md)
<!-- /documentation-navigation -->

<!-- documentation-anchors:start -->
<a id="doc-overview"></a>
<!-- documentation-anchors:end -->
## Áttekintés
Átfogó biztonsági fejlesztések megvalósítása a teljes Plot Manager rendszerben, beleértve a szerepköralapú hozzáférés-vezérlést, biztonságos hitelesítőadat-kezelést és auditnaplózást.

<!-- documentation-anchors:start -->
<a id="doc-goals"></a>
<!-- documentation-anchors:end -->
## Célok
- Szerepköralapú hozzáférés-vezérlés megvalósítása a GUI-hoz és scriptekhez
- Hitelesítőadatok biztonságos tárolása és kezelése
- Átfogó auditnaplózás hozzáadása
- API-biztonság javítása hitelesítési tokenekkel

<!-- documentation-anchors:start -->
<a id="doc-acceptance-criteria"></a>
<!-- documentation-anchors:end -->
## Elfogadási feltételek
- Szerepköralapú felhasználóhitelesítési rendszer
- Biztonságos hitelesítőadat-tárolás (Windows Credential Manager/Azure Key Vault)
- Átfogó auditnaplózás minden művelethez
- API-hitelesítés JWT-tokenekkel
- Biztonsági szkennelés és sérülékenységértékelés
- Biztonságos konfigurációkezelés

<!-- documentation-anchors:start -->
<a id="doc-tasks"></a>
<!-- documentation-anchors:end -->
## Feladatok
- Felhasználói szerepkör- és jogosultságrendszer tervezése
- Hitelesítés megvalósítása az Angular frontendben
- JWT-tokenalapú API-hitelesítés hozzáadása
- Windows Credential Manager integrálása biztonságos tároláshoz
- Azure Key Vault támogatás hozzáadása felhőtelepítésekhez
- Átfogó auditnaplózás megvalósítása
- Biztonsági fejlécek és HTTPS-kikényszerítés hozzáadása
- Biztonságos konfigurációfájl-titkosítás létrehozása
- Bemenetvalidáció és szanitizálás megvalósítása
- Biztonsági szkennelés hozzáadása a CI/CD-pipeline-hoz
- Biztonsági dokumentáció és irányelvek létrehozása
- Munkamenet-kezelés és időtúllépés megvalósítása

<!-- documentation-anchors:start -->
<a id="doc-business-value"></a>
<!-- documentation-anchors:end -->
## Üzleti érték
- Vállalati szintű biztonság éles környezetekhez
- Megfelelés a biztonsági szabványoknak és előírásoknak
- Jogosulatlan hozzáférés és adatszivárgás kockázatának csökkentése
- Jobb nyomon követhetőség és elszámoltathatóság

<!-- documentation-anchors:start -->
<a id="doc-dependencies"></a>
<!-- documentation-anchors:end -->
## Függőségek
- Story 02 (A modern Angular jobb biztonsági funkciókat biztosít)
- Story 04 (A tesztelési keretrendszer validálja a biztonsági megvalósításokat)

<!-- documentation-anchors:start -->
<a id="doc-estimated-effort"></a>
<!-- documentation-anchors:end -->
## Becsült ráfordítás
Nagy (2 hét) - A biztonság gondos megvalósítást és tesztelést igényel

<!-- documentation-anchors:start -->
<a id="doc-status"></a>
<!-- documentation-anchors:end -->
## Állapot
Tervezett
