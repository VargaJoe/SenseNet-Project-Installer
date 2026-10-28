<!-- documentation-anchors:start -->
<a id="doc-sensenet-docker-project-for-plot-manager"></a>
<!-- documentation-anchors:end -->
# SenseNet Docker projekt a Plot Managerhez

<!-- documentation-navigation -->
[English](README.md) | [Magyar](README-hu.md) · [Dokumentáció](../../docs/README-hu.md) · [Projekt](../../README-hu.md)
<!-- /documentation-navigation -->

Valódi, helyi fejlesztői SenseNet telepítés: SQL Server Developer, SenseNet repository és IdentityServer. A projekt a meglévő `compose`, `process`, `json` és `filesystem` csomagokat használja. A Plot Manager motorja és konfigurációs formátuma változatlan.

<!-- documentation-anchors:start -->
<a id="doc-starting-from-the-application"></a>
<!-- documentation-anchors:end -->
## Indítás az alkalmazásból

1. Másold ezt a teljes könyvtárat a futtató Plot Manager projektgyökerébe, és nyisd meg a **Open project** művelettel. A `.local` könyvtárat ne másold másik projekthez.
2. A **Guided setup** felületen adj meg egy egyedi `pm-sensenet-…` Compose-nevet és két szabad portot. A beállítások a szokásos `project.json` rétegbe kerülnek.
3. A Microsoft SQL Server Developer használati feltételeinek elfogadása után ments, ellenőrizd a preflightot, és indítsd az `install` plotot. A Developer kiadás fejlesztésre/tesztelésre való. [Microsoft konténeres SQL útmutató](https://learn.microsoft.com/en-us/sql/linux/quickstart-install-connect-docker).
4. Az eredményben a repository és a bejelentkezési szolgáltatás URL-je, az OData ellenőrzés és a tényleges adminbejelentkezés eredménye jelenik meg. Az első repository-inicializálás több percig tarthat.

Feltétel: Docker Engine Linux-konténerekkel, Docker Compose v2, PowerShell 7.2 vagy újabb a futtató gép PATH-ján; szabad memória és lemezterület a SQL Serverhez. A stepek a Plot Manager szolgáltatás gépén és felhasználójával futnak. Hostolt Plot Managernél a localhost URL-ek a szerverhez tartoznak.

<!-- documentation-anchors:start -->
<a id="doc-operations"></a>
<!-- documentation-anchors:end -->
## Műveletek

| Plot | Eredmény |
|---|---|
| `prepare` | Validálás, saját helyi jelszavak és HTTPS-tanúsítvány létrehozása egyszer. |
| `install` | Előkészítés, Compose-validálás, szolgáltatások indítása, OData + valódi PKCE adminlogin ellenőrzése. |
| `start`, `restart` | Indítás vagy újraindítás és hitelesített ellenőrzés. |
| `status`, `logs` | Saját szolgáltatások állapota, illetve az utolsó 80 naplósor szolgáltatásonként. |
| `verify` | Aktív kapcsolatteszt, OpenID discovery és bejelentkezés, hitelesített Admin tartalomolvasás. |
| `demo-content` | Saját mintamappa létrehozása/olvasása az OData API-val. Az ID újrafuttatáskor megmarad. |
| `verify-demo-content` | A korábban létrehozott mintamappa meglétének ellenőrzése; hiány esetén hibázik. |
| `stop` | Konténerek leállítása, adatok megőrzése. |
| `backup` | A saját stack leállítása után a teljes SQL és App_Data volume hidegmentése, hash-manifesttel; a korábban futó szolgáltatások visszaindítása. |
| `restore` | Kiválasztott saját mentés visszaállítása explicit névmegerősítéssel, majd indítás és ellenőrzés. A jelenlegi saját adatokat lecseréli. |
| `remove-containers-keep-data` | Saját konténerek és hálózat eltávolítása; a named volume-ok, titkok és mentések megmaradnak. Az `install` visszaindítja. |

Az előnézet/WhatIf statikus ellenőrzés; nem próbál bejelentkezni, nem vizsgál Docker-portfoglalást és nem készít mentést. Egyedi stepek futtatása előtt vedd figyelembe az előkészítés eredményeként létrejövő fájlokat. Teljes plothoz használd a teljes futtatást.

<!-- documentation-anchors:start -->
<a id="doc-data-https-and-secrets"></a>
<!-- documentation-anchors:end -->
## Adatok, HTTPS és titkok

Az alkalmazás saját AppData-projektkönyvtárában élő másolat a munkapéldány; a telepítési könyvtár és a forráscheckout nem automatikus konfigurációforrás. `default.json` → `project.json` → `environments/development.json` a változatlan konfigurációs sorrend.

Docker volume-ok: `<stack>_db-data` (`/var/opt/mssql`) és `<stack>_app-data` (`/app/App_Data`). SQL-port nincs publikálva. A repository és az IdentityServer kizárólag a gép loopback interfészén érhető el.

A generált `.local` könyvtár csak az aktuális operációsrendszer-felhasználónak olvasható: benne a helyi runtime-env, a PFX magánkulcs, az előkészítés állapota és a mentések. Ez szándékosan nincs Gitben. **A mentés is érzékeny adat**, mert adatbázist és a visszaállításhoz szükséges helyi titkokat tartalmazza. A forrásbeli JSON-ok csak publikus paramétereket tartalmaznak. A Dockerhez hozzáférő felhasználó a konténerek konfigurációját olvasni tudja.

A localhost tanúsítványt a script nem telepíti az OS tanúsítványtárába. A script HTTP-kliense kizárólag a projekthez generált tanúsítványt fogadja el, hostnév-ellenőrzéssel; más hibás tanúsítványt elutasít. A böngészőben a saját fejlesztői tanúsítványhoz tartozó figyelmeztetés várható. Külső/éles HTTPS-hez külön, valódi tanúsítvány és telepítési konfiguráció szükséges.

A hivatalos friss repository demófiókja **admin / admin**. A beépített automatikus ellenőrzés ezt a helyi demófiókot használja. Módosított jelszóhoz ments `SENSENET_ADMIN_PASSWORD` nevű Runner secretet, majd az `Authentication.AdminPassword` beállítást írd át `{"$env":"PLOTMANAGER_SECRET_SENSENET_ADMIN_PASSWORD"}` hivatkozásra. A jelszót a natív process lépés külön környezeti változóként, a futás pillanatképéhez rögzítve kapja; ez a beállítás nincs benne a generált runtime-JSON-ban. CLI esetén ugyanilyen nevű környezeti változó használható.

Ez a minta fejlesztői használatra készült; internetre publikálása és üzemi hitelesítésre átállítása külön feladat. A név és a portok az első előkészítés után rögzítettek: új példányhoz új projektmásolat, másik név és portok kellenek. Az image-ek SHA-256 digesttel rögzítettek, így egy mozgó `preview` vagy `latest` tag újrafuttatáskor nem frissíti őket észrevétlenül.

Az ellenőrzéshez külön `plotmanager-adminui` PKCE-kliens tartozik, kizárólag a saját repository localhost címére mutató visszahívással. Az ellenőrző script a visszahívási átirányításból olvassa ki a kódot, nem navigál a címre. Külső vagy külön telepített Admin UI csatlakoztatásához további, az adott felület pontos originjére és callbackjére vonatkozó konfiguráció szükséges; ez a projekt ilyen külső hozzáférést nem engedélyez.

<!-- documentation-anchors:start -->
<a id="doc-backup-and-restore"></a>
<!-- documentation-anchors:end -->
## Mentés és visszaállítás

Futtasd a `backup` plotot. A kimenet és a `.local/backups` könyvtár mutatja az elkészült mentést. A `project.json` rétegben állítsd be:

```json
{
  "Restore": {
    "BackupPath": ".local/backups/A-MENTES-KONYVTARA",
    "ConfirmStackName": "pm-sensenet-a-sajat-stack-neve"
  }
}
```

Ezután `restore`. A névnek pontosan az előkészített stack nevének kell lennie. A művelet a mentés hash-eit és a saját stackhez tartozását a visszaállítás előtt ellenőrzi. A restore után töröld ezt a két felülírást vagy állítsd üresre. Ez az első változat ugyanahhoz a stackhez és azonos rögzített image-ekhez tartozó helyi mentést támogat; új verzióra adatbázis-frissítést nem végez.

<!-- documentation-anchors:start -->
<a id="doc-cli"></a>
<!-- documentation-anchors:end -->
## CLI

A saját Plot Manager checkout gyökeréből, a `project.json` kitöltése után:

```powershell
pwsh -NoProfile -File ./src/Deployment/Scripts/Run.ps1 install `
  -DefaultConfigPath ./examples/sensenet-docker/default.json `
  -ConfigPath ./examples/sensenet-docker/project.json `
  -EnvironmentConfigPath ./examples/sensenet-docker/environments/development.json `
  -WorkDirectory ./examples/sensenet-docker
```

Az `install` helyére bármelyik fenti plot neve írható. Előnézethez `-WhatIf`. Az alkalmazásba másolt projekt CLI-futtatásakor mindhárom fájlútvonal és a WorkDirectory arra a másolatra mutasson.

<!-- documentation-anchors:start -->
<a id="doc-public-foundation-and-boundaries"></a>
<!-- documentation-anchors:end -->
## Publikus alap és határok

A friss, önálló projekt a hivatalos [SenseNet perzisztens Compose forgatókönyv](https://github.com/SenseNet/sensenet/blob/f889cfce16e724ad095d4ca976a2e0d7fa362c26/deployment/docker-compose.with-volume.yml), [szolgáltatásdefiníciók](https://github.com/SenseNet/sensenet/blob/f889cfce16e724ad095d4ca976a2e0d7fa362c26/deployment/compose.services.yml) és [IdentityServer PKCE teszt](https://github.com/SenseNet/sensenet/blob/f889cfce16e724ad095d4ca976a2e0d7fa362c26/deployment/tests/Test-IdentityServerLogin.ps1) publikus szerződéseire épül. Céges telepítőből nincs átvett kód vagy konfiguráció.

Nincs automatikus image-frissítés, éles közzététel, többgépes telepítés vagy volume-törlő reset plot. A Plot Manager futásmegszakítása nem jelent Docker-rollbacket. A projekt saját scriptjei és Compose-fájljai külső bemeneti fájlok: futás közben ezeket ne szerkeszd; a motor és a JSON-rétegek futási pillanatképe nem fagyasztja be ezeket a fájlokat.
