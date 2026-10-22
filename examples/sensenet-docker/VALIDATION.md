# Verification — 2026-10-22

This report covers the portable example, independently of the existing shared
management application delivery. No engine, API or frontend code changed.

## Actual execution

- Windows PowerShell7.6.6 native regression suite:110/110 passed.
- Windows PowerShell5.1 native regression suite:109/109 passed. The example
  itself requires PowerShell7.2+; these checks preserve the engine's older host.
- `tests/Run-SenseNetExample.ps1`:14/14 checks with no Docker invocation:
  all13 native plot preflights and license refusal before helper runtime effects.
- `tests/Run-SenseNetExample.ps1 -RunDocker`:30/30 checks. Fresh randomly named
  loopback-only stack, pinned public images, actual Root response, discovery,
  strict PKCE admin login, authenticated Admin read and real Folder creation.
  The same content ID survived stop/start, container recreation and restore.
  An unconfirmed restore preserved the changed markers. A confirmed restore
  replaced changed markers in **both** the SQL acceptance database and App_Data
  with their original backup values. Ownership-checked cleanup removed the
  disposable containers, two volumes, network and private local files.
- Actual local browser application:15 successful managed runs, including
  install preview, full install, content, status/logs, backup, stop/start,
  recreation, restore and authenticated verification. Existing three projects
  and histories retained. The fourth project remains installed and running.
- Actual desktop application store: wizard saved through the supported API,
  install preview, repeated prepare and status passed. It has its own namespace
  and ports; a second persistent SQL stack was intentionally not installed.
- Ubuntu26.04 / PowerShell7.6.6: actual project prepare and localhost certificate
  generation, owner-only directory/file modes700/600 and all13 native previews
  passed. Full Linux-host installation/backup/restore was **not** exercised.
  The complete Docker lifecycle above ran from Windows against Linux containers.

Sanitized local evidence is under ignored
`artifacts/sensenet-example-tests/<fixture>/acceptance-evidence.json` and
`artifacts/management/sensenet-project-20261022/`. Neither directory is a required
project input or a committed credential store. Regenerate the disposable evidence
with the two test commands above.

## Reproduced corrections

- A local API build's digest was not resolvable in the public registry. The
  example pins a published immutable API digest instead of that local image.
- A separate configured localhost-only client avoids the default client
  initialization dependency. With RequirePkce=true, successful IdentityServer
  login can return a200 HTML Redirect view. The helper reads its local data-url
  without executing HTML/JavaScript, validates its identity callback and state,
  then exchanges the authorization code.
- The current API accepts the direct JSON content model. Legacy form/models
  syntax ignored the requested Name; the corrected seed reads back the exact
  named Folder instead of trusting the create response alone.
- Repeated PowerShell Set-Acl requested SeSecurityPrivilege on a protected
  directory. Explicit FileSystemAclExtensions.SetAccessControl changes only the
  DACL and works repeatedly with the normal user token.

## Scope

This is a local development example with the official initial admin/admin
account. It does not configure an external Admin UI callback, production
authentication, image upgrades or a different-version database migration.
Only the generated project certificate is accepted by the helper; no OS trust
store changes or globally disabled certificate validation are used.
