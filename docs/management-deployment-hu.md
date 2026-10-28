<!-- documentation-anchors:start -->
<a id="doc-management-build-desktop-packaging-and-deployment"></a>
<!-- documentation-anchors:end -->
# Management build, asztali csomagolás és telepítés

<!-- documentation-navigation -->
[English](management-deployment.md) | [Magyar](management-deployment-hu.md) · [Dokumentáció](README-hu.md) · [Projekt](../README-hu.md)
<!-- /documentation-navigation -->

A közös React klienst a `src/Management/Server/PlotManager.Server.csproj` szolgálja ki.
A szolgáltatás elkülönített PowerShell 7 folyamatokban hívja az 1-es verziójú JSON worker hidat.
A `src/Desktop` egy Tauri 2 natív ablak **ugyanazon szolgáltatás és kliens** körül.
Nincs külön asztali konfigurációfeloldó. Lásd: [API és tulajdonjog](management-api-hu.md).

<!-- documentation-anchors:start -->
<a id="doc-prerequisites"></a>
<!-- documentation-anchors:end -->
## Előfeltételek

| Mód | A végrehajtó gépen szükséges |
| --- | --- |
| Windows asztali | Windows 10/11 x64, PowerShell 7 (`pwsh` a PATH-ban), Microsoft WebView2 |
| Linux asztali | Ubuntu 26.04 x64 grafikus munkamenet, PowerShell 7 a PATH-ban, GTK 3 / WebKitGTK 4.1; a `.deb` deklarálja a rendszerkönyvtárakat |
| Publikált helyi/hosztolt szolgáltatás | Windows x64 vagy Ubuntu 26.04 x64, PowerShell 7 a PATH-ban; a publikált szolgáltatás tartalmazza a .NET 8-at |
| Forrásból történő build | .NET 8 SDK, Node 20, npm; asztali buildhez ezenfelül Rust 1.99.1 és a platform fordító/WebView fejlesztői csomagjai |

A PowerShellt a [Microsoft útmutatója](https://learn.microsoft.com/powershell/scripting/install/installing-powershell) alapján telepítsd.
A `scripts/management/Check-DesktopPrerequisites.ps1` ellenőrzi a telepített előfeltételeket;
a fordító ellenőrzéséhez add meg a `-Build` kapcsolót. Egyes lépések további eszközöket
(Git, Docker, adatbáziskliensek) vagy jogosultságokat igényelhetnek. A katalógus jelöli a csak Windowson használható lépéseket;
a platformfüggetlen felület telepítése nem teszi elérhetővé az IIS-lépéseket Linuxon.

Az aláíratlan Windows NSIS fejlesztői telepítő felhasználónként telepít, és szükség esetén felajánlja
a Microsoft WebView2 bootstrappert. Egy offline Windows gépen a WebView2-nek már telepítve kell lennie.
A buildhez és teszteléshez nem kell alkalmazásaláíró tanúsítvány.
A Windows megjelenítheti az aláíratlan csomagok szokásos, ismeretlen közzétevőre figyelmeztető ablakát.

A Windows asztali buildhez Visual Studio C++ buildeszközök és Windows SDK szükséges.
Az Ubuntu asztali build receptje ezt használja:

```sh
sudo apt-get install libwebkit2gtk-4.1-dev build-essential curl wget file \
  libxdo-dev libssl-dev libayatana-appindicator3-dev librsvg2-dev xvfb
```

A platformelőfeltételek és a Windows bootstrapper működése a
[Tauri előfeltételeit](https://v2.tauri.app/start/prerequisites/) és a
[Windows-telepítő dokumentációját](https://v2.tauri.app/distribute/windows-installer/) követik.
A leszállított Linux fejlesztői csomag Ubuntu 26.04 x64 rendszeren készült és futott;
deklarált ICU-függősége az ICU 74-et vagy 78-at fogadja el. A helyi validáció kicsomagolja a `.deb`-et,
és elkülönített, kicsomagolt függőségekkel futtatja a natív WebView-t; a tényleges,
`apt`-on keresztüli csomagtelepítés külön ellenőrzés. A kézi workflow külön artefaktumként
definiál Ubuntu 24.04 buildet. Más disztribúciók és az ARM64 kívül esnek
az ellenőrzött csomagmátrixon. Lásd a [validációs feljegyzést](management-validation-hu.md).

<!-- documentation-anchors:start -->
<a id="doc-build-and-local-browser"></a>
<!-- documentation-anchors:end -->
## Build és helyi böngésző

A repository gyökeréből, PowerShell 7-ben:

```powershell
./scripts/management/Build-Management.ps1 -Runtime win-x64
# On Ubuntu: -Runtime linux-x64
./scripts/management/Start-Management.ps1
```

A `Build-Management.ps1` a verziókezelt npm lockfájlokat használja, önálló .NET 8
szolgáltatást publikál, belefoglalja a lefordított klienst, és csak a natív motort, manifeszteket
és CLI-belépési pontokat másolja. Kizárólag az ellenőrzött, generált kimeneti könyvtárait üríti.
A kimenet: `artifacts/management/<rid>/{service,engine}`. Az ezt a könyvtárat használó
célgépen nincs szükség forráscheckoutra. A PowerShell kifejezett futásidejű előfeltétel,
nem egy második, becsomagolt, önállóan javítandó futtatókörnyezet.
Ez a hordozható motorkönyvtár csak a natív CLI-t támogatja; a történeti `-Legacy`
végrehajtás továbbra is az eredeti forrásdisztribúciót és annak örökölt függőségeit használja.

A `Start-Management.ps1` egy átmeneti IPv4 loopback porton indítja el a publikált szolgáltatást,
kriptográfiai bootstrap hitelesítőadatot generál a memóriában, és URL-fragmenttel nyitja meg
a böngészőt. A felület ezt HttpOnly munkamenetcookie-ra cseréli,
majd eltávolítja a fragmentet. Az indító sosem írja ki vagy menti ezt a hitelesítőadatot.
A szolgáltatás élettartamát a terminál birtokolja; a böngészőlap bezárása után a futások aktívak maradnak.
A terminál bezárása vagy az indító leállítása leállítja a szolgáltatást és workereit.
Leállított műveletet nem jelent sikeres visszagörgetésként.

Az opcionális `-DataDirectory`, `-ProjectRoot` és `-Port` a helyi tárolót és
az engedélyezett, futtatói oldali projektgyökeret választja ki. A `-NoBrowser` használatához az operátornak
`PLOTMANAGER_TOKEN` értéket kell megadnia az indító környezetében; nyisd meg a kiírt alap-URL-t, és használd
ezt a tokent a bejelentkező képernyőn. Valódi tokeneket ne adj át shell-előzménybe kerülő parancsban, és ne commitold
őket projektbe. Másolt szolgáltatáskönyvtár közvetlen futtatásához állítsd be az alábbi
változókat, és indítsd a `service/PlotManager.Server` fájlt (Windows: `.exe`).

<!-- documentation-anchors:start -->
<a id="doc-native-desktop"></a>
<!-- documentation-anchors:end -->
## Natív asztali alkalmazás

```powershell
./scripts/management/Check-DesktopPrerequisites.ps1 -Build
./scripts/management/Build-Management.ps1 -Runtime win-x64 -Desktop
# On Ubuntu: -Runtime linux-x64 -Desktop
```

A Rust eszközláncot a `src/Desktop/rust-toolchain.toml` rögzíti. A Cargo- és npm-
lockfájlok korlátozzák a függőségfeloldást. A szokásos build a megfelelő gazda operációs rendszert használja;
a Linux-csomag Windows alatti keresztfordítása nem támogatott. A kimenet:

- Windows: `src/Desktop/src-tauri/target/release/bundle/nsis/*-setup.exe`.
- Ubuntu: `src/Desktop/src-tauri/target/release/bundle/deb/*.deb`; telepítés:
  `sudo apt install ./<package>.deb`, majd az alkalmazásmenüből indítsd a **Plot Manager** alkalmazást.

Ha nem áll rendelkezésre natív Windows buildeszköz vagy CI, a Tauri Linuxos
NSIS keresztbuildet is dokumentál a `cargo-xwin` és az MSVC Windows cél használatával. Egy
elkülönített Linux buildgépen telepítsd az `llvm`, `lld`, `clang` és `nsis` eszközöket, futtasd a
`rustup target add x86_64-pc-windows-msvc`, majd a
`cargo install --locked --version 0.23.1 cargo-xwin` parancsot. Ezután:

```powershell
./scripts/management/Build-Management.ps1 -Runtime win-x64 -Desktop -WindowsCross
```

A segédprogram alapértelmezésben x64 desktop SDK-t bont ki, és utána visszaállítja a hívó folyamat
környezetét; a kifejezetten megadott `XWIN_ARCH` / `XWIN_VARIANT` értékeket megtartja.
Az `XWIN_CACHE_DIR`, `CARGO_HOME`, `RUSTUP_HOME`, `NUGET_PACKAGES`, az npm cache
és a `TMPDIR` kellő szabad hellyel rendelkező buildkötetre kerüljön. Az SDK kibontása és a natív
függőségek a végső telepítőn felül több GB helyet igényelnek. A `/dev/shm` cache
átmeneti RAM-tároló: a WSL vagy konténere leállítása előtt
mentsd a kész cache-t a buildkötetre. A Docker képrétegei a Docker saját lemezét használják akkor is,
ha a checkout másik meghajtóról van bind mounttal felcsatolva.
A `makensis` disztribúciós buildjei rögzített `/usr/share/nsis` adatútvonalat tarthatnak meg
akkor is, ha az `NSISDIR` be van állítva. A hordozható buildernek ezeket a fájlokat biztosítania kell
az elkülönített buildkörnyezetben; a helyi ellenőrző privát mount névteret használ.

Ez továbbra is a Tauri Windows alkalmazást és annak önálló Windows
backendjét fordítja. A telepítő helye:
`src/Desktop/src-tauri/target/x86_64-pc-windows-msvc/release/bundle/nsis/`.
A `cargo-xwin` a dokumentált Microsoft licencfeltételek szerint szerzi be a Microsoft SDK/CRT-t.
A sikeres keresztbuildet tényleges Windows-telepítésnek és
natív smoke tesztnek kell követnie; önmagában a Wine alatti futtatás nem igazolja a Windows-viselkedést.

A Tauri becsomagolja az önálló helyi szolgáltatást, a lefordított klienst és a natív motort.
Induláskor ellenőrzi a `pwsh`-t, privát, felhasználónkénti alkalmazástárhelyet hoz létre, kizárólag
a `127.0.0.1` címhez kötődik, új 256 bites hitelesítőadatot generál, elindítja gyermekfolyamatát, és vár
a hitelesített készenléti válaszra. Az ablak csak az adott szolgáltatás origóján belül navigálhat,
és nincs frontend fájlrendszer/shell IPC-jogosultsága.
A szolgáltatás hitelesítőadatait a folyamatkörnyezet adja át, soha nem parancsargumentumok
vagy projektfájlok. A felület munkamenete ugyanazt a cookie-cserét használja, mint a helyi böngészős mód.

Az asztali ablak birtokolja helyi szolgáltatását. Bezáráskor megerősítést kér, és
kifejezetten figyelmeztet, hogy a futó workerek leállnak, a befejezett műveletek nem gördülnek vissza,
és a külső feladatok folytatódhatnak. Először szabályos leállítást kísérel meg, majd korlátozott idejű
kényszerleállítást végez a példány saját gyermekfolyamat-fáján. A szolgáltatás figyeli az asztali szülőfolyamatot,
hogy az asztali alkalmazás összeomlása ne hagyjon szándékosan leválasztott, jogosultságokkal rendelkező futtatót.
Ne zárd be az asztali alkalmazást, ha egy műveletnek folytatódnia kell: ehhez a tartós helyi
böngészős vagy hosztolt szolgáltatásmódot használd. Minden asztali indítás saját
szolgáltatáspéldányt és hitelesítőadatot indít; egy asztali adatkönyvtárat ne ossz meg
párhuzamos példányok között.

Az alapértelmezett engedélyezett projektgyökér az adott asztali példány privát `projects/`
könyvtára. Máshol található meglévő projektek megnyitásához indítás előtt állítsd a géphelyi
`PLOTMANAGER_DESKTOP_PROJECT_ROOT` értékét abszolút könyvtárra, például
Windowson `$env:PLOTMANAGER_DESKTOP_PROJECT_ROOT = 'D:\Projects'`, Linuxon pedig
`PLOTMANAGER_DESKTOP_PROJECT_ROOT="$HOME/projects" plot-manager`. A meglévő
`plot-project.json` projektet a futtatói oldali könyvtárválasztóval nyisd meg a gyökér alatt.
A választás az indítógéphez tartozik, nem a hordozható projektdefinícióhoz.
A backend tulajdonjog-, útvonal- és linkellenőrzései továbbra is érvényesek, a smoke tesztek pedig
ettől a beállítástól függetlenül mindig saját elkülönített projektgyökerüket használják.

<!-- documentation-anchors:start -->
<a id="doc-authenticated-https-server"></a>
<!-- documentation-anchors:end -->
## Hitelesített HTTPS-szerver

A böngésző végrehajtási célpontja mindig a szolgáltatás gazdagépe, a kijelzett operációsrendszer-
identitás alatt. A böngésző soha nem csatlakozik tetszőleges localhost workerekhez. Az első futtatói
interfész 1-es verziójú, egygépes és soros. A hitelesített kimenő ügynökök
és több távoli célgép támogatása későbbi munka.

Publikáld a megfelelő futtatókörnyezetet, másold a `service/` és `engine/` könyvtárakat egy dedikált helyre,
például `/opt/plot-manager`, telepítsd a `pwsh`-t, és hozz létre dedikált, nem privilegizált
`plotmanager` fiókot. Csak a jóváhagyott projektekhez szükséges jogosultságokat/eszközöket add neki.
A GUI-hozzáférés nem ad további OS-jogosultságot. A szolgáltatás környezeti változóit
a forráscheckouton/projektfájlokon kívül állítsd be:

| Változó | Példa / jelentés |
| --- | --- |
| `PLOTMANAGER_MODE` | `hosted`; a távoli HTTP elutasítva |
| `ASPNETCORE_URLS` | `https://0.0.0.0:7443` |
| `ASPNETCORE_Kestrel__Certificates__Default__Path` | `/etc/plot-manager/gui-api.pfx` |
| `ASPNETCORE_Kestrel__Certificates__Default__Password` | A szolgáltatásfelügyelő/titoktár által injektált PFX-jelszó |
| `PLOTMANAGER_USERS` | JSON-leképezés az operátornevekről különböző, legalább 32 karakteres véletlen tokenekre |
| `PLOTMANAGER_DATA` | `/var/lib/plot-manager`; privát állapot, védelmi kulcsok, tulajdonjog, titkosított titkok, futási rekordok |
| `PLOTMANAGER_PROJECT_ROOT` | `/srv/plot-manager/projects`; csak ez alatti könyvtárak nyithatók meg |
| `PLOTMANAGER_ENGINE` | `/opt/plot-manager/engine` |

Az operátortokeneket kriptográfiai generátorral, például
`openssl rand -hex 32` paranccsal generáld közvetlenül egy hozzáférés-védett telepítési titoktárba.
A `PLOTMANAGER_USERS` szemléltető alakja:
`{"alice":"<alice-64-hex-token>","bob":"<bob-distinct-64-hex-token>"}`; a helyőrzőket
cseréld le, ne használd hitelesítőadatként. A tokeneket a szolgáltatáskörnyezet frissítésével
és karbantartási ablakban történő újraindítással rotáld. A cookie tokenbélyegeit az aktuális
operátori hitelesítőadatokkal ellenőrzi, így a módosított konfiguráció betöltése után a régi munkameneteket elutasítja.
Őrizd meg a védelmi kulcsokat: a tárolt titkokat is ezek titkosítják,
és nem tokenrotációs mechanizmust jelentenek.

A `scripts/management/plot-manager.service.example` Linuxos folyamatfelügyeletet mutat.
Csak a tulajdonos által olvasható `/etc/plot-manager/service.env` fájlt és a szolgáltatásfiók
tulajdonában lévő, `0700` módú tárolókönyvtárakat használj. A HTTPS privát kulcsa a projekteken kívül legyen,
és csak a felügyelő/szolgáltatásfiók olvashassa. A hálózati hozzáférést korlátozd a jóváhagyott
operátorokra. Telepíts megbízható GUI/API tanúsítványt a megfelelő szervernévvel
(például `plot-manager.example.invalid`) és megbízható CA-lánccal. Nem szükséges bizonytalan
tanúsítványellenőrzési megkerülés. Ebben a szállításban közvetlenül Kestrel HTTPS-hez kötődj;
a megbízható forwarded header/reverse proxy TLS-terminálás nincs megvalósítva.
Windowson egy meglévő, jóváhagyott szolgáltatásfelügyelő felügyelheti a futtatható fájlt;
a program nem állítja, hogy megvalósítja a Windows Service Control Manager protokollját.

Az állapotmódosító API-hívások hitelesítést, `X-Plot-Request: 1` fejlécet, és ha van Origin fejléc,
azonos origót igényelnek. A böngészőcookie-k HttpOnly, SameSite=Strict, HTTPS módban pedig
Secure beállításúak. CLI/natív kliensek használhatják az `Authorization: Bearer <token>` fejlécet.
A projekt-, réteg- és futáskérések ellenőrzik a projekt tulajdonjogát. Minden felhasználó továbbra is
a közös szerver OS-identitásával fut; csak olyan operátorfiókokat hozz létre, amelyekre rábízható a
jóváhagyott projektlépések futtatása ezzel az identitással. Ez adminisztrációs szolgáltatás,
nem ellenséges feladatok sandboxa. Ne tegyél elérhetővé hitelesítetlen távoli végpontokat.

A szolgáltatás priváttá teszi adatkönyvtárát (Windows tulajdonosi ACL / Unix `0700`).
Az állapotot és a védelmi kulcsokat együtt mentsd; a mentéseket ugyanolyan gondosan korlátozd, mint az élő
állapotot. A projektfájlok környezeti/titokhivatkozásokat tartalmazhatnak, privát kulcsokat
vagy jelszavakat nem. A tulajdonoshoz kötött szolgáltatási titkokat Data Protection titkosítja,
és kizárólag worker-környezetbe injektálja. Ne engedélyezz részletes request-body naplózást.
Mintaprojektnek soha ne adj meg tetszőleges éles hitelesítőadatokat.

Három külön tanúsítványkörnyezet létezik:

1. **GUI/API HTTPS:** tanúsítvány/privát kulcs a management szerveren; a böngészőnek
   meg kell bíznia a CA-jában. A helyi loopback mód HTTP-n használja a véletlen hitelesítőadatot.
2. **A lépések által elért szolgáltatások:** bizalmi gyökerek, kliensanúsítványok és hivatkozások
   a futtatógépen, annak folyamatidentitása által használva. Ezek nem konfigurálják a GUI HTTPS-t.
3. **A telepített alkalmazás:** kifejezetten engedélyezett projektlépés által a célgépre telepített
   tanúsítványok, saját privátkulcs-jogosultságokkal. Ezek nem lesznek automatikusan managementszolgáltatás-tanúsítványok.

<!-- documentation-anchors:start -->
<a id="doc-tests-and-evidence"></a>
<!-- documentation-anchors:end -->
## Tesztek és bizonyítékok

```powershell
pwsh -NoProfile -File ./tests/Run-Tests.ps1
# Windows only:
powershell.exe -NoProfile -File ./tests/Run-Tests.ps1
pwsh -NoProfile -File ./tests/Run-GuiSmoke.ps1

cd src/Management/Web
npm ci
npx playwright install --with-deps chromium
cd ../../..
./scripts/management/Test-Management.ps1
```

A management tesztharness frontendellenőrzéseket, valódi workerfolyamatokat használó backendteszteket,
és egy valódi, elkülönített loopback szolgáltatás elleni Playwright-tesztet futtat. A harness
eldobható projekteket használ, saját hitelesítőadattal ellenőrzi a készenlétet, és csak
ellenőrzött átmeneti könyvtárát takarítja. Valódi telepítési projektet sosem csatol fel.

Az asztali csomagolás után egy eldobható Windows tesztgépen, ahol nincs meglévő
Plot Manager telepítés, futtasd:

```powershell
$installer = @(Get-ChildItem ./src/Desktop/src-tauri/target/release/bundle/nsis/*.exe)[0]
./scripts/management/Test-InstalledDesktop.ps1 -Installer $installer.FullName -ExpectedPayloadRoot ./artifacts/management/win-x64
```

Linuxon telepítsd a `.deb`-et, és futtasd a `Test-DesktopSmoke.ps1 -Executable /usr/bin/plot-manager`
parancsot `xvfb-run -a dbus-run-session -- pwsh -NoProfile -File ...` alatt. Ez valódi,
rejtett natív WebView-t indít, megvárja a hitelesített React kliens betöltését, ellenőrzi
a tokenfragment eltávolítását, leállítja saját szolgáltatását, és JSON-bizonyítékfájlt ír
az OS és a futtatható fájl SHA-256 értékével. Ez végrehajtási smoke teszt, nem teljes vizuális
asztali átvételi teszt. A Windows segéd a csomagját csendesen telepíti és eltávolítja
egy saját átmeneti könyvtárban. `-ExpectedPayloadRoot` megadásakor minden telepített
szolgáltatás-/motorfájlt összevet a publikált csomagtartalommal, és rögzíti a
manifeszt és a telepítő hashét. Tiszta teszt-VM-ekre készült,
mert az NSIS-regisztráció az alkalmazás identitásához tartozik. Nem fut le,
ha meglévő Plot Manager eltávolítási regisztrációt, szabványos parancsikont vagy menükönyvtárat
talál, így nem ír felül meglévő telepítést. A telepítő sikeres buildje,
a telepített csomag végrehajtási smoke tesztje és a kézi GUI-átvétel külön állítás.

A `.github/workflows/management.yml` **kizárólag kézi** (`workflow_dispatch`); pushok
és pull requestek sosem indítják. A repository tulajdonosa a havi runnerkeret miatt
letiltotta az Actionst, és a későbbi hónapokban sem szeretne automatikus futásokat.
A jelenlegi szállítás helyi kézi buildeket és ellenőrzéseket használ.
Kerülőútként ne engedélyezd a repository Actionst, és ne adj hozzá automatikus triggereket.
A megtartott `powershell-tests.yml` workflow is kizárólag kézi.

Az opcionális kézi workflow Windowson és Ubuntun futtatja a motort, a backendet, a frontendet,
a valódi böngészős folyamatot és a telepített natív asztali smoke tesztet. Aláíratlan
NSIS/`.deb` csomagokat, hordozható szolgáltatást és külön végrehajtási bizonyítékokat tölt fel. A meglévő PS5.1-regresszió és WinForms
smoke továbbra is Windows-ellenőrzés. A leszállított commithoz tartozó workflow eredménye,
nem e YAML jelenléte bizonyítja a sikeres buildet és platformon történő futtatást.
Runnerkeret nélkül futtasd a dokumentált `Run-Tests.ps1`,
`Test-Management.ps1`, `Build-Management.ps1` és platformfüggő asztali smoke parancsokat
helyben, ugyanazokkal a verziókezelt függőségi lockokkal és elkülönített tesztkönyvtárakkal.
A szállítás build- és végrehajtási bizonyítékait a
[validáció](management-validation-hu.md) rögzíti; sikeres Actions-futást nem állítunk.

Opcionális, gazdagéptől független Linux-ellenőrzőhöz készítsd el a
`docker build -f scripts/management/Dockerfile.linux-build -t plot-manager-linux-build .` buildet.
Ez Dockerben biztosít Ubuntu 24.04-et, .NET-et, Node-ot, PowerShellt, Rustot és WebView-buildfüggőségeket.
Tesztelés előtt másold a checkoutot elkülönített konténermunkaterületre, kihagyva
a `node_modules`, `bin`, `obj`, Cargo `target` és artifacts könyvtárakat; Linuxhoz ne használd
újra a Windows natív függőségi könyvtárait. A Docker-alapú natív WebView
smoke megkövetelheti a WebKit sandbox kikapcsolását **csak az elkülönített tesztkonténeren belül**;
ez nem alkalmazástelepítési beállítás.
