# Local GUI and structured integration

`Show-PlotRunner.ps1` is a small Windows Forms host for the native runtime. Launch it from Windows PowerShell 5.1 (or a Windows PowerShell 7 installation with Windows Forms):

```powershell
powershell.exe -NoProfile -STA -File ./src/Deployment/Scripts/Show-PlotRunner.ps1
```

1. Enter absolute configuration paths, one per line, in default -> project -> environment order.
2. Set the absolute working directory in the text field below the paths.
3. Click **Load plots** and select a plot.
4. Click **Preview** to preflight and obtain a Skipped result without calling steps.
5. Click **Run** to execute. The window stays responsive and displays the child process's final JSON and exit code.

The window uses the same PowerShell executable that launched it. It does not elevate automatically. Controls are disabled during a run, and closing is blocked until the result is available. Output is collected until completion; this is not a streaming log viewer. It does not support cancellation or rollback. Tool-level deadlines still apply. Use the CLI for automation requiring external supervision.

The old Angular client and experimental HTTP listener remain historical code. They are not wired to the native engine and should not be exposed as a remote command-execution endpoint. The new host uses a local child process and an ephemeral request file; it starts no network listener. Only load trusted package folders, plots, scripts and tool arguments, under the operating-system identity authorized to perform their operations.

## JSON request protocol, version 1

The host-independent bridge is `Core/PlotIntegration.psm1` -> `Invoke-PlotRequest`. The CLI wrapper is:

```powershell
./src/Deployment/Scripts/Invoke-Request.ps1 -RequestPath ./request.json
```

Example request:

```json
{
  "Operation": "run",
  "ConfigurationFiles": ["C:/work/default.json", "C:/work/project.json", "C:/work/test.json"],
  "Plot": "deploy",
  "WorkDirectory": "C:/work",
  "Overrides": {"copy": {"Overwrite": true}},
  "WhatIf": true
}
```

- Operation is `catalog`, `plan` or `run`. Unknown fields are rejected.
- ConfigurationFiles is an optional ordered array, using exactly the native deep merge/reference rules. Relative configuration paths resolve against the caller's current directory. Absolute paths are recommended for GUI callers.
- Catalog returns ProtocolVersion=1, step IDs/packages/versions/parameter schemas and plot names. Secret parameter defaults are omitted; actual configuration values are never returned.
- Plan requires exactly one Plot or Step. It returns invocation IDs, canonical step IDs and parameter-source labels without resolved setting values. It validates static references and types without invoking providers.
- Run requires exactly one Plot or Step. Overrides is an object keyed by invocation ID; use `single` for Step. WhatIf must be a JSON boolean. It returns the same Status/Steps result as Run.ps1; preview returns Skipped. Deferred previous-step output values are only resolved during execution.
- CLI stdout contains one JSON document, including for preview. Exit 0 indicates success/preview; exit 1 indicates validation or execution failure. Validation errors go to stderr, while execution failures are structured results. Successful step outputs can contain sensitive data by design.

There is no arbitrary command-string field, script evaluation or remotely selectable module path. This is an integration contract for a trusted local caller, not an authentication boundary. A desktop application can invoke the script via a process argument array and parse stdout; a remote service would still need its own authentication, authorization, request limits and isolation.

## Acceptance check

Use the existing layered-artifact example with a newly created temporary work directory. Load default.json, project.json and environment.json from `Examples/layered-artifact` in that order. Preview should leave the directory unchanged; Run should create the documented artifacts and show Succeeded. Running it again should report its normal existing-file behavior. The main regression suite exercises the request protocol on both supported PowerShell hosts; `tests/Run-GuiSmoke.ps1` also exercises the real controls and asynchronous child execution without a visible window. Visual Windows Forms interaction requires this manual check.
