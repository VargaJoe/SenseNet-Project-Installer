<!-- documentation-anchors:start -->
<a id="doc-management-application-acceptance"></a>
<!-- documentation-anchors:end -->
# Management application acceptance

<!-- documentation-navigation -->
[English](management-acceptance.md) | [Magyar](management-acceptance-hu.md) · [Documentation](README.md) · [Project](../README.md)
<!-- /documentation-navigation -->

Use a fresh project and a directory reserved exclusively for this exercise. The
sample uses text and filesystem packages only; it needs no database, container,
company configuration, private endpoint or administrator rights.

1. Follow [build and launch](management-deployment.md) for local browser mode or
   install the development desktop package. Confirm that the header identifies
   the service host and runtime identity. Hosted mode must identify the server.
2. Create a project with the **generic file installer** template. Choose Guided
   setup, enter `acceptance.txt` and a recognizable message, save the answers,
   run static preflight, then execute the sample. Confirm the actual UTF-8 file
   in the displayed project directory and the structured output in Run history.
3. Reopen the run URL or reload during a longer approved local test. Confirm the
   same Run ID, replayed step events and stored result. Closing a browser tab
   must not cancel the managed run. Closing the desktop app explicitly stops its
   own service after the displayed confirmation.
4. In Configuration, explicitly select the project or environment layer. Add
   `"Acceptance":{"nil":null,"off":false,"zero":0,"empty":[],"extension":"kept"}`.
   Save and reload. Inspect raw layers and effective file origins. Override a
   default message in the environment, then remove that override to restore
   inheritance. Check exact file, engine setting layer and reference origins in
   preflight details. No effective merged configuration should replace a layer.
5. Open the same selected layer in two browser sessions. Save in one, then try
   saving stale edits in the other. Expect a conflict and retained local edits.
   Attempting to edit or start a conflicting run while a run holds its project
   lock must also fail visibly.
6. In Plot editor, move `save` before `compose`, save, then preflight. Expect an
   earlier-output dependency error before any operation. Restore the order.
   Select `compose` and run only that invocation. Select `save` alone and expect
   a dependency rejection. Full-plot execution must execute both sequentially.
   Copy/add/remove invocations and inspect their stable, distinct IDs.
7. WhatIf should show Skipped native steps and produce no file changes. It does
   not prove service connectivity. Run an explicit HTTP/TCP/SQL readiness step
   only when an active test against that chosen destination is authorized.
8. Store a synthetic credential in Runner secrets and use its `$env` reference.
   Verify values never return from the secret-list API or appear in run output.
   Stop a deliberately long, isolated process step. Expect Cancelled plus the
   warning that completed/external effects are not rolled back. Never use a real
   deployment to test cancellation.

For CLI parity, set `$project` to that newly created project directory and run
from the source checkout on Windows or PowerShell 7 on Linux:

```powershell
pwsh -NoProfile -File ./src/Deployment/Scripts/Run.ps1 install `
  -DefaultConfigPath "$project/default.json" `
  -ConfigPath "$project/project.json" `
  -EnvironmentConfigPath "$project/environments/development.json" `
  -WorkDirectory "$project"
```

This reads the same ordinary files and native plot as the GUI. Omit the environment
argument for projects without an environment. See [configuration](settings.md)
for per-invocation `-Params` overrides. To clean up, stop this exercise's service,
verify the sample directory contains only resources created for this exercise,
then remove that directory and its private test state. Do not remove an existing
project or unrelated runner data.

Automated commands and platform evidence are in [deployment](management-deployment.md)
and [tests](../tests/README.md). A successful installer build, a hidden native
WebView execution smoke, installation on a clean user machine, and human visual
acceptance are separate checks. CI artifacts belong to their exact source commit.

The first runner executes on its service host. Multi-machine outbound agents,
conditional/parallel graphs, retry, rollback, signed releases, unattended elevation,
arbitrary reverse-proxy TLS termination and broad Linux-distribution packaging
are outside this delivery. Existing source CLI/legacy compatibility is retained;
the portable management distribution contains the native engine only.
