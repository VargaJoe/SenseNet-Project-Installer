# Management validation record

This records execution during the 2026-10-21–22 implementation sessions. Build,
automated execution smoke, and interactive manual acceptance are separate claims.
Use [acceptance](management-acceptance.md) for the remaining human review and
[deployment](management-deployment.md) to reproduce builds and checks.

## Source and review

- Preparation: [PR #31](https://github.com/VargaJoe/SenseNet-Project-Installer/pull/31),
  `codex/management-ui-preparation` into `develop`.
- Implementation: [PR #32](https://github.com/VargaJoe/SenseNet-Project-Installer/pull/32),
  `codex/shared-management-ui` into the preparation branch. Review/merge #31 first,
  then retarget #32 to `develop`. Neither PR was automatically merged.
- Final functional source before packaging: `a8cb561b50ff57c13b1d0f6fa65cc1ec0035d495`.
  Packaging helpers, manual workflow policy and documentation changes
  are recorded separately from the packaged program.
- Native engine remains 14 packages / 49 steps. CLI, PS5.1 entry points and the
  temporary Windows Forms launcher remain available.

## Executed checks

| Check | Actual environment | Result |
| --- | --- | --- |
| Native engine and new management bridge | Windows, PowerShell 7.6.6 | 110/110, no skips |
| Native compatibility | Windows PowerShell 5.1 | 109/109, no skips |
| Retained Windows Forms preview/run smoke | Windows, PS7 and PS5.1 | Passed, hidden real form |
| Native engine and management bridge | WSL Ubuntu 26.04, PowerShell 7.6.6 | Final 103/103 passed; 7 explicit Windows-only skips |
| ASP.NET Core backend | Windows, .NET 8 | Final full suite 93/93 assertions, including terminal-history sharing failure, short-secret protocol, native-created directory ACL and actual verbatim-path worker regression |
| ASP.NET Core backend | WSL Ubuntu 26.04, .NET 8 | 75/75 full suite before final sanitizer; final sanitizer real-worker regression 22/22 |
| React/TypeScript | Windows, Node 20 | Build passed; 23/23 tests; production dependency audit: 0 vulnerabilities |
| React/TypeScript | WSL Ubuntu 26.04, Node 20 | Build passed with identical final JS asset; 23/23 tests |
| Real browser flow | Windows, Playwright Chromium | 2/2 passed against final lossless JSON client and actual service/workers |
| Real browser flow | WSL Ubuntu 26.04, Playwright Chromium | 2/2 passed with the same final client and actual service/workers |
| Published portable launcher | Windows, self-contained win-x64 service | Authenticated readiness, full generic plot, exact output bytes, service/launcher shutdown passed |
| Installed Windows desktop | Windows, unsigned NSIS development installer | Install, 368 installed payload hashes, native authenticated UI/service shutdown, uninstall and registration/shortcut cleanup passed |
| Native Linux desktop | Ubuntu 26.04 / WSLg, final extracted `.deb` | Actual GTK/WebKit window, authenticated UI readiness, bootstrap-fragment removal and owned-service shutdown passed |

Engine, UI and browser checks use `d0467510`. Later product changes affect only
Windows state-directory ACL setup and local engine-path normalization; they change no
engine or frontend code. The full Windows backend suite and portable launcher were
rerun after them. The Linux service was republished/repackaged and its native smoke
repeated from a fresh extraction. This is not a new full Linux backend-suite claim.

The browser flow creates a fresh project and runs the generic wizard through a
real filesystem output, then checks independent/full execution, invalid output
dependencies after reordering, typed/unknown numeric JSON roundtrip, durable run
URLs and reconnect, and a project with no wizard/environment. Backend checks cover
CLI parity, layered provenance, immutable configuration/package/environment/secret
snapshots, preflight before side effects, actual worker/grandchild cancellation,
ownership, CSRF, at-rest secret encryption, token revocation and real Kestrel HTTPS.
The HTTPS fixture pins its temporary test certificate; production certificate
validation is not disabled.

A separate final real-service regression passed 22/22 assertions for short secret
values, referenced-only injection, catalog/plan/provenance integrity, redacted data
keys/numeric scalars, and an actual failed process with the secret value `Failed`.
Protocol statuses are authoritative and are never altered by payload redaction.

Actual Windows installed-native startup found a directory-permission defect that
the browser launcher did not exercise. A Rust-created directory already owned by
the current user can have inherited Modify permission without WRITE_OWNER.
Unconditionally assigning that same owner caused UnauthorizedAccessException.
The regression reproduced that failure before the fix; the service now requests
owner reassignment only when the owner differs. It still replaces inherited ACLs
with protected, current-identity-only FullControl. Three regression checks verify
startup, repeat startup and private child-file inheritance. The complete backend
suite passed again after this fix.

A second native-only defect was reproduced with the exact same PowerShell file:
an ordinary local drive path executes, while the `\\?\D:\…` spelling fails with
`AuthorizationManager check failed` before writing a response. Native Tauri resource
paths used that spelling. The service now normalizes only verbatim local drive
engine paths, rejects ambiguous trailing dot/space components, and preserves real
UNC paths and the execution policy. A real authenticated catalog regression fails
before the fix and returns all 49 steps after it. The genuine native Windows
application then passed UI/authentication/shutdown without a policy bypass.

Portable Linux worker plus nested package PowerShell startup was measured at
26.2 seconds on mounted build storage. The cancellation fixture now waits up to
60 seconds for the **actual child PID**, then still verifies that cancellation
terminates that process. This is a test readiness allowance, not a product startup
performance guarantee.

Local evidence is under the ignored `artifacts/management/` directory, including
`windows-engine-final.log`, `windows-powershell51-final.log`,
`windows-backend-final.log`, `windows-browser-e2e-final.log`, the Linux verification
logs and separate desktop execution JSON files. Generated artifacts and test
credentials are not versioned source. Both checked-in workflows are manual only,
as requested by the repository owner. Actions is disabled for the current runner
allowance; all results here are local manual execution, with no passing CI claim.

The Windows portable service ZIP is
`artifacts/management/PlotManager-service-win-x64-a8cb561b.zip`, SHA-256
`79aa69f12ac3c5406905099018bcec5b1f1ed8676829aa941643dc1fdf9be415`.
The canonical `artifacts/management/win-x64` directory was launched through
`Start-Management.ps1 -NoBrowser`; its actual worker wrote the expected sample file
and both processes exited after the authenticated shutdown request. The isolated
project/state directory was removed. Evidence: `portable-launcher-windows.json`.

The unsigned Windows installer is
`artifacts/management/PlotManager_0.1.0_x64-setup.exe`, SHA-256
`7292253cf1d016c2fcfe25575a55d5413f81738cf91fff1c1c88ea23e4ae32ad`.
`Test-InstalledDesktop.ps1` completed with exit 0, comparing all 368 installed
service/engine files with the immutable published payload before native execution.
`desktop-smoke-windows.json` records authenticated UI readiness, service shutdown,
protocol 1, installer hash, payload-manifest hash and `installationRemoved: true`.
Uninstall/shortcut/registration and owned temporary-folder cleanup passed. The
helper refuses to overwrite an existing Plot Manager installation; the exercise
installed into its own temporary directory. It allows a bounded 10-second retry
for WebView2 cache handles to close and retains original errors if cleanup fails.

The final client asset is `index-BJY8UmCJ.js`, SHA-256
`8b744d62a89ec44061afccdcbe44981a912147e85014ac0f56d43edccbb098ce`.
The Windows service assembly is SHA-256
`4a77bea74cfdfb799b57661342e264626fd7f24640bedd839cb206492fc36500`;
the native management bridge is SHA-256
`4a53184008c30907609d1cb09adb72fd24c59c42b995ea2805032b6155919997`.
Per-platform `BUILD-EVIDENCE.json` and `SHA256SUMS` identify packaged payloads.

The Linux `.deb` is `artifacts/management/PlotManager_0.1.0_amd64.deb`, SHA-256
`af4f027e35afc43571a833cb3723b9c32a6e7117962026253d8b3f63462a02ee`.
The portable ZIP is
`artifacts/management/PlotManager-service-linux-x64-a8cb561b.zip`, SHA-256
`e3b314b6ee5398ba8fe563ad442b6f5a32799af900febaa0d73821f2bbda3c7e`.
Final native evidence: `desktop-smoke-linux-a8cb561b.json`;
runtime/source/test details: `linux-final-manifest-a8cb561b.json`.

The Linux package was extracted with `dpkg-deb` and executed with private extracted
libraries in a mount namespace, using Ubuntu 26.04 / GTK 3.24.52 / WebKit 2.52.6 /
ICU 78.2 / OpenSSL 3.5.5 and WSLg. No host packages were installed or replaced.
This establishes actual native execution from the package, not installation via
`apt` or final-artifact compatibility with Ubuntu 24.04. The checked-in Docker and
optional manual workflow recipes targeting Ubuntu 24.04 produce a separate build.

Catalog command/module discovery is cached once per catalog request. In the same
portable Ubuntu runtime the in-process catalog changed from 33.6 to 9.2 seconds,
with the same 49 steps and discovered tool results. A fresh PowerShell worker on
mounted build storage has additional startup cost. Discovery reports executable
or module availability; it does not establish Docker/database connectivity.

## Limits and later work

- This delivery has one execution host per service. Outbound authenticated agents,
  multiple target machines, branching, parallel execution and automatic retry are
  later work. Cancellation never claims rollback of external operations.
- Native WebView smoke checks authenticated UI readiness, fragment removal and
  service shutdown. Human desktop acceptance, signing, ARM64 and a broader Linux
  distribution matrix remain separate work.
- Effective execution values use the existing native PowerShell numeric types.
  Raw configuration editing preserves valid JSON numeric tokens exactly, including
  values outside JavaScript's safe numeric range; unknown metadata is never copied
  from the engine-rounded effective view when an inherited step array is edited.
- Existing SQL/Compose integration results from earlier deliveries are historical.
  No new real database/container integration or real IIS deployment is claimed by
  these management checks.
- Hosted mode was exercised through actual isolated Kestrel HTTPS and access-control
  tests. No public production service was deployed.
