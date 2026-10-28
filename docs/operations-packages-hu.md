<!-- documentation-anchors:start -->
<a id="doc-generic-operational-packages"></a>
<!-- documentation-anchors:end -->
# Általános üzemeltetési csomagok

<!-- documentation-navigation -->
[English](operations-packages.md) | [Magyar](operations-packages-hu.md) · [Dokumentáció](README-hu.md) · [Projekt](../README-hu.md)
<!-- /documentation-navigation -->

Ezek a csomagok általános műveleteket tesznek elérhetővé alkalmazásspecifikus chartok, szolgáltatások, repository-URL-ek vagy hitelesítő adatok nélkül. A teljes mappáikat telepítsd bármely Auto könyvtár alá. **A Git, Build és Docker csomagoknak a Process csomagra is szükségük van**; a mappanevek eltérhetnek a jegyzékfájlokban szereplő nevektől. A Http független. A meglévő natív futtatókörnyezet, a szekvenciális hibakezelés és a réteges konfiguráció szabályai érvényesek.

<!-- documentation-anchors:start -->
<a id="doc-process-processrun"></a>
<!-- documentation-anchors:end -->
## Folyamat: `process.run`

| Paraméter | Jelentés/alapérték |
| --- | --- |
| FilePath | Kötelező végrehajthatófájl-útvonal vagy a PATH-on található alkalmazásnév |
| Arguments | Egyedi karakterláncok tömbje, alapértéke `[]`; soha nem shell-parancsszöveg |
| WorkingDirectory | Létező könyvtár, alapértéke a WorkDirectory |
| Environment | Csak a gyermekfolyamatra érvényes felülírások; a null érték eltávolít egy örökölt változót |
| TimeoutSeconds | A folyamat és kimenete teljes határideje, 60; tartomány: 1–86400 |
| SuccessExitCodes | Elfogadott egész kilépési kódok, `[0]` |

Az elválasztókat tartalmazó útvonalak a WorkDirectory alapján oldódnak fel. A `.ps1`, `.cmd` és `.bat` fájlokhoz explicit interpreter-végrehajtható szükséges. A shelles végrehajtás le van tiltva; a metakarakterek közönséges argumentumszövegként viselkednek. Az stdin zárt. A kimenet FilePath, ExitCode, StandardOutput, StandardError és DurationMilliseconds mezőket tartalmaz. Mindkét adatfolyamot párhuzamosan olvassa és memóriában puffereli: a lépés véges parancsokhoz készült, nem korlátlan naplógyűjtéshez. A kimenet változatlanul tér vissza, és tartalmazhat a program által kiírt titkokat; a CLI szerializálja azt.

Időtúllépéskor a rendszer megpróbálja leállítani a saját folyamatfáját (modern .NET), illetve PowerShell 5.1 alatt a Windows taskkill parancsot használja. Ha egy folyamat leválik vagy a leszármazottai előtt kilép, nem garantálható, hogy nem maradnak leszármazottak. Az örökölt kimeneti csövekre való várakozás továbbra is korlátos. Az időtúllépés hibát jelent, nem vonja vissza a fájlrendszeren, daemonon vagy külső rendszeren végzett hatásokat. A hibák kihagyják az argumentumokat, a környezetet és a gyermekfolyamat kimenetét; részletes diagnosztikához vizsgáld a sikeres kimenetet, vagy futtasd külön az eszközt. Minden parancs előnézete megtekinthető a plot `-Explain` / `-WhatIf` kapcsolóival.

<!-- documentation-anchors:start -->
<a id="doc-http-and-tcp"></a>
<!-- documentation-anchors:end -->
## HTTP és TCP

| Lépés | Kötelező bemenetek | Opcionális bemenetek | Kimenet |
| --- | --- | --- | --- |
| `http.download` | Url, Destination | Headers `{}`, Sha256 `""`, Overwrite `false`, MaxBytes `1073741824`, TimeoutSeconds `300` | Path, Bytes, Sha256, StatusCode |
| `http.wait` | Url | Headers `{}`, StatusCodes `[200]`, TimeoutSeconds `60`, RequestTimeoutSeconds `5`, IntervalMilliseconds `500` | StatusCode, Attempts, DurationMilliseconds |
| `http.wait-tcp` | HostName, Port | TimeoutSeconds `60`, IntervalMilliseconds `500` | HostName, Port, Attempts, DurationMilliseconds |

A HTTP csak beágyazott hitelesítő adatok nélküli HTTP(S) URL-eket fogad el. A tanúsítványellenőrzés a rendszer alapbeállításait használja; az átirányítások tiltottak, a cookie-kat nem őrzi meg. A kérésfejléceket beállítás- vagy környezeti hivatkozásokkal add át. A HTTP-készenlét a válasz státuszát ellenőrzi, nem az alkalmazás/adatbázis állapotát; a TCP-készenlét csak a kapcsolat létrehozhatóságát bizonyítja.

A letöltés véletlenszerű ideiglenes fájlt ír a cél mellé, korlátozza a deklarált és ténylegesen átvitt bájtokat, ellenőrzi az opcionális SHA256 értéket, majd elérhetővé teszi a fájlt. A cél szülőkönyvtárának léteznie kell. Hiba esetén a meglévő cél érintetlen marad, az ideiglenes fájl törlődik. A sikeres letöltés mindig visszaadja a kiszámított SHA256 értéket. Az Overwrite értéket explicit meg kell adni. A határidő tartalmazza a fejlécek/törzs átvitelét; a helyi fájlrendszer-/hash-művelet szinkron, és az eredmény elérhetővé tétele előtt ellenőrzést kap. A készenléti ellenőrzés az átmeneti státusz- és átviteli hibákat egyetlen teljes határidőn belül újrapróbálja. A hibaeredményekből kimaradnak az URL-ek, fejlécek és választörzsek.

<!-- documentation-anchors:start -->
<a id="doc-git"></a>
<!-- documentation-anchors:end -->
## Git

Minden Git-lépéshez a PATH-on elérhető Git szükséges. A TimeoutSeconds alapértéke 300, az Environment értéke `{}`. A nem interaktív hitelesítést az argumentumszövegeken kívül állítsd be (például meglévő credential helperrel és a gyermekfolyamat környezetével).

| Lépés | Bemenetek | Viselkedés |
| --- | --- | --- |
| `git.clone` | Repository, Destination, opcionális Branch `""` | A Destination még nem létezhet; hiba esetén nincs automatikus törlés |
| `git.fetch` | Directory, opcionális Remote `"origin"` | Egy remote tartalmát tölti le; nem merge-el, prune-ol vagy resetel |
| `git.checkout` | Directory, Ref | Tiszta munkafát igényel, a nem követett fájlokat is beleértve; detached HEAD állapotot állít be |

A Directory/Destination a WorkDirectory alapján oldódik fel. A remote/revízió operandusok nem kezdődhetnek `-` karakterrel. A kimenetek a folyamat-eredményszerződést használják. A sikertelen klónozás részleges célkönyvtárat hagyhat vizsgálatra; válassz új könyvtárat, vagy felülvizsgálat után explicit töröld a maradványt. A Git hookokat és a repository végrehajtható tartalmát továbbra is a telepített Git/eszköz konfigurációja szabályozza.

<!-- documentation-anchors:start -->
<a id="doc-build-and-nuget"></a>
<!-- documentation-anchors:end -->
## Build és NuGet

A PATH-on elérhető `dotnet` szükséges; nincsenek beégetett SDK-/Visual Studio-útvonalak vagy csomaglisták. Mindkét lépés fogadja a Directory (`.`), Arguments (`[]`), TimeoutSeconds (`300`) és Environment (`{}`) értékeket. Minden útvonal a WorkDirectory alapján oldódik fel. Az Arguments az eszköz natív argumentumvektora; nem történik karakterlánc-feldarabolás.

- `build.dotnet`: Project (létező projekt-/solution-útvonal), Command (`build`; megengedett: restore, build, test, publish, pack). A futtatott parancs: `dotnet <Command> <absolute Project> <Arguments...>`.
- `build.nuget`: Command (push, delete, list, locals, add, remove, update, enable, disable). A futtatott parancs: `dotnet nuget <Command> <Arguments...>`. Csomag-visszaállításhoz/-készítéshez a `build.dotnet` restore/pack parancsait használd. A feed és API-kulcs beállításait az üzemeltető adja meg.

A kimenetek a folyamat-eredményszerződést használják. A restore/build/test/publish projektben definiált kódot futtathat és kapcsolatba léphet a konfigurált feedekkel. Ha ez a szándék, használj natív eszközkapcsolókat, például `--no-restore` értéket vagy explicit helyi forrást.

<!-- documentation-anchors:start -->
<a id="doc-docker"></a>
<!-- documentation-anchors:end -->
## Docker

A `docker.cli` kötelező paramétere a Command; további paraméterei: Arguments (`[]`), Directory (`.`), TimeoutSeconds (`300`), Environment (`{}`). A PATH-on elérhető Docker CLI és a kiválasztott daemon/context szükséges. Megengedett parancsok:

- Image: build, pull, tag, push, inspect.
- Container: run, start, stop, rm.
- Network: network-create, network-inspect, network-connect, network-disconnect, network-rm (a megfelelő `docker network <verb>` parancsra képezve).

Az argumentumokat egyedi karakterláncokként adja át. Az erőforrásneveket, tageket, útvonalakat, portokat és kapcsolókat a plot adja meg. A kimenetek a folyamat-eredményszerződést használják. Nincs implicit takarítás vagy teljes daemonra kiterjedő prune. Időtúllépéskor a CLI-folyamat áll le; a Docker daemon által már elfogadott művelet folytatódhat. A többkonténeres életciklus-lépéseket a külön [compose csomag](platform-packages-hu.md#doc-docker-compose-compose) biztosítja.

<!-- documentation-anchors:start -->
<a id="doc-configuration-example-and-commands"></a>
<!-- documentation-anchors:end -->
## Konfigurációs példa és parancsok

A `src/Deployment/Scripts/Examples/operations.json` külön forrás/build, konténerbuild és készenléti plotokat tartalmaz. A Values szakaszát projekt-/környezeti fájlokon keresztül igazítsd a saját igényeidhez. Minden példa helykitöltő útvonalakat és végpontokat használ.

```powershell
# Inspect without requiring executable tools or contacting endpoints.
./src/Deployment/Scripts/Run.ps1 source-build -ConfigPath ./src/Deployment/Scripts/Examples/operations.json -Explain

# After supplying your project paths/settings and installing the required tools:
./src/Deployment/Scripts/Run.ps1 source-build -DefaultConfigPath ./src/Deployment/Scripts/Examples/operations.json -ConfigPath ./my-project.json -WorkDirectory ./work
```

A teszteket a `pwsh -NoProfile -File ./tests/Run-Tests.ps1` és `powershell.exe -NoProfile -File ./tests/Run-Tests.ps1` parancsokkal futtasd. A tesztek helyi folyamatokat, loopback HTTP/TCP tesztkörnyezetet, valódi elkülönített Git repositoryt és helyettesített build/Docker függőségi parancsokat használnak. Nem ellenőriznek éles telepítést, és nem hajtanak végre Docker-daemonműveleteket.
