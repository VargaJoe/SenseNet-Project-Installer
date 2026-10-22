# Management API, protocol 1

The .NET 8 service serves the shared React client and `/api` from the same origin.
All JSON wrappers use lower camel case. Native engine responses in `engine` retain
their PascalCase property names. Errors use `{error, code}`. The supported runner
is the service host; a browser never reaches arbitrary localhost services.

Authenticate with `POST /api/session` `{token}` and use `credentials: 'include'`.
Every mutating request, including login, must send `X-Plot-Request: 1`; an Origin,
when present, must equal the service origin. This also applies on loopback.
Cookies are HttpOnly, SameSite=Strict, Secure in hosted HTTPS mode.
Native desktop/CLI clients may authenticate using `Authorization: Bearer TOKEN`
instead; browsers exchange their bootstrap fragment for a cookie and erase the
fragment. Token rotation invalidates existing cookie sessions. Both forms still
require the mutation marker and same-origin check.

| Method and route | Request / response |
| --- | --- |
| `GET /api/session` | `{authenticated,user,mode}`; does not require authentication |
| `POST /api/session` | `{token}` -> session; 401 on invalid bootstrap/operator token |
| `DELETE /api/session` | sign out |
| `GET /api/runner` | `{id,displayName,os,identity,protocolVersion,powerShell,mode,executionTarget:'service-host'}` |
| `GET /api/catalog` | `{engine:{ProtocolVersion,Steps,Packages}}` |
| `GET /api/browse?path=...` | runner-side directories under the allowed project root: `{path,entries:[{name,path,isDirectory}],allowedRoot}` |
| `GET /api/projects` | `{projects:[project]}` owned by authenticated user |
| `POST /api/projects` | `{name,directory?,template?:'generic'}` creates a blank project; explicit `generic` seeds the guided sample. Directory defaults to a safe new child of allowed root. Returns project |
| `POST /api/projects/open` | `{directory}` opens an existing `plot-project.json` within allowed root. Returns project |
| `GET /api/projects/{id}` | project |
| `GET /api/projects/{id}/definition` | `{etag,data}` original portable project definition |
| `PUT /api/projects/{id}/definition` | `{etag,data}` changes name, layer mappings or wizard metadata without discarding unknown properties; verifies mapped JSON files and paths. 409 on stale etag or active run |
| `GET /api/projects/{id}/layers?environment=development` | `{layers:[{id,label,path}],environment}`. IDs: `default`, `project`, `environment:NAME` |
| `GET /api/projects/{id}/layers/{layerId}` | `{id,path,etag,data}`; `data` is the original JSON object |
| `PUT /api/projects/{id}/layers/{layerId}` | `{etag,data}` with an explicit selected layer. 409 if changed or running. Unknown properties and JSON types are preserved; delete a property to inherit it |
| `POST /api/projects/{id}/environments` | `{name}` creates an environment layer and updates portable definition |
| `POST /api/projects/{id}/uploads` | `{name,contentBase64}` saves an explicitly uploaded browser file in project `uploads/`; returns `{path,relativePath}`. This is distinct from runner-side browse |
| `GET /api/projects/{id}/configuration?environment=development` | `{engine:{Configuration,Sources,Layers}}`; values containing environment/secret references stay references |
| `POST /api/projects/{id}/plan` | `{plot,environment,overrides:{invocationId:{Parameter:value}},invocationId?}` -> `{engine}`. Static preflight only; does not contact step services |
| `POST /api/projects/{id}/runs` | `{plot,environment,overrides,invocationId?,whatIf:false}` -> run, HTTP 202. Returns before completion; a closed browser does not cancel it |
| `GET /api/projects/{id}/runs` | `{runs:[run]}` newest first |
| `GET /api/projects/{id}/runs/{runId}` | run, including sanitized engine result |
| `GET /api/projects/{id}/runs/{runId}/events?after=0` | `{events:[{cursor,type,timestamp,...}],cursor,status}`. Poll after the returned cursor for replay/reconnect |
| `POST /api/projects/{id}/runs/{runId}/cancel` | run. Kills the worker process tree; `Cancelled` does not mean rollback |
| `GET /api/projects/{id}/wizard` | project definition's `{title,description,plot,layer,groups:[{id,title,fields:[{key,label,type,default,required,settingPath}]}]}`; 404 when no wizard is declared |
| `POST /api/projects/{id}/wizard` | `{etag,values:{target,message}}` applies declared field bindings into wizard's explicit layer; supported types are string, int, bool, array, object; returns layer |
| `GET /api/secrets` | `{secrets:[{name,reference}]}`; never values |
| `PUT /api/secrets/{name}` | `{value}` encrypted service-local value, returns `{name,reference:{$env:'PLOTMANAGER_SECRET_NAME'}}` |
| `DELETE /api/secrets/{name}` | removes the secret |
| `POST /api/lifecycle/shutdown` | authenticated local desktop only when `PLOTMANAGER_PARENT_PID` is configured; gracefully stops service and workers |

`project` contains `{id,name,directory,environments,definition,activeRunId}`.
`definition` is portable JSON from `plot-project.json`:

```json
{"formatVersion":1,"name":"Example","configuration":{"default":"default.json","project":"project.json","environments":{"development":"environments/development.json"}}}
```

A run contains `{id,projectId,plot,environment,invocationId,whatIf,status,createdAt,
startedAt,completedAt,steps,engine,error,snapshot}`. Status is `Queued`, `Running`,
`Succeeded`, `Failed`, `Cancelled`, or `Interrupted`. Engine events are exposed
as lower-camel wrappers `{cursor,type,timestamp,invocationId,step,status,durationMs}`.
No raw worker stdout/stderr is returned. Snapshot contains file hashes and package
copies; secrets are injected into the worker environment, never written to snapshot.
Referenced environment values, including encrypted owner secrets and absent
variables, are captured once in memory when the run is submitted. Preflight and
the run use that same capture even if a secret or service environment later changes.

Project lookup and all child resources enforce authenticated ownership. Hosted
mode uses separately configured operator tokens and HTTPS; access tokens never
belong in project JSON. Opening an existing directory claims no project already
owned by another user. Layer paths cannot escape the project; symlink/reparse
paths are rejected. Project editing and conflicting execution return 409 while
a run holds its project lock. Startup converts unfinished durable runs to
`Interrupted`; it never retries a potentially non-idempotent operation.

Polling durable NDJSON is used instead of SignalR: the first service is a
single-host sequential runner, and cursor replay supports reconnection without
a separate transient event channel. Event delivery and run storage remain
independent of browser connections.
If terminal history cannot be persisted, the service reports `Failed` with a
storage error from its in-memory record in both detail and history. It never
claims a successful durable result. This fallback cannot survive a process crash;
startup classifies any remaining unfinished record as `Interrupted`.

The generic project's wizard lives in `plot-project.json`, with separate target
and settings question groups. Each field's `settingPath`, for example
`Sample.Target`, writes into its declared configuration layer; it does not create
a second execution model. A template can supply different groups and bindings.

`PLOTMANAGER_DATA` is private service state. Only one service may hold its
exclusive lease. Windows uses the runner account's owner-only directory ACL and
DPAPI-protected DataProtection keys. Unix uses a mode-0700 directory; protect and
back up that directory and its key ring as service credentials. Encrypted secrets
are namespaced per operator, listed as references only, and explicitly injected
as `PLOTMANAGER_SECRET_NAME` variables into each worker. Service authentication
and Kestrel environment settings are removed from worker inheritance. Referenced
environment values are redacted from structured responses. Neither raw stdout
nor stderr is sent to the browser. Secret values must be environment/settings
references in project files rather than literal password/key fields.

Projects and steps execute with the displayed service identity. An authenticated
operator allowed to run `process.run` or other powerful steps is trusted to run
code with that identity; project ownership is an API access boundary, not an OS
sandbox. Host separate service identities/state roots for mutually untrusted
operators. Hosted mode requires direct Kestrel HTTPS and distinct operator tokens
in `PLOTMANAGER_USERS` JSON (operator IDs: 1-64 ASCII letters, digits, underscores,
hyphens); reverse proxy forwarding and remote agent dispatch
are outside this first protocol.

Run `dotnet run --project tests/Management.Server.Tests/Management.Server.Tests.csproj
--configuration Release` from the repository root for isolated real-worker HTTP
acceptance checks. The console suite needs .NET 8 and PowerShell 7, does not need
NuGet test packages, and creates/cleans only its temporary project, state and
ephemeral HTTPS test certificate.
On Windows the suite also holds a read-only sharing handle to its own run record
to verify truthful failure when atomic history replacement is denied. Run only
that regression and authentication setup with `-- --storage-only` after the
normal console command.
