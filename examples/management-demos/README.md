# A három általános Plot Manager demó forrása

Ezek a telepített alkalmazásban bemutatott első három demó hordozható,
változatlan bemeneti konfigurációi. A futáskor keletkező fájlokat nem tartalmazzák.

| Mappa | Alkalmazásbeli név | Plotok |
| --- | --- | --- |
| [01-vezetett-telepito](01-vezetett-telepito) | 01 – Vezetett fájltelepítő | `install` |
| [02-retegek-es-hivatkozasok](02-retegek-es-hivatkozasok) | 02 – Rétegek, típusok és hivatkozások | `show-settings`, `hibas-sorrend` |
| [03-json-xml-zip](03-json-xml-zip) | 03 – JSON, XML és ZIP csomagolás | `package` |

A negyedik, Dockerben futó projekt külön könyvtárban van:
[SenseNet Docker](../sensenet-docker).

**[Teljes magyar demókatalógus, forgatókönyvek és minden lépés magyarázata](../../docs/management-demo-projects-hu.md)**
· **[A teljes GUI felhasználói kézikönyve](../../docs/management-user-guide-hu.md)**

A használathoz a kiválasztott teljes projektmappát másold a Plot Manager
szolgáltatás engedélyezett projektgyökere alá, és nyisd meg a projektválasztó
**Open project** műveletével. A szolgáltatás gépének útvonalát adod meg. A
`plot-project.json` a projektleíró, a három konfigurációs réteg pedig a natív motor
változatlan JSON-formátumát használja.

A másolat önálló projekt: nem követi automatikusan a GitHub-forrást, és a desktop
és browser példányok között sem szinkronizál. Az első három demóhoz nincs szükség
Dockerre vagy külső szolgáltatásra. A kimenetek a saját projektmásolatban
keletkeznek; a részletes útmutató felsorolja őket és az újrafuttatás hatását.
