# Plot Manager bemutatóprojektek

Ezek a repóhoz tartozó, újra használható mintaprojektek. A bemenetek verziózottak,
a generált eredményfájlok, helyi jelszavak és mentések nem részei a forrásnak.
A projektek célja, hogy a Plot Manager működését friss projektmásolatokon is
lépésről lépésre be lehessen mutatni.

| Demó | Forrás | Bemutatott képesség |
|---|---|---|
| 01 – Vezetett fájltelepítő | [Projekt](management-demos/01-vezetett-telepito) | Vezetett kérdések, mentett beállítások, outputfüggőség és tényleges fájlírás. |
| 02 – Rétegek, típusok és hivatkozások | [Projekt](management-demos/02-retegek-es-hivatkozasok) | Default/projekt/environment, értéktípusok és öröklés, szándékosan hibás sorrend felismerése. |
| 03 – JSON, XML és ZIP csomagolás | [Projekt](management-demos/03-json-xml-zip) | Kilenc lépéses fájlgenerálás, csomagolás, hash és visszaellenőrzés. |
| 04 – SenseNet Docker telepítés és menedzsment | [Projekt](sensenet-docker) | Egy valódi alkalmazás telepítése, kezelése, hitelesített ellenőrzése és mentése/visszaállítása. |

**[Magyar dokumentáció – itt kezdd](../docs/management-guide-index-hu.md)**
· [Minden demó, forgatókönyv és step](../docs/management-demo-projects-hu.md)
· [Minden GUI-oldal, gomb és panel](../docs/management-user-guide-hu.md)

Az első háromhoz csak a Plot Manager natív csomagjai kellenek. A negyedik saját
Docker Linux-konténereket és adattárolókat hoz létre; a feltételeit és adatot
cserélő restore műveletét futtatás előtt olvasd el.

Az alkalmazásba felvett munkapéldány a repó tiszta mintájától független. Új
bemutatóhoz másold a megfelelő teljes projektkönyvtárat a szolgáltatás engedélyezett
projektgyökere alá, majd a **Workspace → Open project** mezőben add meg a másolat
útvonalát a futtató gépen. A repóba helyezés önmagában nem regisztrálja a projektet
minden desktop/böngészős adattárban. SenseNethez mindig új nevet és szabad portokat
válassz; a `.local` könyvtárat ne másold másik példányhoz.
