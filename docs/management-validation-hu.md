<!-- documentation-anchors:start -->
<a id="doc-management-validation-record"></a>
<!-- documentation-anchors:end -->
# Management validációs feljegyzés

<!-- documentation-navigation -->
[English](management-validation.md) | [Magyar](management-validation-hu.md) · [Dokumentáció](README-hu.md) · [Projekt](../README-hu.md)
<!-- /documentation-navigation -->

Ez a 2026-10-21–22 megvalósítási munkamenetek végrehajtásait rögzíti. A build,
az automatizált végrehajtási smoke és az interaktív kézi átvétel külön állítás.
A hátralévő emberi ellenőrzéshez használd az [átvételt](management-acceptance-hu.md),
a buildek és ellenőrzések megismétléséhez a [telepítést](management-deployment-hu.md).

<!-- documentation-anchors:start -->
<a id="doc-source-and-review"></a>
<!-- documentation-anchors:end -->
## Forrás és review

- Előkészítés: [PR #31](https://github.com/VargaJoe/SenseNet-Project-Installer/pull/31),
  `codex/management-ui-preparation` → `develop`.
- Megvalósítás: [PR #32](https://github.com/VargaJoe/SenseNet-Project-Installer/pull/32),
  `codex/shared-management-ui` az előkészítő ágba. Előbb #31 review/merge,
  majd #32 átirányítása `develop`-ra. Egyik PR sem lett automatikusan mergelve.
- Csomagolás előtti végső funkcionális forrás: `a8cb561b50ff57c13b1d0f6fa65cc1ec0035d495`.
  A csomagolási segédek, a kézi workflow-szabály és a dokumentáció változásai
  külön szerepelnek a becsomagolt programtól.
- A natív motor továbbra is 14 csomag / 49 lépés. A CLI, a PS5.1-belépési pontok és
  az átmeneti Windows Forms indító elérhetők maradnak.

<!-- documentation-anchors:start -->
<a id="doc-executed-checks"></a>
<!-- documentation-anchors:end -->
## Végrehajtott ellenőrzések

| Ellenőrzés | Tényleges környezet | Eredmény |
| --- | --- | --- |
| Natív motor és új management híd | Windows, PowerShell 7.6.6 | 110/110, kihagyás nélkül |
| Natív kompatibilitás | Windows PowerShell 5.1 | 109/109, kihagyás nélkül |
| Megtartott Windows Forms preview/run smoke | Windows, PS7 és PS5.1 | Sikeres, rejtett valódi form |
| Natív motor és management híd | WSL Ubuntu 26.04, PowerShell 7.6.6 | Végül 103/103 sikeres; 7 kifejezett, csak Windowsos kihagyás |
| ASP.NET Core backend | Windows, .NET 8 | Végső teljes csomag: 93/93 ellenőrzés, beleértve a terminal-history megosztási hibát, rövid titkok protokollját, natívan létrehozott könyvtár ACL-jét és tényleges verbatim útvonalas workerregressziót |
| ASP.NET Core backend | WSL Ubuntu 26.04, .NET 8 | 75/75 teljes csomag a végső szanitizáló előtt; a végső szanitizáló valódi workerregressziója 22/22 |
| React/TypeScript | Windows, Node 20 | Sikeres build; 23/23 teszt; éles függőségaudit: 0 sérülékenység |
| React/TypeScript | WSL Ubuntu 26.04, Node 20 | Sikeres build azonos végső JS-állománnyal; 23/23 teszt |
| Valódi böngészős folyamat | Windows, Playwright Chromium | 2/2 sikeres a végső veszteségmentes JSON-klienssel és tényleges szolgáltatással/workerekkel |
| Valódi böngészős folyamat | WSL Ubuntu 26.04, Playwright Chromium | 2/2 sikeres ugyanazzal a végső klienssel és tényleges szolgáltatással/workerekkel |
| Publikált hordozható indító | Windows, önálló win-x64 szolgáltatás | Hitelesített készenlét, teljes általános plot, pontos kimeneti bájtok és szolgáltatás-/indítóleállítás sikeres |
| Telepített Windows asztali alkalmazás | Windows, aláíratlan NSIS fejlesztői telepítő | Telepítés, 368 telepített tartalomhash, natív hitelesített UI/szolgáltatásleállítás, eltávolítás és regisztráció/parancsikon takarítása sikeres |
| Natív Linux asztali alkalmazás | Ubuntu 26.04 / WSLg, végső kicsomagolt `.deb` | Tényleges GTK/WebKit ablak, hitelesített UI-készenlét, bootstrapfragment-eltávolítás és saját szolgáltatás leállítása sikeres |

A motor-, UI- és böngészőellenőrzések a `d0467510` forrást használják. A későbbi termékváltozások csak
a Windows állapotkönyvtár ACL-beállítását és a helyi motorútvonal normalizálását érintik; sem a
motort, sem a frontendkódot nem változtatják. Ezek után a teljes Windows backendcsomag és a hordozható indító
újra lefutott. A Linux szolgáltatás újrapublikálva/újracsomagolva, natív smoke tesztje
friss kicsomagolásból megismételve. Ez nem új teljes Linux backendteszt-állítás.

A böngészős folyamat új projektet hoz létre, és az általános varázslót valódi
fájlrendszerkimenetig futtatja, majd ellenőrzi a különálló/teljes végrehajtást, az átrendezés utáni hibás kimeneti
függőségeket, a típusos/ismeretlen numerikus JSON roundtripet, a tartós futás-
URL-eket és újracsatlakozást, valamint egy varázsló/környezet nélküli projektet. A backendellenőrzések lefedik
a CLI-egyezést, a rétegzett eredetkövetést, a változtathatatlan konfiguráció-/csomag-/környezet-/titok-
pillanatképeket, a mellékhatás előtti preflightot, a tényleges worker/unokafolyamat megszakítását,
a tulajdonjogot, CSRF-et, tárolt titkok titkosítását, tokenvisszavonást és a valódi Kestrel HTTPS-t.
A HTTPS-fixture rögzíti átmeneti teszttanúsítványát; az éles tanúsítvány-
ellenőrzés nincs kikapcsolva.

Egy külön végső, valódi szolgáltatásos regresszió 22/22 ellenőrzést teljesített rövid titok-
értékekre, csak hivatkozott titkok injektálására, a katalógus/terv/eredetkövetés épségére, kitakart adat-
kulcsokra/numerikus skalárokra és egy ténylegesen hibás folyamatra, amelynek titokértéke `Failed`.
A protokollstátuszok mérvadók, és a payload kitakarása sosem módosítja őket.

A tényleges telepített Windows natív indítás olyan könyvtárjogosultsági hibát talált,
amelyet a böngészős indító nem érintett. A Rust által létrehozott, már az aktuális felhasználó
tulajdonában lévő könyvtár örökölt Modify jogosultsággal rendelkezhet WRITE_OWNER nélkül.
Ugyanennek a tulajdonosnak a feltétel nélküli hozzárendelése UnauthorizedAccessException hibát okozott.
A regresszió a javítás előtt reprodukálta ezt; a szolgáltatás most csak akkor kér
tulajdonos-újrahozzárendelést, ha a tulajdonos eltér. Az örökölt ACL-eket továbbra is védett,
csak az aktuális identitásra érvényes FullControl beállításra cseréli. Három regressziós ellenőrzés igazolja
az indulást, az ismételt indulást és a privát gyermekfájl-öröklést. A teljes backend-
csomag a javítás után ismét sikeres volt.

Egy második, csak natív módban jelentkező hibát pontosan ugyanazzal a PowerShell-fájllal sikerült reprodukálni:
a szokásos helyi meghajtóútvonal fut, míg a `\\?\D:\…` írásmód
`AuthorizationManager check failed` hibával leáll válaszírás előtt. A natív Tauri erőforrás-
útvonalak ezt az írásmódot használták. A szolgáltatás most csak a verbatim helyi meghajtós
motorútvonalakat normalizálja, elutasítja a kétértelmű, ponttal/szóközzel végződő komponenseket, és megtartja a valódi
UNC-útvonalakat és a végrehajtási házirendet. Egy valódi hitelesített katalógusregresszió a javítás előtt hibázik,
utána mind a 49 lépést visszaadja. A valódi natív Windows
alkalmazás ezután házirend-megkerülés nélkül teljesítette a UI/hitelesítés/leállítás ellenőrzését.

A hordozható Linux worker és a beágyazott csomag PowerShell-indulását
26.2 másodpercnek mértük csatolt buildtáron. A megszakítási fixture most legfeljebb
60 másodpercig vár a **tényleges gyermek-PID-re**, majd továbbra is ellenőrzi, hogy a megszakítás
leállítja azt a folyamatot. Ez tesztkészenléti keret, nem termékindulási
teljesítménygarancia.

A helyi bizonyítékok az ignorált `artifacts/management/` könyvtár alatt vannak, többek között:
`windows-engine-final.log`, `windows-powershell51-final.log`,
`windows-backend-final.log`, `windows-browser-e2e-final.log`, a Linux-ellenőrzési
naplók és a külön asztali végrehajtási JSON-fájlok. Generált artefaktumok és teszt-
hitelesítőadatok nem verziókezelt források. Mindkét verziókezelt workflow kizárólag kézi,
a repository tulajdonosának kérésére. Az Actions az aktuális runner-
keret miatt letiltva; itt minden eredmény helyi kézi végrehajtás, sikeres CI-állítás nélkül.

A Windows hordozható szolgáltatás ZIP-je:
`artifacts/management/PlotManager-service-win-x64-a8cb561b.zip`, SHA-256
`79aa69f12ac3c5406905099018bcec5b1f1ed8676829aa941643dc1fdf9be415`.
A kanonikus `artifacts/management/win-x64` könyvtár a
`Start-Management.ps1 -NoBrowser` indítóval futott; tényleges workere megírta a várt mintafájlt,
és a hitelesített leállítási kérés után mindkét folyamat kilépett. Az elkülönített
projekt-/állapotkönyvtár eltávolítva. Bizonyíték: `portable-launcher-windows.json`.

Az aláíratlan Windows telepítő:
`artifacts/management/PlotManager_0.1.0_x64-setup.exe`, SHA-256
`7292253cf1d016c2fcfe25575a55d5413f81738cf91fff1c1c88ea23e4ae32ad`.
A `Test-InstalledDesktop.ps1` 0 kilépési kóddal végzett; a natív végrehajtás előtt mind a 368 telepített
szolgáltatás-/motorfájlt összevetette a változtathatatlan publikált tartalommal.
A `desktop-smoke-windows.json` rögzíti a hitelesített UI-készenlétet, szolgáltatásleállítást,
az 1-es protokollt, a telepítőhash-t, tartalommanifeszt-hash-t és az `installationRemoved: true` értéket.
Az eltávolítás/parancsikon/regisztráció és a saját átmeneti mappa takarítása sikeres volt. A
segéd nem ír felül meglévő Plot Manager telepítést; a gyakorlat
saját átmeneti könyvtárba telepített. Legfeljebb 10 másodpercnyi újrapróbálkozást
enged a WebView2 cache-handle-ök lezárására, és takarítási hiba esetén megtartja az eredeti hibákat.

A végső kliensállomány: `index-BJY8UmCJ.js`, SHA-256
`8b744d62a89ec44061afccdcbe44981a912147e85014ac0f56d43edccbb098ce`.
A Windows szolgáltatás assembly SHA-256 értéke:
`4a77bea74cfdfb799b57661342e264626fd7f24640bedd839cb206492fc36500`;
a natív management híd SHA-256 értéke:
`4a53184008c30907609d1cb09adb72fd24c59c42b995ea2805032b6155919997`.
A platformonkénti `BUILD-EVIDENCE.json` és `SHA256SUMS` azonosítja a csomagolt tartalmat.

A Linux `.deb`: `artifacts/management/PlotManager_0.1.0_amd64.deb`, SHA-256
`af4f027e35afc43571a833cb3723b9c32a6e7117962026253d8b3f63462a02ee`.
A hordozható ZIP:
`artifacts/management/PlotManager-service-linux-x64-a8cb561b.zip`, SHA-256
`e3b314b6ee5398ba8fe563ad442b6f5a32799af900febaa0d73821f2bbda3c7e`.
Végső natív bizonyíték: `desktop-smoke-linux-a8cb561b.json`;
futásidejű/forrás-/tesztrészletek: `linux-final-manifest-a8cb561b.json`.

A Linux-csomagot `dpkg-deb` bontotta ki, és privát kicsomagolt
könyvtárakkal futott egy mount névtérben, Ubuntu 26.04 / GTK 3.24.52 / WebKit 2.52.6 /
ICU 78.2 / OpenSSL 3.5.5 és WSLg használatával. A gazdarendszeren nem történt csomagtelepítés vagy -csere.
Ez a csomagból történő tényleges natív végrehajtást igazolja, nem az
`apt`-os telepítést vagy a végső artefaktum Ubuntu 24.04-kompatibilitását. A verziókezelt Docker- és
opcionális kézi workflow-receptek Ubuntu 24.04 célra külön buildet készítenek.

A katalógus parancs-/modulfelderítése katalóguskérésenként egyszer cache-elve van. Ugyanabban a
hordozható Ubuntu futtatókörnyezetben a folyamaton belüli katalógus ideje 33.6-ról 9.2 másodpercre változott,
azonos 49 lépéssel és felderített eszközeredményekkel. A csatolt buildtáron induló új PowerShell workernek
további indulási költsége van. A felderítés a futtatható fájl
vagy modul elérhetőségét jelzi; Docker-/adatbázis-kapcsolatot nem igazol.

<!-- documentation-anchors:start -->
<a id="doc-limits-and-later-work"></a>
<!-- documentation-anchors:end -->
## Korlátok és későbbi munka

- Ez a szállítás szolgáltatásonként egy végrehajtógépet kezel. A kimenő hitelesített ügynökök,
  több célgép, elágazás, párhuzamos végrehajtás és automatikus újrapróbálkozás
  későbbi munka. A megszakítás sosem állítja külső műveletek visszagörgetését.
- A natív WebView smoke a hitelesített UI-készenlétet, fragmenteltávolítást és
  szolgáltatásleállítást ellenőrzi. Az emberi asztali átvétel, aláírás, ARM64 és szélesebb Linux-
  disztribúciós mátrix külön munka marad.
- Az effektív végrehajtási értékek a meglévő natív PowerShell numerikus típusait használják.
  A nyers konfigurációszerkesztés pontosan megőrzi az érvényes JSON numerikus tokeneket, beleértve
  a JavaScript biztonságos számtartományán kívüli értékeket; örökölt lépéstömb szerkesztésekor az ismeretlen metaadatok
  sosem a motor által kerekített effektív nézetből kerülnek átmásolásra.
- A korábbi szállítások meglévő SQL/Compose integrációs eredményei történetiek.
  Ezek a managementellenőrzések nem állítanak új valódi adatbázis-/konténerintegrációt vagy valódi IIS-telepítést.
- A hosztolt mód tényleges, elkülönített Kestrel HTTPS- és hozzáférés-ellenőrzési
  tesztekkel lett kipróbálva. Nyilvános éles szolgáltatás nem lett telepítve.

<!-- documentation-anchors:start -->
<a id="doc-editing-safety-follow-up"></a>
<!-- documentation-anchors:end -->
## Szerkesztési biztonság utókövetése

A `codex/management-editing-safety` ág a PR #33 `9b96153` commitjáról indul.
A közös böngészős/asztali klienst változtatja; a korábban leszállított
`a8cb561b` telepítők és hordozható ZIP-ek **nem** tartalmazzák ezeket a változásokat.
Új natív telepítőt, Linux-csomagot vagy telepített asztali átvételt nem állítunk.

A javítások előtt három szerkesztési hiba lett reprodukálva:

- A varázsló újranyitása a mentett beállítások helyett a leíró alapértékeit állította vissza.
  Egy egyedi cél `hello.txt` néven tért vissza, és a mentés felülírhatta az operátor
  kiválasztott értékeit. A hidratálás most a mentett konfigurációt használja, megkülönbözteti a hiányzó
  értéket a `null`/`false`/`0`/`[]` értékektől, és kizárja a hivatkozásalapú beállításokat a literális
  varázslószerkesztésből. Ez a nyers célréteget is ellenőrzi, ha egy környezeti literál
  elfedi a réteg hivatkozását, és frissíti a válaszokat konfiguráció- vagy
  definíciómentés után.
- A Workspace elhagyása lecsatolta a hordozható definíciószerkesztőt, és eldobta
  piszkozatát. Az oldalak közti navigáció most megőrzi; a nem mentett definíciók részt vesznek
  az oldalelhagyás és projekt-/környezetváltás védelmében.
- Az érvénytelen vagy nem alkalmazott paraméterbevitel az előző érvényes értéket hagyta a
  rétegben, miközben a mentés és végrehajtás engedélyezett maradt. A közös kliens most blokkolja
  ezeket a műveleteket a javításig vagy kifejezett eldobásig. Másik mező újrarenderelésének
  meg kell őriznie az érvénytelen piszkozatot és annak védelmét.

A kezdeti nyolc új komponens-/alkalmazásregresszió hibázott, miközben mind a 23
meglévő teszt sikeres volt. Mindhárom új valódi böngészőteszt is a
várt állításnál hibázott a korábban lefordított kliens ellen: mentett varázslóértékek,
a definíciópiszkozat pontos megőrzése és a továbbra is engedélyezett Save gomb, amikor egy
paraméter érvénytelen JSON-t tartalmaz. A böngészőtesztek elkülönített
szolgáltatás-/adat-/projektgyökeret használnak, nem meglévő telepített alkalmazást vagy hitelesítőadatait.

Végső forrásellenőrzések Windowson, Node 20.20.0, PowerShell 7.6.6,
Playwright Chromium 1.64.1 és .NET SDK 10.0.113 környezetben, `net8.0` célra:

| Ellenőrzés | Eredmény |
| --- | --- |
| React/modell/komponens/alkalmazás regressziók | 39/39 sikeres öt tesztfájlban; 16 új ellenőrzés |
| TypeScript és éles webbuild | Sikeres; végső kliens `index-C339-pX0.js` |
| Az új klienst tartalmazó szolgáltatásbuild | Sikeres, nulla figyelmeztetés/hiba; nincs backendmegvalósítás-változás |
| Új böngészőregressziók | Mindhárom sikeres: varázsló mentés/újranyitás, definíció navigáció/mentés, hibás paraméter/testvérmező-szerkesztés/mentés |
| Meglévő üresprojektes böngészős folyamat | Sikeres ugyanabban a teljes csomagfutásban, mint a három új regresszió |
| Meglévő teljes/egyedi futás, átrendezés, numerikus roundtrip és újracsatlakozás | Sikeres célzott újrafuttatásban a korlátozott tesztvárakozások javítása után, 1.1 perc |
| Dokumentációs linkek és whitespace | 145 helyi link/anchor érvényes; `git diff --check` sikeres |

Mind az öt külön böngészős forgatókönyv ugyanazzal az új kliensbuilddel sikeres volt.
A teljes csomag először négy esetet teljesített, majd kimerítette a hosszú folyamat régi várakozási
korlátait. Trace-e a 120 másodperces teljes korlát mellett 116.9 másodpercnél induló konfigurációkérést mutatott;
a következő kísérlet a 20 másodperces URL-/futáslétrehozási
ellenőrzést merítette ki, miközben a tényleges elfogadott futás már látszott. Csak a hosszú folyamat
kapott 180 másodperces teljes keretet és 60 másodperces run-ID várakozásokat, a
meglévő korlátozott run-state várakozással összhangban. Célzott újrafuttatása termék-
változás, automatikus tesztismétlés vagy további timeoutemelés nélkül sikeres volt. Ezek teszt-
keretek, nem alkalmazásindulási vagy teljesítménygaranciák.

A helyi bizonyítékok az ignorált `artifacts/management/` alatt vannak: `editing-safety-web-unit.log`,
`editing-safety-web-build.log`, `editing-safety-service-build.log`,
`editing-safety-e2e-final.log` (négy siker és a korábbi várakozási hiba), valamint
`editing-safety-existing-flow-final.log` (sikeres, javított hosszú folyamat).

Megismétlés a repository gyökeréből, a dokumentált előfeltételekkel:

```powershell
npm --prefix src/Management/Web test
npm --prefix src/Management/Web run build
dotnet build src/Management/Server/PlotManager.Server.csproj -c Release
pwsh -NoProfile -File scripts/management/Test-Management.ps1 -SkipBuild -SkipBackendTests
```

Az utolsó parancs a valódi böngészőcsomagot futtatja a frissen fordított kliens és
szolgáltatás ellen. A motor és a backend megvalósítása ebben az utókövetésben változatlan;
korábbi, fenti eredményeik történeti eredmények, nem új végrehajtások.
A workflow-k továbbra is kizárólag kéziek. Ezek az ellenőrzések nem változtatnak felhasználói AppData-t,
meglévő Docker-stackeket vagy a korábbi átadási ZIP-et.

<!-- documentation-anchors:start -->
<a id="doc-bilingual-documentation-follow-up--2026-10-28"></a>
<!-- documentation-anchors:end -->
## Kétnyelvű dokumentációs folytatás — 2026-10-28

A repó mind a 49 dokumentációs témájának teljes angol és magyar oldala van.
A kanonikus fájlnevek alapértelmezetten angolok; a `-hu.md` párjaik magyarok.
A teljes GUI-kézikönyv és a négydemós katalógus lefedettsége azonos mindkét
nyelven, ahogy a technikai, tesztelési, régi és történelmi tervezési leírásoké is.
Mindkét tartalomjegyzék eléri a saját nyelve összes oldalát; minden lap hivatkozik
a párjára és a saját nyelvű tartalomjegyzékre. Az explicit szakaszazonosítók a
lefordított címek között is használhatóvá teszik a mélyhivatkozásokat. Az eredeti
GUI-feliratok, mintaértékek és kód felismerhetők maradnak, nem fordítjuk őket
más végrehajtható bemenetekké.

A független ellenőrzések: `node ./scripts/management/Test-Documentation.mjs --self-test`
és `node ./scripts/management/Test-Documentation.mjs`. A párok lefedettségét,
a címsorok/táblázatok teljességét, 68 végrehajtható példa és az inline kódliterálok egyezését,
a kölcsönös nyelvi navigációt, helyi célokat/horgonyokat és a nyelvenkénti bejárhatóságot vizsgálják.
Az önellenőrzések a hiányzó párok/célok/horgonyok, rossz nyelvű linkek,
módosult példák/literálok, pár nélküli lapok és elérhetetlen dokumentumok
elutasítását is bizonyítják. A négy magyarázó szöveges ábra feliratait lefordítottuk,
és ezeket a jegyzék kifejezetten felsorolja. A teljes dokumentációs gráf nulla hibával megfelelt.

Ez a folytatás csak dokumentációt és annak független ellenőrzőjét módosítja.
A fenti korábbi alkalmazás-/motoreredmények dátumhoz kötött bizonyítékok maradnak;
a fordításhoz nem állítunk új alkalmazás-, Docker-, telepítő-, böngésző-, natív
asztali vagy Linux-végrehajtást.
