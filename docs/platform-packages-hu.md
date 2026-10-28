<!-- documentation-anchors:start -->
<a id="doc-sql-server-iis-web-maintenance-and-compose"></a>
<!-- documentation-anchors:end -->
# SQL Server, IIS, webes karbantartás és Compose

<!-- documentation-navigation -->
[English](platform-packages.md) | [Magyar](platform-packages-hu.md) · [Dokumentáció](README-hu.md) · [Projekt](../README-hu.md)
<!-- /documentation-navigation -->

A natív futtatókörnyezetben jelenleg **14 csomag / 49 lépés** érhető el. Ezek a csomagok explicit beállításokkal általános platformműveleteket valósítanak meg; nem tartalmaznak alkalmazásspecifikus chartot, szerverlistát, hitelesítő adatokat vagy adatbázissémát. Minden lépés önállóan is használható a `Run.ps1 -Step <id> -Params '{"single":{...}}'` paranccsal.

<!-- documentation-anchors:start -->
<a id="doc-sql-server-sqlserver"></a>
<!-- documentation-anchors:end -->
## SQL Server (`sqlserver`)

A PowerShell hostban elérhető `System.Data.SqlClient` szükséges (Windows PowerShell 5.1 és PowerShell 7 alatt ellenőrizve). Nem igényel SMO-t, SqlServer PowerShell-modult vagy sqlcmd-t. Ez a csomag SQL Servert céloz, nem minden SQL-dialektust vagy az Azure SQL Database korlátozott DDL-/mentési lehetőségeit.

Minden lépéshez titkos `ConnectionString` szükséges. Hitelesítő adatok commitolása helyett környezeti hivatkozást használj. Az integrált és az SQL-hitelesítés ezt a kapcsolati karakterláncot követi. A titkosítás és a tanúsítványellenőrzés szintén a kapcsolati karakterlánc beállítása. A `ConnectTimeoutSeconds` alapértéke 15, a `CommandTimeoutSeconds` értéke 60; egyik sem enged végtelen időkorlátot.

| Lépés | A kapcsolat/időkorlát mellett megadható beállítások | Viselkedés |
| --- | --- | --- |
| `sqlserver.query` | Query, Parameters={}, MaxRows=10000 | Egy T-SQL köteget hajt végre, minden eredményhalmazt Columns és Rows tömbként ad vissza, az összesített RowCount értékkel együtt. Az ismétlődő oszlopnevek és az SQL NULL megmaradnak. |
| `sqlserver.execute` | Query **vagy** Path, Parameters={} | Egy T-SQL köteget vagy helyi UTF-8 szkriptet hajt végre; AffectedRows értékkel tér vissza (DDL esetén ez -1 is lehet). |
| `sqlserver.wait` | TimeoutSeconds=60, IntervalMilliseconds=1000 | Hitelesített `SELECT 1` végrehajtását próbálja újra a konfigurált adatbázison. |
| `sqlserver.create` | Database, RecoveryModel=SIMPLE | Új adatbázist hoz létre; meglévő név esetén hibát jelez. FULL és BULK_LOGGED is elfogadott. |
| `sqlserver.drop` | Database | Törli a megnevezett felhasználói adatbázist; nem kényszeríti ki más munkamenetek bontását. |
| `sqlserver.backup` | Database, Path, CopyOnly=true, Initialize=false | CHECKSUM mentés egy SQL Server oldali fájlba. Mentési készletet fűz hozzá, hacsak az Initialize explicit nem kér adathordozó-felülírást. |
| `sqlserver.restore` | Database, Path, Moves, Replace=false, BackupSet=1 | CHECKSUM visszaállítás a logikai nevek és szerveroldali útvonalak explicit leképezésével. A lecserélést külön engedélyezni kell. |
| `sqlserver.configure-file` | Database, LogicalName, SizeMb, MaxSizeMb, GrowthMb=64 | Egy explicit megnevezett fájl méretét, maximális méretét és növekedését állítja MB-ban. Nem zsugorítja a fájlt, és nem deríti fel implicit az összes fájlt. |
| `sqlserver.login` | Action=create/drop, LoginName, Password a create művelethez | Jelszóházirenddel védett SQL-hitelesítésű bejelentkezést hoz létre, vagy törli azt. A beépített sa kizárt. |
| `sqlserver.user` | Database, Action=create/drop, UserName, LoginName a create művelethez, Roles=[] | Egy adatbázis-felhasználót meglévő bejelentkezéshez rendel, és csak a megnevezett szerepköröket adja meg; a felhasználó/szerepkör létrehozása tranzakciós. |

A Parameters skalár ADO.NET parancsparamétereket tartalmaz, `@` előtaggal vagy anélkül. A generált adminisztrációs utasítások azonosítói és szerveroldali útvonalai külön escape-elést kapnak. A lekérdezésszöveg megbízhatónak tekintett üzemeltetői bemenet, és a `query` műveletben is módosíthat adatbázist; ez nem csak olvasásra használható SQL-sandbox. Az SQLCMD `GO`, `:r` és változóhelyettesítés nem támogatott: a szkripteket egymás utáni `sqlserver.execute` hívásokra bontsd. Letöltött szkriptekhez a `http.download` (opcionálisan SHA256 ellenőrzéssel) és a `sqlserver.execute` kapcsolható össze.

A providerszintű hibák kihagyják a kapcsolati karakterláncot, az SQL-t és a provider nyers üzeneteit. Részletekért használd az SQL Server diagnosztikáját. A sikeres lekérdezések eredménye érzékeny adatokat tartalmazhat, ezért tudatosan válassz lekérdezést és kimeneti célt. A sorkorlát a sorok számát korlátozza, nem az eredmény teljes bájtméretét. A készenléti határidőnél a provider időkorlát-kerekítése legfeljebb két másodperces eltérést okozhat; a parancsidőkorlát a provider végrehajtási/olvasási időkorlátja, nem tranzakció-visszagörgetési garancia.

A mentési/visszaállítási útvonalak az **SQL Server gépéhez/konténeréhez** tartoznak, nem a WorkDirectory értékéhez. A query műveleten keresztüli `RESTORE FILELISTONLY` segítségével kérdezd le az összes logikai nevet; ne feltételezd, hogy megegyeznek az adatbázis nevével. A [Microsoft RESTORE referenciája](https://learn.microsoft.com/en-us/sql/t-sql/statements/restore-statements-transact-sql) ismerteti a MOVE/CHECKSUM/REPLACE lehetőségeket. A generált adatbázis-kezelő lépések kizárják a rendszeradatbázisokat. Az explicit `query`/`execute` továbbra is általános célú.

A `create` a helyreállítási modell beállítását is tartalmazza; a létrehozás utáni providerhiba mellett az adatbázis már létezhet. Nincs automatikus törlés/visszaállítás egy részlegesen befejezett adminisztrációs művelet után. Az SQL-felhasználók és a szerverbejelentkezések külön műveletek; nincs implicit db_owner vagy teljes szerverre érvényes jogosultságadás.

Lásd: [database.json](../src/Deployment/Scripts/Examples/platform/database.json). A `PLOT_SQL_CONNECTION` értékét helyi titokkezeléssel add meg, a Values értékeit pedig valódi adatbázisnevekkel és szerverútvonalakkal írd felül. A példa készenlétet, létrehozást, mentést, külön adatbázisba történő visszaállítást és query–JSON exportot tartalmaz. Több adatbázishoz adatbázisonként egy explicit nevű mentési hívást használj; nincs implicit teljes szerveres felderítés vagy tömeges törlés.

<!-- documentation-anchors:start -->
<a id="doc-iis-and-web-maintenance"></a>
<!-- documentation-anchors:end -->
## IIS és webes karbantartás

Az IIS-lépésekhez Windows, IIS/WebAdministration és megfelelő helyi jogosultság szükséges. Ha a PowerShell 7 hostban nem érhető el a WebAdministration, az IIS-gépen Windows PowerShell 5.1-et használj. A natív futtatókörnyezet/csomagok tesztjei mindkét shellt lefedik; a WebAdministration elérhetősége külön platformfeltétel.

- `iis.create`: WebsiteName, AppPoolName, létező PhysicalPath; Port=80, IPAddress=*, HostHeader='', RuntimeVersion='' (nincs felügyelt futtatókörnyezet; v2.0/v4.0 is támogatott), PipelineMode=Integrated (vagy Classic). Dedikált alkalmazáskészletet és HTTP-webhelyet hoz létre. Meglévő webhely/készlet vagy azonos kötés esetén hibát jelez. Nem módosít más készleteket, nem telepít IIS-t, nem konfigurál TLS-tanúsítványokat, és nem ad fájlrendszer-ACL-eket. A New-Website az IIS szokásos indulási viselkedését alkalmazza. Ha a létrehozás a készlet elkészülte után sikertelen, újrapróbálás előtt vizsgáld meg és távolítsd el az új készletet; nem fut széles körű visszaállítás.
- `iis.status`: WebsiteName. Visszaadja a webhely állapotát, a készlet nevét/állapotát és a fizikai útvonalat; hiányzó webhelynél hibát jelez.
- `iis.recycle`: AppPoolName, TimeoutSeconds=30, PollMilliseconds=200. Újraindítást kér, és megvárja a készlet Started állapotát. Ez nem bizonyítja az alkalmazás bemelegedését; ezt kövesse `http.wait` egy alkalmazásszintű egészségvégponton.
- Az `iis.start` / `iis.stop` megtartja a meglévő, korlátos webhely-/készletéletciklus-viselkedést.
- `web.offline`: létező Directory, Content='Maintenance in progress.'. Létrehozza az `app_offline.htm` fájlt, meglévő karbantartási oldal felülírása nélkül.
- `web.online`: Directory. Ezt a konkrét karbantartási oldalt távolítja el; a hiányzó oldal már online állapotot jelent.

A web csomag csak az ASP.NET karbantartásifájl-konvencióját kezeli. Az alkalmazás hostjának ezt tiszteletben kell tartania. Nem állít le tetszőleges webszervereket, és nem ad hozzáférési jogokat. A `web.online` az explicit kiválasztott könyvtárból eltávolítja az oldalt attól függetlenül, hogy eredetileg ki hozta létre.

Az [iis.json](../src/Deployment/Scripts/Examples/platform/iis.json) create, deploy, status, recycle és recover-online plotokat tartalmaz. A deploy offline állapotba teszi az alkalmazást, bemásol egy előkészített csomagot, online állapotba hozza, és ellenőrzi a HTTP-készenlétet. **A másolási hiba leállítja a plotot, és szándékosan bekapcsolva hagyja a karbantartást.** Vizsgáld meg a részleges telepítést, állítsd helyre/javítsd a fájlokat, majd futtasd a recover-online plotot. A telepítési csomag nem tartalmazhat `app_offline.htm` fájlt; a könyvtármásolás összefésüli a fájlokat, és nem törli az elavult célfájlokat. Szükség szerint külön, korlátozott hatókörű törlést vagy verziózott telepítési könyvtárat használj. XML-konfiguráció módosításához továbbra is rendelkezésre áll az `xml.set`.

<!-- documentation-anchors:start -->
<a id="doc-docker-compose-compose"></a>
<!-- documentation-anchors:end -->
## Docker Compose (`compose`)

Lépések: `compose.config`, `pull`, `build`, `up`, `ps`, `logs`, `stop`, `down`. Függőségként deklarálja a `process` csomagot. Compose-támogatással rendelkező Docker CLI és a kívánt Docker context elérése szükséges.

Minden lépéshez `ProjectName` és nem üres, rendezett `Files` lista szükséges. Opcionális beállítások: Directory='.', EnvFiles=[], Profiles=[], Services=[], Arguments=[], Environment={}, TimeoutSeconds=300. A relatív fájl-/env-fájlútvonalak a Directory alapján, az pedig a WorkDirectory alapján oldódik fel. A fájlsorrend megmarad. A fájloknak létezniük kell; a projektnevek a Compose kisbetűs névszabályait követik. A környezeti értékeket csak a gyermekfolyamat kapja meg.

Az `up` tartalmazza a `--detach` kapcsolót; futó/egészséges készenléthez add át az `Arguments: ["--wait", "--wait-timeout", "30"]` értéket a [Docker up referenciájának](https://docs.docker.com/reference/cli/docker/compose/up/) megfelelően. A `down` nem ad hozzá kötettörlést vagy árva erőforrások eltávolítását. A további natív Arguments értékek megbízhatónak tekintett üzemeltetői döntések, és romboló műveletet is kérhetnek. Az adapter mindig explicit projekt-/fájl-/könyvtárkapcsolókat ad meg; ezt a hatókört ne írd felül további globális opciókkal. Nem fut teljes daemonra kiterjedő prune.

A kimenetek a process.run szerződését követik (ExitCode, StandardOutput, StandardError). A `compose.config` kimenete behelyettesített titkokat tartalmazhat; kizárólag ellenőrzéshez a `--quiet` kapcsolót használd. Időtúllépéskor a kliens áll le; a daemon által már elfogadott módosítások folytatódhatnak. A `logs --follow` ugyanazon kliensidőkorláton belül marad.

A [compose.json](../src/Deployment/Scripts/Examples/platform/compose.json) és [compose.yaml](../src/Deployment/Scripts/Examples/platform/compose.yaml) validate/up/status/down plotokat ad. A WorkDirectory értékét a platformpéldák könyvtárára állítva futtasd. A példa a localhost:18080 címet köti, és általános nginx image-et használ; elérhető/szabad portot igényel, és letöltheti az image-et.

<!-- documentation-anchors:start -->
<a id="doc-general-workflow-equivalents"></a>
<!-- documentation-anchors:end -->
## Általános munkafolyamat-megfelelők

| Korábbi képesség | Natív összeállítás |
| --- | --- |
| Adatbázis-kapcsolat / hitelesítőadat-ellenőrzés / várakozás | sqlserver.wait (hitelesített adatbázis-művelet, nem pusztán TCP-ellenőrzés) |
| SQL-lekérdezés exportja / letöltött SQL végrehajtása | sqlserver.query -> json.write; http.download -> sqlserver.execute |
| Üres DB / fájlméretek / felhasználók / mentés / visszaállítás / törlés | A fenti dedikált sqlserver lépések |
| Automatikus dátumozott vagy többadatbázisos mentések | Explicit plot-hívásazonosítók és a hívó által megadott útvonalak; a plotot az üzemeltető ütemezője időzítse |
| IIS-webhely létrehozása / életciklus / ellenőrzés / bemelegítés | iis.create/start/stop/status/recycle -> http.wait |
| Alkalmazás offline / másolásos telepítés / alkalmazás online | web.offline -> filesystem.copy-tree -> web.online -> http.wait |
| Build / publish / csomagolás / csomagletöltés | A meglévő build, archive, filesystem és http csomagok |
| Kapcsolat-/konfigurációmódosítás | json.merge, json.write és xml.set az alkalmazás saját kulcsaival/értékeivel |
| Többkonténeres helyi életciklus | compose config/up/ps/logs/stop/down |
| GUI-katalógus / plot-végrehajtás | Strukturált helyi protokoll és Windows host a [helyi integrációban](local-integration-hu.md) |

Ez képességmigráció, nem bináris kompatibilitás minden történeti lépésnévvel, és nem ígéret arra, hogy minden történeti forgatókönyv változatlanul fut. A külső ütemezők, távoli Windows-elérés, hosts-fájl-/tűzfal-/ACL-adminisztráció és az alkalmazásspecifikus telepítés/indexelés/import/export továbbra is explicit konfigurált eszközöket vagy saját adaptereket igényel; a process.run elindíthatja ezeket, de nem biztosítja a területük saját szemantikáját. A megtartott legacy futtató külön marad. A csomag nem tartalmaz vállalati konfigurációt vagy alkalmazásspecifikus Helm chartot.
