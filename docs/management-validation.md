<!-- documentation-anchors:start -->
<a id="doc-management-validation-record"></a>
<!-- documentation-anchors:end -->
# Management validation record

<!-- documentation-navigation -->
[English](management-validation.md) | [Magyar](management-validation-hu.md) · [Documentation](README.md) · [Project](../README.md)
<!-- /documentation-navigation -->

This records execution during the 2026-10-21–22 implementation sessions. Build,
automated execution smoke, and interactive manual acceptance are separate claims.
Use [acceptance](management-acceptance.md) for the remaining human review and
[deployment](management-deployment.md) to reproduce builds and checks.

<!-- documentation-anchors:start -->
<a id="doc-source-and-review"></a>
<!-- documentation-anchors:end -->
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

<!-- documentation-anchors:start -->
<a id="doc-executed-checks"></a>
<!-- documentation-anchors:end -->
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

<!-- documentation-anchors:start -->
<a id="doc-limits-and-later-work"></a>
<!-- documentation-anchors:end -->
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

<!-- documentation-anchors:start -->
<a id="doc-editing-safety-follow-up"></a>
<!-- documentation-anchors:end -->
## Editing safety follow-up

The `codex/management-editing-safety` branch starts at PR #33's `9b96153`.
It changes the shared browser/desktop client; the previously delivered
`a8cb561b` installers and portable ZIPs do **not** include these changes.
No new native installer, Linux package or installed-desktop acceptance is claimed.

Three editing defects were reproduced before the fixes:

- Reopening a wizard restored descriptor defaults instead of saved settings.
  A custom target returned as `hello.txt`, and saving could replace the operator's
  chosen values. Hydration now uses saved configuration, distinguishes missing
  from `null`/`false`/`0`/`[]`, and keeps reference-backed settings out of literal
  wizard edits. This also checks the raw target layer when an environment literal
  hides a reference in that layer, and refreshes answers after configuration or
  definition saves.
- Leaving Workspace unmounted the portable-definition editor and discarded its
  draft. Page navigation now retains it; unsaved definitions participate in
  unload and project/environment transition protection.
- Invalid or unapplied parameter input left the previous valid value in the
  layer while save and execution remained enabled. The shared client now blocks
  these actions until correction or explicit discard. Rerendering another field
  must retain the invalid draft and its protection.

The initial eight added component/application regressions failed while all 23
existing tests passed. All three added real-browser tests also failed at their
expected assertions against the previously built client: saved wizard values,
exact definition-draft retention, and the still-enabled Save button while a
parameter contains invalid JSON. The browser tests use an isolated
service/data/project root, not an existing installed application or its credentials.

Final source checks on Windows, Node 20.20.0, PowerShell 7.6.6,
Playwright Chromium 1.64.1 and .NET SDK 10.0.113 targeting `net8.0`:

| Check | Result |
| --- | --- |
| React/model/component/application regressions | 39/39 passed across five test files; 16 added checks |
| TypeScript and production web build | Passed; final client `index-C339-pX0.js` |
| Service build carrying the new client | Passed, zero warnings/errors; no backend implementation changes |
| New browser regressions | All three passed: wizard save/reopen, definition navigation/save, invalid parameter/sibling edit/save |
| Existing blank-project browser flow | Passed in the same full-suite run as the three new regressions |
| Existing full/single-run, reorder, numeric roundtrip and reconnect flow | Passed in a focused rerun after bounded test-wait corrections, 1.1 minutes |
| Documentation links and whitespace | 145 local links/anchors valid; `git diff --check` passed |

All five distinct browser scenarios passed against the same new client build.
The full-suite run first passed four cases and exhausted the old long-flow wait
limits. Its trace showed a configuration request starting at 116.9 seconds under
a 120-second total limit; the next attempt exhausted the 20-second URL/run-creation
assertion while the actual accepted run was already visible. The long flow alone
now has a 180-second total allowance and 60-second run-ID waits, matching the
existing bounded run-state wait. Its focused rerun passed without a product
change, automatic test retry or further timeout increase. These are test
allowances, not application startup or performance guarantees.

Local evidence is under ignored `artifacts/management/`: `editing-safety-web-unit.log`,
`editing-safety-web-build.log`, `editing-safety-service-build.log`,
`editing-safety-e2e-final.log` (four passes and the earlier wait failure), and
`editing-safety-existing-flow-final.log` (successful corrected long flow).

To reproduce from the repository root with the documented prerequisites:

```powershell
npm --prefix src/Management/Web test
npm --prefix src/Management/Web run build
dotnet build src/Management/Server/PlotManager.Server.csproj -c Release
pwsh -NoProfile -File scripts/management/Test-Management.ps1 -SkipBuild -SkipBackendTests
```

The last command runs the real browser suite against the freshly built client and
service. The engine and backend implementations are unchanged in this follow-up;
their earlier results above remain historical results, not new executions.
Workflows remain manual only. No user AppData, existing Docker stacks, or the
previous transfer ZIP are changed by these checks.

<!-- documentation-anchors:start -->
<a id="doc-bilingual-documentation-follow-up--2026-10-28"></a>
<!-- documentation-anchors:end -->
## Bilingual documentation follow-up — 2026-10-28

All 49 repository documentation topics now have full English and Hungarian
pages. Canonical filenames default to English; `-hu.md` siblings contain Hungarian.
The complete GUI manual and four-demo catalog have equal coverage in both
languages, as do the technical, testing, legacy and historical planning guides.
Both indexes reach every page in their own language, and every page links to its
counterpart and localized index. Explicit section IDs keep local deep links usable
across translated headings. Original GUI labels, sample values and code remain
recognizable rather than being translated into different executable inputs.

The independent checks are `node ./scripts/management/Test-Documentation.mjs --self-test`
and `node ./scripts/management/Test-Documentation.mjs`. They verify pair coverage,
heading/table coverage, 68 identical executable examples and inline code literals,
reciprocal language navigation, local targets/anchors and per-language reachability.
Self-checks also prove rejection of missing pairs/targets/anchors, wrong-language
links, changed examples/literals, unpaired pages and unreachable documents.
The four explanatory text diagrams have localized labels, explicitly registered
in the manifest. The full documentation graph passed with zero errors.

This follow-up changes documentation and its independent validator only. Earlier
application/runtime results above remain dated evidence; no new app, Docker,
installer, browser, native desktop or Linux execution is claimed for translation.
