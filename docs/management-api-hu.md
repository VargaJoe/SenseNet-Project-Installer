<!-- documentation-anchors:start -->
<a id="doc-management-api-protocol-1"></a>
<!-- documentation-anchors:end -->
# Management API, 1. protokoll

<!-- documentation-navigation -->
[English](management-api.md) | [Magyar](management-api-hu.md) · [Dokumentáció](README-hu.md) · [Projekt](../README-hu.md)
<!-- /documentation-navigation -->

A .NET 8 szolgáltatás ugyanarról az originről szolgálja ki a közös React-klienst és az `/api` útvonalat. Minden JSON-burkolat lower camel case elnevezést használ. Az `engine` mezőben található natív motorválaszok megtartják PascalCase tulajdonságneveiket. A hibák formája `{error, code}`. A támogatott futtató a szolgáltatáshost; a böngésző soha nem ér el tetszőleges localhost-szolgáltatásokat.

A hitelesítéshez használd a `POST /api/session` `{token}` kérést és a `credentials: 'include'` beállítást. Minden módosító kérésnek, a bejelentkezést is beleértve, el kell küldenie az `X-Plot-Request: 1` fejlécet; ha van Origin, annak egyeznie kell a szolgáltatás originjével. Ez loopback esetén is érvényes. A cookie-k HttpOnly, SameSite=Strict tulajdonságúak, hostolt HTTPS módban Secure beállítással.
A natív asztali/CLI-kliensek ehelyett `Authorization: Bearer TOKEN` fejléccel is hitelesíthetnek; a böngészők a kezdeti hitelesítési fragmentet cookie-ra cserélik, majd törlik a fragmentet. A token cseréje érvényteleníti a meglévő cookie-munkameneteket. Mindkét forma megköveteli a módosításjelölőt és a same-origin ellenőrzést.

| Metódus és útvonal | Kérés / válasz |
| --- | --- |
| `GET /api/session` | `{authenticated,user,mode}`; nem igényel hitelesítést |
| `POST /api/session` | `{token}` -> munkamenet; 401 érvénytelen kezdeti/üzemeltetői token esetén |
| `DELETE /api/session` | kijelentkezés |
| `GET /api/runner` | `{id,displayName,os,identity,protocolVersion,powerShell,mode,executionTarget:'service-host'}` |
| `GET /api/catalog` | `{engine:{ProtocolVersion,Steps,Packages}}` |
| `GET /api/browse?path=...` | a futtató gépének könyvtárai az engedélyezett projektgyökéren belül: `{path,entries:[{name,path,isDirectory}],allowedRoot}` |
| `GET /api/projects` | a hitelesített felhasználó tulajdonában álló `{projects:[project]}` |
| `POST /api/projects` | `{name,directory?,template?:'generic'}` üres projektet hoz létre; explicit `generic` esetén kitölti a vezetett mintát. A Directory alapértéke az engedélyezett gyökér biztonságos új alkönyvtára. A projektet adja vissza |
| `POST /api/projects/open` | `{directory}` meglévő `plot-project.json` fájlt nyit meg az engedélyezett gyökéren belül. A projektet adja vissza |
| `GET /api/projects/{id}` | projekt |
| `GET /api/projects/{id}/definition` | `{etag,data}` eredeti hordozható projektdefiníció |
| `PUT /api/projects/{id}/definition` | `{etag,data}` módosítja a nevet, réteg-hozzárendeléseket vagy varázsló-metaadatokat az ismeretlen tulajdonságok eldobása nélkül; ellenőrzi a hozzárendelt JSON-fájlokat és útvonalakat. 409 elavult etag vagy aktív futás esetén |
| `GET /api/projects/{id}/layers?environment=development` | `{layers:[{id,label,path}],environment}`. Azonosítók: `default`, `project`, `environment:NAME` |
| `GET /api/projects/{id}/layers/{layerId}` | `{id,path,etag,data}`; a `data` az eredeti JSON-objektum |
| `PUT /api/projects/{id}/layers/{layerId}` | `{etag,data}` explicit kiválasztott réteggel. 409 módosítás vagy futás esetén. Az ismeretlen tulajdonságok és JSON-típusok megmaradnak; örökléshez töröld a tulajdonságot |
| `POST /api/projects/{id}/environments` | `{name}` környezeti réteget hoz létre, és frissíti a hordozható definíciót |
| `POST /api/projects/{id}/uploads` | `{name,contentBase64}` a böngészőből explicit feltöltött fájlt menti a projekt `uploads/` könyvtárába; eredménye `{path,relativePath}`. Ez különbözik a futtatóoldali tallózástól |
| `GET /api/projects/{id}/configuration?environment=development` | `{engine:{Configuration,Sources,Layers}}`; a környezeti/titkos hivatkozásokat tartalmazó értékek hivatkozások maradnak |
| `POST /api/projects/{id}/plan` | `{plot,environment,overrides:{invocationId:{Parameter:value}},invocationId?}` -> `{engine}`. Csak statikus előzetes ellenőrzés; nem kapcsolódik a lépések szolgáltatásaihoz |
| `POST /api/projects/{id}/runs` | `{plot,environment,overrides,invocationId?,whatIf:false}` -> futás, HTTP 202. Befejezés előtt visszatér; a böngésző bezárása nem szakítja meg |
| `GET /api/projects/{id}/runs` | `{runs:[run]}`, a legújabb elöl |
| `GET /api/projects/{id}/runs/{runId}` | futás, a megtisztított motoreredménnyel együtt |
| `GET /api/projects/{id}/runs/{runId}/events?after=0` | `{events:[{cursor,type,timestamp,...}],cursor,status}`. Visszajátszáshoz/újracsatlakozáshoz a visszaadott kurzor után kérdezz le |
| `POST /api/projects/{id}/runs/{runId}/cancel` | futás. Leállítja a workerfolyamat fáját; a `Cancelled` nem jelent visszaállítást |
| `GET /api/projects/{id}/wizard` | a projektdefiníció `{title,description,plot,layer,groups:[{id,title,fields:[{key,label,type,default,required,settingPath}]}]}` értéke; 404, ha nincs deklarált varázsló |
| `POST /api/projects/{id}/wizard` | `{etag,values:{target,message}}` a deklarált mezőkötéseket alkalmazza a varázsló explicit rétegében; támogatott típusok: string, int, bool, array, object; a réteget adja vissza |
| `GET /api/secrets` | `{secrets:[{name,reference}]}`; értékeket soha |
| `PUT /api/secrets/{name}` | `{value}` titkosított, szolgáltatáshelyi érték; eredménye `{name,reference:{$env:'PLOTMANAGER_SECRET_NAME'}}` |
| `DELETE /api/secrets/{name}` | eltávolítja a titkot |
| `POST /api/lifecycle/shutdown` | csak hitelesített helyi asztali kliensnek, ha a `PLOTMANAGER_PARENT_PID` konfigurált; szabályosan leállítja a szolgáltatást és a workereket |

A `project` tartalma `{id,name,directory,environments,definition,activeRunId}`. A `definition` a `plot-project.json` hordozható JSON-tartalma:

```json
{"formatVersion":1,"name":"Example","configuration":{"default":"default.json","project":"project.json","environments":{"development":"environments/development.json"}}}
```

A futás tartalma `{id,projectId,plot,environment,invocationId,whatIf,status,createdAt,
startedAt,completedAt,steps,engine,error,snapshot}`. Az állapot `Queued`, `Running`, `Succeeded`, `Failed`, `Cancelled` vagy `Interrupted`. A motoresményeket lower-camel burkolatok adják át: `{cursor,type,timestamp,invocationId,step,status,durationMs}`. Nyers worker stdout/stderr nem kerül visszaadásra. A pillanatkép fájlhash-eket és csomagmásolatokat tartalmaz; a titkok a worker környezetébe kerülnek, a pillanatképbe soha nem íródnak. A hivatkozott környezeti értékeket, beleértve a tulajdonos titkosított titkait és a hiányzó változókat is, a rendszer a futás beküldésekor egyszer, memóriában rögzíti. Az előzetes ellenőrzés és a futás ugyanazt a rögzített állapotot használja akkor is, ha később megváltozik egy titok vagy a szolgáltatás környezete.

A projektkeresés és minden alárendelt erőforrás ellenőrzi a hitelesített tulajdonjogot. A hostolt mód külön konfigurált üzemeltetői tokeneket és HTTPS-t használ; a hozzáférési tokenek soha nem tartoznak a projekt JSON-jába. Meglévő könyvtár megnyitása nem sajátít ki más felhasználó tulajdonában lévő projektet. A rétegútvonalak nem léphetnek ki a projektből; a symlink/reparse útvonalakat elutasítja. Amíg egy futás birtokolja a projekt zárolását, a projektszerkesztés és az ütköző végrehajtás 409 választ kap. Induláskor a befejezetlen tartós futásokat `Interrupted` állapotra módosítja; potenciálisan nem idempotens műveletet soha nem próbál újra.

A rendszer SignalR helyett tartós NDJSON lekérdezést használ: az első szolgáltatás egygépes, szekvenciális futtató, és a kurzoralapú visszajátszás külön átmeneti eseménycsatorna nélkül támogatja az újracsatlakozást. Az eseménykézbesítés és a futástárolás független marad a böngészőkapcsolatoktól.
Ha a lezárt előzmény nem tárolható tartósan, a szolgáltatás a memóriabeli rekordjából `Failed` állapotot és tárolási hibát jelent a részletekben és az előzményekben is. Nem állít sikeres tartós eredményt. Ez a tartalékmegoldás nem éli túl a folyamat összeomlását; induláskor minden megmaradt befejezetlen rekord `Interrupted` besorolást kap.

Az általános projekt varázslója a `plot-project.json` fájlban található, külön cél- és beállítási kérdéscsoportokkal. Az egyes mezők `settingPath` értéke, például `Sample.Target`, a deklarált konfigurációs rétegbe ír; nem hoz létre második végrehajtási modellt. Egy sablon eltérő csoportokat és kötéseket is megadhat.

A `PLOTMANAGER_DATA` privát szolgáltatásállapot. A kizárólagos zárolását egyszerre csak egy szolgáltatás birtokolhatja. Windows alatt a futtatófiók kizárólag tulajdonosnak hozzáférhető könyvtár-ACL-jét és DPAPI-védett DataProtection-kulcsokat használ. Unix alatt 0700 módú könyvtárat használ; ezt és a kulcsgyűrűjét szolgáltatás-hitelesítő adatként védd és mentsd. A titkosított titkok üzemeltetőnként elkülönített névtérben vannak, csak hivatkozásként listázhatók, és explicit `PLOTMANAGER_SECRET_NAME` változókként kerülnek az egyes workerekbe. A szolgáltatáshitelesítési és Kestrel-környezeti beállításokat a worker nem örökli. A hivatkozott környezeti értékeket a strukturált válaszok kitakarják. Sem a nyers stdout, sem az stderr nem kerül a böngészőhöz. A titkos értékeknek környezeti/beállítási hivatkozásként kell szerepelniük a projektfájlokban, literális jelszó-/kulcsmezők helyett.

A projektek és lépések a megjelenített szolgáltatásidentitással futnak. A `process.run` vagy más nagy hatalmú lépés futtatására jogosult hitelesített üzemeltető megbízható abban az értelemben, hogy kódot futtathat ezzel az identitással; a projekttulajdonjog API-hozzáférési határ, nem operációsrendszer-szintű sandbox. Egymásban nem bízó üzemeltetőkhöz külön szolgáltatásidentitásokat/állapotgyökereket használj. A hostolt mód közvetlen Kestrel HTTPS-t és külön üzemeltetői tokeneket igényel a `PLOTMANAGER_USERS` JSON-ban (üzemeltetői azonosítók: 1-64 ASCII betű, számjegy, aláhúzás vagy kötőjel); a reverse proxy továbbítás és a távoli agenthez küldés kívül esik ezen az első protokollon.

Az elkülönített, valódi workert használó HTTP-átvételi ellenőrzésekhez futtasd a `dotnet run --project tests/Management.Server.Tests/Management.Server.Tests.csproj
--configuration Release` parancsot a repository gyökeréből. A konzolos tesztcsomaghoz .NET 8 és PowerShell 7 szükséges, NuGet tesztcsomagokra nincs szüksége, és csak a saját ideiglenes projektjét, állapotát és rövid életű HTTPS-teszttanúsítványát hozza létre/takarítja el.
Windowson a tesztcsomag csak olvasást engedő megosztási fogantyút is tart a saját futási rekordján, hogy ellenőrizze a valósághű hibajelzést, amikor az atomi előzménycsere tiltott. Csak ezt a regressziót és a hitelesítés beállítását a szokásos konzolparancs után megadott `-- --storage-only` értékkel futtasd.
