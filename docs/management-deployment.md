# Management build, desktop packaging and deployment

The shared React client is served by `src/Management/Server/PlotManager.Server.csproj`.
The service calls the version 1 JSON worker bridge in isolated PowerShell 7 processes.
`src/Desktop` is a Tauri 2 native window around **the same service and client**.
There is no separate desktop configuration resolver. See [API and ownership](management-api.md).

## Prerequisites

| Mode | Required on the execution machine |
| --- | --- |
| Windows desktop | Windows x64, PowerShell 7 (`pwsh` on PATH), Microsoft WebView2 |
| Linux desktop | Ubuntu 24.04 x64 graphical session, PowerShell 7 on PATH, GTK 3 / WebKitGTK 4.1; the `.deb` declares system libraries |
| Published local/hosted service | Windows x64 or Ubuntu 24.04 x64, PowerShell 7 on PATH; the published service includes .NET 8 |
| Source build | .NET 8 SDK, Node 20, npm; desktop additionally Rust 1.99.1 and platform compiler/WebView development packages |

Install PowerShell from the [Microsoft instructions](https://learn.microsoft.com/powershell/scripting/install/installing-powershell).
`scripts/management/Check-DesktopPrerequisites.ps1` checks installed prerequisites;
pass `-Build` for compiler checks. Individual steps can require additional tools
(Git, Docker, database clients) or privileges. The catalog marks Windows-only steps;
an installed cross-platform UI does not make IIS steps available on Linux.

The unsigned Windows NSIS development installer installs per-user and offers the
Microsoft WebView2 bootstrapper if needed. An offline Windows machine must already
have WebView2. No application signing certificate is required to build or test it.
Windows may show the normal unrecognized-publisher prompt for this unsigned package.

Windows desktop builds need Visual Studio C++ build tools and the Windows SDK.
Ubuntu 24.04 desktop builds need:

```sh
sudo apt-get install libwebkit2gtk-4.1-dev build-essential curl wget file \
  libxdo-dev libssl-dev libayatana-appindicator3-dev librsvg2-dev xvfb
```

Platform prerequisites and the Windows bootstrapper behavior follow the
[Tauri prerequisites](https://v2.tauri.app/start/prerequisites/) and
[Windows installer documentation](https://v2.tauri.app/distribute/windows-installer/).
The initial Linux package targets Ubuntu 24.04, whose ICU/OpenSSL dependencies
are declared. Other distributions and ARM64 are not part of this package matrix.

## Build and local browser

From the repository root in PowerShell 7:

```powershell
./scripts/management/Build-Management.ps1 -Runtime win-x64
# On Ubuntu: -Runtime linux-x64
./scripts/management/Start-Management.ps1
```

`Build-Management.ps1` uses checked-in npm locks, publishes a self-contained .NET 8
service, includes the built client, and copies only the native engine, manifests
and CLI entry points. It resets only its validated generated output directories.
Output is `artifacts/management/<rid>/{service,engine}`. A source checkout is not
required on a target machine using this directory. PowerShell is an explicit
runtime prerequisite rather than a second bundled, independently patched runtime.
This portable engine directory supports the native CLI only; historical `-Legacy`
execution still uses the original source distribution and its legacy dependencies.

`Start-Management.ps1` starts the published service on an ephemeral IPv4 loopback
port, generates a cryptographic bootstrap credential in memory, and opens the
browser with a URL fragment. The UI exchanges it for an HttpOnly session cookie
and removes the fragment. The launcher never prints or saves this credential.
The terminal owns the service lifetime; closing a browser tab leaves runs active.
Closing the terminal or stopping the launcher stops the service and its workers.
No stopped operation is reported as a successful rollback.

Optional `-DataDirectory`, `-ProjectRoot`, and `-Port` select local storage and
the allowed runner-side project root. `-NoBrowser` requires an operator-supplied
`PLOTMANAGER_TOKEN` in the launcher environment; open the printed base URL and use
that token in the login screen. Do not pass real tokens in shell history or commit
them to a project. To run a copied service directory directly, set the variables
below and execute `service/PlotManager.Server` (Windows: `.exe`).

## Native desktop

```powershell
./scripts/management/Check-DesktopPrerequisites.ps1 -Build
./scripts/management/Build-Management.ps1 -Runtime win-x64 -Desktop
# On Ubuntu: -Runtime linux-x64 -Desktop
```

The Rust toolchain is pinned in `src/Desktop/rust-toolchain.toml`. Cargo and npm
lock files constrain dependency resolution. Builds use the matching host OS;
cross-compiling the Linux package on Windows is not supported. The output is:

- Windows: `src/Desktop/src-tauri/target/release/bundle/nsis/*-setup.exe`.
- Ubuntu: `src/Desktop/src-tauri/target/release/bundle/deb/*.deb`; install with
  `sudo apt install ./<package>.deb`, then launch **Plot Manager** from the app menu.

Tauri bundles the self-contained local service, compiled client and native engine.
At startup it verifies `pwsh`, creates private per-user application storage, binds
only to `127.0.0.1`, generates a new 256-bit credential, launches its child, and waits
for an authenticated readiness response. The window can navigate only within that
specific service origin and has no frontend filesystem/shell IPC permissions.
Service credentials are passed in its process environment, never command arguments
or project files. Its UI session uses the same cookie exchange as local browser mode.

The desktop window owns its local service. Closing it asks for confirmation and
explicitly warns that running workers stop, completed operations are not rolled back,
and external jobs can continue. A graceful shutdown is attempted before a bounded
forced stop of this instance's child tree. The service monitors its desktop parent
process so a desktop crash does not intentionally leave a detached privileged runner.
Do not close desktop while an operation should continue: use the long-lived local
browser or hosted service mode for that workflow. Each desktop launch starts its
own service instance and credential; do not share one desktop data directory across
simultaneous instances.

## Authenticated HTTPS server

The browser's execution target is always the service host, under its displayed OS
identity. A browser never connects to arbitrary localhost workers. The first runner
interface is version 1, single-host and sequential. Authenticated outbound agents
and multiple remote target machines remain future work.

Publish the matching runtime, copy `service/` and `engine/` to a dedicated directory
such as `/opt/plot-manager`, install `pwsh`, and create a dedicated unprivileged
`plotmanager` account. Give that account only the rights/tools needed by approved
projects. GUI access never grants additional OS privileges. Set service environment
variables outside the source checkout/project files:

| Variable | Example / meaning |
| --- | --- |
| `PLOTMANAGER_MODE` | `hosted`; remote HTTP is rejected |
| `ASPNETCORE_URLS` | `https://0.0.0.0:7443` |
| `ASPNETCORE_Kestrel__Certificates__Default__Path` | `/etc/plot-manager/gui-api.pfx` |
| `ASPNETCORE_Kestrel__Certificates__Default__Password` | PFX password injected by the service supervisor/secret store |
| `PLOTMANAGER_USERS` | JSON mapping of operator name to distinct random token of at least 32 characters |
| `PLOTMANAGER_DATA` | `/var/lib/plot-manager`; private state, protection keys, ownership, encrypted secrets, run records |
| `PLOTMANAGER_PROJECT_ROOT` | `/srv/plot-manager/projects`; only directories beneath it can be opened |
| `PLOTMANAGER_ENGINE` | `/opt/plot-manager/engine` |

Generate operator tokens with a cryptographic generator, for example
`openssl rand -hex 32`, directly into an access-controlled deployment secret store.
An illustrative `PLOTMANAGER_USERS` shape is
`{"alice":"<alice-64-hex-token>","bob":"<bob-distinct-64-hex-token>"}`; replace the
placeholders rather than using them as credentials. Rotate tokens by updating the
service environment and restarting during a maintenance window. Cookie token stamps
are checked against current operator credentials, so old sessions are rejected after
the changed configuration is loaded. Keep the protection keys: they also encrypt
stored secrets and are not a token-rotation mechanism.

`scripts/management/plot-manager.service.example` shows Linux process supervision.
Use an owner-only `/etc/plot-manager/service.env` and storage directories owned by
the service account, mode `0700`. Keep the HTTPS private key outside projects,
readable only by the supervisor/service account. Restrict network access to approved
operators. Install your trusted GUI/API certificate with the correct server hostname
(for example `plot-manager.example.invalid`) and trusted CA chain. No insecure
certificate-validation bypass is needed. Bind directly to Kestrel HTTPS in this
delivery; trusted forwarded-header/reverse-proxy TLS termination is not implemented.
Windows may supervise the executable using an existing approved service supervisor;
the executable does not claim to implement the Windows Service Control Manager protocol.

Mutating API calls require authentication, `X-Plot-Request: 1`, and a same-origin
Origin header when supplied. Browser cookies are HttpOnly, SameSite=Strict and
Secure in HTTPS mode. CLI/native clients may use `Authorization: Bearer <token>`.
Project ownership is checked on project, layer and run requests. All users still run
under the shared server OS identity; only provision operator accounts trusted to run
approved project steps with that identity. This is an administration service, not a
sandbox for hostile workloads. Do not expose unauthenticated remote endpoints.

The service makes its data directory private (Windows owner ACL / Unix `0700`).
Back up state and protection keys together; restrict backups as carefully as live
state. Project files may contain environment/secret references, not private keys
or passwords. Owner-scoped service secrets are encrypted with Data Protection and
injected only into worker environments. Do not enable verbose request-body logging.
Never supply arbitrary production credentials to a sample project.

There are three separate certificate contexts:

1. **GUI/API HTTPS:** certificate/private key on the management server; the browser
   needs to trust its CA. Local loopback mode uses the random credential over HTTP.
2. **Services reached by steps:** trust roots, client certificates and references on
   the runner host, used by its process identity. These do not configure GUI HTTPS.
3. **Application being installed:** certificates installed on the target by an
   explicitly authorized project step, with its own private-key permissions. These
   do not automatically become management-service certificates.

## Tests and evidence

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

The management harness runs frontend checks, backend tests with real worker
processes, and Playwright against a real isolated loopback service. The harness
uses disposable projects, checks readiness with its own credential, and cleans only
its validated temporary directory. It never mounts a real deployment project.

After desktop packaging, on a disposable Windows test machine with no existing
Plot Manager installation, run:

```powershell
$installer = @(Get-ChildItem ./src/Desktop/src-tauri/target/release/bundle/nsis/*.exe)[0]
./scripts/management/Test-InstalledDesktop.ps1 -Installer $installer.FullName
```

On Linux, install the `.deb` and run `Test-DesktopSmoke.ps1 -Executable /usr/bin/plot-manager`
under `xvfb-run -a dbus-run-session -- pwsh -NoProfile -File ...`. This launches a real,
hidden native WebView, waits for the authenticated React client to load, checks
token-fragment removal, shuts down its own service and writes a JSON evidence file
with OS and executable SHA-256. It is an execution smoke test, not a complete visual
desktop acceptance test. The Windows helper also silently installs and uninstalls
its package in an owned temporary directory. It is intended for clean test VMs,
because NSIS registration belongs to the application identity. Installer build
success, installed-package execution smoke and manual GUI acceptance are separate claims.

`.github/workflows/management.yml` runs the engine, backend, frontend, real browser
flow and installed native desktop smoke on Windows and Ubuntu. It uploads unsigned
NSIS/`.deb` packages, the portable service and separate execution evidence. The existing PS5.1 regression and WinForms
smoke remain Windows checks. The workflow result for the delivered commit, not the
presence of this YAML, is the evidence of successful builds and platform execution.

For an optional host-independent Linux verifier, build
`docker build -f scripts/management/Dockerfile.linux-build -t plot-manager-linux-build .`.
It supplies Ubuntu 24.04, .NET, Node, PowerShell, Rust and WebView build dependencies
inside Docker. Copy the checkout into an isolated container workspace, excluding
`node_modules`, `bin`, `obj`, Cargo `target` and artifacts, before testing; do not
reuse Windows native dependency directories for Linux. Docker-based native WebView
smoke may require the WebKit sandbox disabled **only inside that isolated test
container**; that is not an application deployment setting.
