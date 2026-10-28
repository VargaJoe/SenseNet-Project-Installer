<!-- documentation-anchors:start -->
<a id="doc-plot-manager-complete-guide-to-the-four-demo-projects"></a>
<!-- documentation-anchors:end -->
# Plot Manager: complete guide to the four demo projects

<!-- documentation-navigation -->
[English](management-demo-projects.md) | [Magyar](management-demo-projects-hu.md) · [Documentation](README.md) · [Project](../README.md)
<!-- /documentation-navigation -->

This catalog explains the four projects that can be opened in the installed application: what they produce, when to choose each plot and what every step does. Source links are readable on GitHub; understanding them does not require a running application. Detailed screen and control descriptions are in the [GUI manual](management-user-guide.md).

<!-- documentation-anchors:start -->
<a id="doc-contents-and-suggested-order"></a>
<!-- documentation-anchors:end -->
## Contents and suggested order

| Project in the application | What does it teach? | Plots | External prerequisite |
| --- | --- | --- | --- |
| [01 – Vezetett fájltelepítő](#demo-01) (guided file installer) | Wizard → ordinary setting → two-step execution → file; passing an earlier step's output. | `install` | None. |
| [02 – Rétegek, típusok és hivatkozások](#demo-02) (layers, types and references) | Default/project/environment overrides, inheritance, `false`, `0`, `null`, `[]`; detecting invalid order. | `show-settings`, `hibas-sorrend` | None. |
| [03 – JSON, XML és ZIP csomagolás](#demo-03) (JSON, XML and ZIP packaging) | Nine-step local packaging and readback; development/production results. | `package` | None. |
| [04 – SenseNet Docker telepítés és menedzsment](#demo-04) (SenseNet Docker installation and management) | SQL + repository + IdentityServer installation, validation, content, daily management, backup/restore. | 13 plots, all listed below. | Docker with Linux containers, Compose v2, PowerShell 7.2+. |

Source for the first three projects is in [examples/management-demos](../examples/management-demos/README.md), containing inputs only. The fourth is in [examples/sensenet-docker](../examples/sensenet-docker/README.md). Execution results and secrets are not part of these GitHub directories.

<!-- documentation-anchors:start -->
<a id="doc-how-to-read-the-demos"></a>
<!-- documentation-anchors:end -->
## How to read the demos

A **project** is a portable directory. `plot-project.json` provides its name, layer-file paths, environments and optional wizard. A **plot** is a named sequence of steps executed in order. A row's **invocation ID** is its name within the plot (`save`); **Step** is the installed operation (`filesystem.write`). The same Step can appear with several IDs and parameter sets.

Every demo uses this layering:

```text
default.json → project.json → environments/<kiválasztott environment>.json
```

A later object field overrides the earlier one; objects merge field by field, while arrays are replaced as a whole. Missing fields inherit; explicit `null`, `false`, `0` and `[]` are actual values. The raw editor in `Configuration` always edits the selected layer; the effective view shows the resolved combined result.

| What you see in JSON | Meaning |
| --- | --- |
| `{"$ref":"settings.Sample.Message"}` | A setting value merged from the layers. |
| `{"$ref":"steps.compose.Output.Text"}` | Output from `compose`, executed **earlier in the same run**. |
| `{"$env":"PLOTMANAGER_SECRET_SENSENET_ADMIN_PASSWORD"}` | A runner environment variable; a Runner secret can supply it in the GUI. |
| `With` | Parameters for this invocation. |
| `StepDefaults` | Common parameters for the same native Step; an invocation's `With` can refine them. |

**Every path refers to the service machine.** Relative outputs are created in the project working directory. With a hosted GUI, this is the server rather than the browser computer. Copies registered in separate desktop and browser data stores are independent. Earlier runs' output is visible in history but cannot serve as an earlier output in a new single-step run.

**Common GUI procedure:** open the project, select an environment and choose the plot in `Plot editor`. Save any changes (`Save layer`, or `Save selected layer` in the unsaved-changes notice), then `Preflight plot` → `WhatIf preview` → `Run plot`. `Run history` shows state, steps, structured outputs and run ID. Preflight and WhatIf are static: they do not write the file, start a Docker stack or verify a password, port availability or external service readiness. Actual execution also starts with full preflight; step execution follows it.

<a id="demo-01"></a>
<!-- documentation-anchors:start -->
<a id="doc-01--guided-file-installer"></a>
<!-- documentation-anchors:end -->
## 01 – Guided file installer

Source: [project definition and wizard](../examples/management-demos/01-vezetett-telepito/plot-project.json),
[defaults and steps](../examples/management-demos/01-vezetett-telepito/default.json),
[project values](../examples/management-demos/01-vezetett-telepito/project.json),
[development](../examples/management-demos/01-vezetett-telepito/environments/development.json).

<!-- documentation-anchors:start -->
<a id="doc-what-do-you-see-and-what-is-the-result"></a>
<!-- documentation-anchors:end -->
### What do you see, and what is the result?

This is a small installer that actually writes a file. `install` composes one message and saves it as a UTF-8 file. It performs no download, service installation or system-wide installation. The project overrides the defaults `hello.txt` / `Hello from Plot Manager` with `udvozlet.txt` / `Szia a Plot Manager demóból!`. The development layer is empty and does not change them. No other environment is predefined here.

<!-- documentation-anchors:start -->
<a id="doc-every-step-in-install"></a>
<!-- documentation-anchors:end -->
### Every step in `install`

| Order / ID | Native Step | Input and action | Output and dependency |
| --- | --- | --- | --- |
| 1. `compose` | `text.join` | `Items` = one element, `settings.Sample.Message`; `Separator` = empty text. Joins the message. Here the name means text composition, not Docker Compose. | `Output.Text` = the whole message. Can run independently. |
| 2. `save` | `filesystem.write` | `Path` = `settings.Sample.Target`; `Content` = `steps.compose.Output.Text`; `Overwrite:true`. Writes or overwrites the target file. | `Output.Path`, `Output.Bytes`. Requires `compose` output from this run. |

<!-- documentation-anchors:start -->
<a id="doc-a-first-guided-installation"></a>
<!-- documentation-anchors:end -->
### A: first guided installation

1. Open the project and `Guided setup`.
2. `Target`: check the runner machine; enter, for example, `udvozlet.txt` in **Fájlnév a projektben** (“filename in the project”). Use a simple filename; this example has no directory-creation step.
3. `Continue to settings →`: enter the desired content in **Üzenet** (“message”).
4. `Save answers →`: the wizard saves `Sample.Target` and `Sample.Message` in `project.json`. It does not start installation.
5. `Run static preflight` → review both steps → `Continue to run →` → `Run sample installation`.
6. In `Result`/`Run history`, both steps succeed. The project directory contains the target file with the entered message; `save` output includes its path and byte count.

<!-- documentation-anchors:start -->
<a id="doc-b-understanding-a-single-step-and-its-dependency"></a>
<!-- documentation-anchors:end -->
### B: understanding a single step and its dependency

1. In `Plot editor`, select `install`, then the `compose` row.
2. `Preflight invocation`, then `Run invocation`: only the text is produced, with no file.
3. Select `save`, then `Preflight invocation`: the system rejects it because a standalone run has no earlier `compose` output. This remains true even if the whole plot succeeded earlier or the target file already exists.
4. Use `Run plot` again to save the message.

**Rerun:** new content overwrites the same file. Changing the filename creates a new file; the previous target remains. **Undo:** manually delete your own created files; the plot has no rollback or cleanup step. Separately restore saved wizard settings if you want the original example back.

<a id="demo-02"></a>
<!-- documentation-anchors:start -->
<a id="doc-02--layers-types-and-references"></a>
<!-- documentation-anchors:end -->
## 02 – Layers, types and references

Source: [project definition](../examples/management-demos/02-retegek-es-hivatkozasok/plot-project.json),
[defaults and both plots](../examples/management-demos/02-retegek-es-hivatkozasok/default.json),
[project](../examples/management-demos/02-retegek-es-hivatkozasok/project.json),
[development](../examples/management-demos/02-retegek-es-hivatkozasok/environments/development.json),
[production](../examples/management-demos/02-retegek-es-hivatkozasok/environments/production.json).

<!-- documentation-anchors:start -->
<a id="doc-what-do-you-see-and-what-is-the-result-1"></a>
<!-- documentation-anchors:end -->
### What do you see, and what is the result?

`show-settings` writes the resolved `Demo` object to `settings-result.json`, then reads it back. You can compare the effective configuration with both the actual file and `read.Output.Value`. There is no wizard here: the lesson is using `Configuration`, the environment selector, `Plot editor` and preflight.

<!-- documentation-anchors:start -->
<a id="doc-actual-results-for-the-two-environments"></a>
<!-- documentation-anchors:end -->
### Actual results for the two environments

| `Demo` field | Default → project | development result | production result |
| --- | --- | --- | --- |
| `Target` | default: `settings-result.json` | `settings-result.json` | `settings-result.json` |
| `Message` | `Alapértelmezett üzenet` → `Projektből érkező üzenet` | `Projektből érkező üzenet` | `Projektből érkező üzenet` |
| `Scope` | `default` → `project` | `development` | `production` |
| `Enabled` | default: `true` | `false` | `true` |
| `Attempts` | default: `3` | `0` | `2` |
| `Optional` | default: `örökölt érték` | `null` | `örökölt érték` (production omits it) |
| `Items` | default: `["egy","kettő"]` | `[]` | `["release"]` |
| `Nested.DefaultOnly` | default: `megmarad` | `megmarad` | `megmarad` |
| `Nested.ProjectOnly` | project: `hozzáadva` | `hozzáadva` | `hozzáadva` |
| `Nested.Switched` | `default` → `project` | `development` | `production` |

The default layer also contains `VendorMetadata.UnknownFeature.Preserve:true` and `VendorMetadata.FutureInteger:9007199254740993`. They are not part of `Demo`, so they do not appear in the exported file. They demonstrate raw configuration and lossless editing: both the unknown field and the number beyond JavaScript's safe integer range must be preserved. Do not manually round the number.

<!-- documentation-anchors:start -->
<a id="doc-every-invocation-in-both-plots"></a>
<!-- documentation-anchors:end -->
### Every invocation in both plots

| Plot / order | ID / native Step | Input and action | Result |
| --- | --- | --- | --- |
| `show-settings` 1. | `export` / `json.write` | `Path=settings.Demo.Target`, `Value=settings.Demo`, `Overwrite:true`. | The complete resolved Demo object is written to a file; `Output.Path`. |
| `show-settings` 2. | `read` / `json.read` | `Path=steps.export.Output.Path`. | The object from the file just written appears under `Output.Value`; order is correct. |
| `hibas-sorrend` 1. | `read` / `json.read` | The same `steps.export.Output.Path`, but `export` would be produced only afterward. | **Preflight rejects the entire plot**, before reading any file. |
| `hibas-sorrend` 2. | `export` / `json.write` | The same parameters as in the valid plot. | Does not execute because the forward output reference is invalid. |

<!-- documentation-anchors:start -->
<a id="doc-a-comparing-development-and-production"></a>
<!-- documentation-anchors:end -->
### A: comparing development and production

1. Select `development` and `Configuration`.
2. Inspect the default, project and development layers in turn, then effective configuration and provenance. Compare with the table above.
3. `Plot editor` → `show-settings` → `Preflight plot` → `Run plot`.
4. `Run history` → `read` output: it should show `false`, `0`, `null`, an empty array and the two inherited `Nested` fields. `settings-result.json` contains the same values.
5. Switch to `production` and run the whole plot again. The file is replaced with production values; the earlier development run's output remains in history.

<!-- documentation-anchors:start -->
<a id="doc-b-trying-inheritance-and-the-deliberate-error"></a>
<!-- documentation-anchors:end -->
### B: trying inheritance and the deliberate error

1. In `Configuration`, explicitly select the development layer, remove the `Demo.Attempts` override, save and inspect the effective value: `3`. Entering `null` does not remove it; that would be another explicit value.
2. Restore the original `Attempts:0` and save.
3. `Plot editor` → `hibas-sorrend` → `Preflight plot`. The expected result is an ordering error, not a successful file write. `Run plot` would also stop here before execution.
4. Select `show-settings` to return. To fix the teaching example, move `export` before `read`; the valid plot already demonstrates this.

**Single step:** `export` can run independently when the required settings are valid. Running `read` alone is rejected because earlier output is missing. **Rerun:** `settings-result.json` is overwritten every time. **Cleanup:** delete only this result file of your own; separately restore configuration experiments.

<a id="demo-03"></a>
<!-- documentation-anchors:start -->
<a id="doc-03--json-xml-and-zip-packaging"></a>
<!-- documentation-anchors:end -->
## 03 – JSON, XML and ZIP packaging

Source: [project definition](../examples/management-demos/03-json-xml-zip/plot-project.json),
[defaults and complete pipeline](../examples/management-demos/03-json-xml-zip/default.json),
[project](../examples/management-demos/03-json-xml-zip/project.json),
[development](../examples/management-demos/03-json-xml-zip/environments/development.json),
[production](../examples/management-demos/03-json-xml-zip/environments/production.json).

<!-- documentation-anchors:start -->
<a id="doc-what-do-you-see-and-what-is-the-result-2"></a>
<!-- documentation-anchors:end -->
### What do you see, and what is the result?

One `package` plot builds a local package. It does not compile an application, use Docker or upload anywhere. The lesson is ordering, different file formats and cooperation between step outputs. This project has no wizard either.

| Order / ID | Native Step | Parameters and step's role | Result / dependency |
| --- | --- | --- | --- |
| 1. `directory` | `filesystem.mkdir` | `Path:"build"`; creates the directory if absent. | `Output.Path`, `Created`; parent directory for the following files. |
| 2. `template` | `filesystem.write` | `build/app.template.xml`, literal XML template, `Overwrite:true`. The initial Environment value is `unset`. | Creates the XML source file. |
| 3. `configure` | `xml.set` | `Source:"build/app.template.xml"`, `Destination:"build/app.config"`, `XPath:"/configuration/appSettings/add/@value"`, `Value=settings.Release.Environment`, `Overwrite:true`. | Sets the XML attribute to the selected environment; the template remains unchanged. |
| 4. `manifest` | `json.write` | `Path:"build/manifest.json"`, `Value=settings.Release.Manifest`, `Overwrite:true`. | The resolved manifest JSON file. Its `Environment` is also a `settings.Release.Environment` reference. |
| 5. `readme` | `filesystem.write` | `Path:"build/README.txt"`, `Content=settings.Release.Readme`, `Overwrite:true`. | A short Hungarian description inside the package. |
| 6. `pack` | `archive.pack` | `Source:"build"`, `Destination:"demo-bundle.zip"`, `Overwrite:true`. | ZIP of the build directory. `Output.Path`, `Files`, `Bytes`. |
| 7. `unpack` | `archive.unpack` | `Source=steps.pack.Output.Path`, `Destination:"expanded"`, `Overwrite:true`. | ZIP contents in the expanded directory, with entry and destination-path checks. Requires earlier `pack` output. |
| 8. `checksum` | `filesystem.hash` | `Path=steps.pack.Output.Path`. | `Output.Algorithm:"SHA256"`, `Output.Hash`; checksum of the completed ZIP. Requires `pack` output. |
| 9. `verify` | `json.read` | `Path:"expanded/manifest.json"`. | The expanded manifest can be read back as `Output.Value`; the file must already exist. |

Starting from a clean project, expect this result:

```text
build/
  app.template.xml   # Environment="unset"
  app.config         # Environment="development" vagy "production"
  manifest.json
  README.txt
demo-bundle.zip      # a build négy fájlja
expanded/
  app.template.xml
  app.config
  manifest.json
  README.txt
```

Common manifest values are `Application:"Demo artifact pipeline"` (project override), `Attempts:0`, `Optional:null` and `Enabled:false`. Development has `Environment:"development"`, `Features:["debug","local"]`; production has `Environment:"production"`, `Features:["release"]`. The shared README is `Ez egy általános, helyi Plot Manager demócsomag.`

<!-- documentation-anchors:start -->
<a id="doc-a-building-and-inspecting-a-package"></a>
<!-- documentation-anchors:end -->
### A: building and inspecting a package

1. `development` → `Plot editor` → `package`.
2. `Preflight plot`: nine rows, with `pack → unpack` and `pack → checksum` output dependencies. `WhatIf preview` has not created new files.
3. `Run plot`, then `Run history`: all nine steps should succeed.
4. Inspect `checksum.Output.Hash` and the manifest at `verify.Output.Value`. You can also inspect files in the service's project directory or by opening the ZIP.
5. Switch to `production` and rerun. The XML and manifest should now specify production, and the feature array should contain only `release`.

<!-- documentation-anchors:start -->
<a id="doc-b-why-does-a-single-steps-prior-state-matter"></a>
<!-- documentation-anchors:end -->
### B: why does a single step's prior state matter?

`directory` safely creates the directory on its own. `template`, `configure`, `manifest`, `readme`, `pack` and `verify` have no earlier-output references in their parameters, so they can be selected statically as single steps; actual success also depends on the required directories/files existing. For example, `verify` only reads an already existing `expanded/manifest.json`, which may be from an older run. In contrast, single-step preflight rejects `unpack` and `checksum` because `pack` output is missing. Use the whole plot for the complete package build.

**Rerun:** overwriting is explicit for the listed output files. Extra files manually copied into `build` earlier would also enter the ZIP; extraction does not delete unrelated extra files in `expanded`. This is not a release pipeline that clears all output first. **Cleanup:** remove only your own `build`, `expanded` directories and `demo-bundle.zip`; the next complete run recreates them. Computing a checksum alone does not compare it with a previously known hash, and `verify` reads back data rather than running an application test.

<a id="demo-04"></a>
<!-- documentation-anchors:start -->
<a id="doc-04--sensenet-docker-installation-and-management"></a>
<!-- documentation-anchors:end -->
## 04 – SenseNet Docker installation and management

Source: [project definition and wizard](../examples/sensenet-docker/plot-project.json),
[defaults, StepDefaults and 13 plots](../examples/sensenet-docker/default.json),
[project](../examples/sensenet-docker/project.json),
[development](../examples/sensenet-docker/environments/development.json),
[Compose topology](../examples/sensenet-docker/compose.yaml),
[Manage-SenseNet.ps1](../examples/sensenet-docker/scripts/Manage-SenseNet.ps1).
Further operations details: [SenseNet README](../examples/sensenet-docker/README.md),
[evidence from earlier actual validation](../examples/sensenet-docker/VALIDATION.md).

<!-- documentation-anchors:start -->
<a id="doc-the-stack-and-data-locations"></a>
<!-- documentation-anchors:end -->
### The stack and data locations

This is an actual local development installation. Source defaults are `pm-sensenet-demo`, API HTTPS port `18160` and Identity HTTPS port `18161`. Installed demo copies may use their own names/ports: the project settings displayed in the GUI and run output are authoritative. Choose a unique name and two free ports for a new copy. The name, ports and image digests are fixed after the first `prepare`. A new installation requires a new directory and its own stack.

| Compose service | What does it do? | Access and persistent data |
| --- | --- | --- |
| `snsql` | SQL Server Developer; SQL `SELECT 1` health check. | No SQL port published to the host. `<stack>_db-data` volume: `/var/opt/mssql`. |
| `db-init` | After SQL becomes ready, creates database `<stack>-sndb` once if absent. | One-off helper container; successful completion is normal. |
| `snapp` | SenseNet repository API with SQL storage. | `https://localhost:<ApiPort>`; `<stack>_app-data` volume: `/app/App_Data`. |
| `snis` | IdentityServer for the repository. | `https://localhost:<IdentityPort>`; for login. |

Host ports bind only to `127.0.0.1`. The project's own `.local` directory stores the runtime environment, localhost PFX, prepared state and backups, with owner-restricted permissions. These are sensitive and must not go onto GitHub or into another project. Docker volumes live in Docker's data store. Removing a container and deleting data are separate operations.

PowerShell 7.2+, Docker running Linux containers and Compose v2 are required **on the Plot Manager service machine**, with adequate memory and disk space. First startup may download images and spend several minutes initializing the database/repository. The user must accept the SQL Developer license; its source setting defaults to `false`. This is a development sample; the new repository's built-in `admin/admin` login and private localhost certificate are not intended for production use.

<!-- documentation-anchors:start -->
<a id="doc-every-plot-in-actual-execution-order"></a>
<!-- documentation-anchors:end -->
### Every plot in actual execution order

**Every plot starts with the same three invocations.** In the table, common 1–3 always means these three actual rows, not a hidden or separate engine function:

| Order / ID | Native Step | Exact task |
| --- | --- | --- |
| 1. `runtime-directory` | `filesystem.mkdir` | `Path:".local"`; creates the local runtime directory. |
| 2. `configuration` | `json.write` | `Path:".local/settings.json"`, `Value=settings.SenseNet`, `Overwrite:true`; exports layered public installation values. `Authentication` and `Restore` objects do not enter this file. |
| 3. `prepare` | `process.run` | `pwsh -NoProfile -File scripts/Manage-SenseNet.ps1 -Action prepare`; validates license acceptance, names, ports, digests and ownership. On first use it creates its own random SQL password, repository API key, PFX and runtime environment; later it checks and preserves them. |

Every subsequent `process.run` invokes the helper action below with the same `pwsh -NoProfile -File scripts/Manage-SenseNet.ps1` command. Configured process/Compose rows have a 900-second timeout; the helper waits up to 600 seconds for readiness by default. Through StepDefaults, Compose rows use the project's `compose.yaml`, `.local/runtime.env` and project name `settings.SenseNet.StackName`. Each row's `With` therefore contains only that operation's own arguments.

| Plot | **All** IDs / Steps following common 1–3, in order | Action and purpose |
| --- | --- | --- |
| `prepare` | No further rows (3 in total). | Local runtime preparation only; does not bring up services. It also checks Docker ownership, so Docker access is required. |
| `install` | 4. `validate-compose` / `compose.config` (`--quiet`); 5. `start-services` / `compose.up` (`--wait --wait-timeout 240`); 6. `verify-repository-and-login` / `process.run`, action `verify`. | Compose validation, container creation/startup, then actual repository and admin login tests. |
| `start` | 4. `start-services` / `compose.up` (same wait); 5. `verify-repository-and-login` / `process.run`, `verify`. | Starts an existing installation; may also create missing containers. |
| `verify` | 4. `verify-repository-and-login` / `process.run`, `verify`. | Authenticated connection test for a running stack. Does not start containers. |
| `demo-content` | 4. `create-or-read-demo-folder` / `process.run`, `demo-content`. | After login, creates `/Root/Content/PlotManagerDemo` if absent, then reads it back. An existing folder keeps its ID. |
| `verify-demo-content` | 4. `verify-persistent-demo-folder` / `process.run`, `verify -ExpectedContentPath /Root/Content/PlotManagerDemo`. | In addition to login, checks the previously created folder and its ID/Path; does not recreate missing content. |
| `status` | 4. `service-status` / `compose.ps` (`--all`). | Current state of every container in this stack, including stopped ones. Plot success means the query succeeded; read individual service states in its output. |
| `logs` | 4. `service-logs` / `compose.logs` (`--tail 80 --no-color`). | Up to the last 80 lines per service; not continuous log following. |
| `stop` | 4. `stop-services-keep-data` / `compose.stop` (`--timeout 30`). | Stops this stack's containers; containers and volumes remain. |
| `restart` | 4. `stop-services-keep-data` / `compose.stop` (`--timeout 30`); 5. `start-services` / `compose.up` (wait); 6. `verify-repository-and-login` / `process.run`, `verify`. | Stop → start → actual functional verification. |
| `backup` | 4. `offline-consistent-backup` / `process.run`, `backup`. | Stops this stack's services, cold-backs up both volumes, copies private runtime files and creates a SHA-256 manifest. Finally restarts its own services that were previously running. |
| `restore` | 4. `restore-confirmed-backup` / `process.run`, `restore -BackupPath settings.Restore.BackupPath -ConfirmRestore settings.Restore.ConfirmStackName`; 5. `start-services` / `compose.up` (wait); 6. `verify-repository-and-login` / `process.run`, `verify`. | The confirmed backup **replaces** current SQL/App_Data contents belonging to this stack, then the plot starts and verifies. |
| `remove-containers-keep-data` | 4. `remove-containers-keep-volumes` / `compose.down` (empty `With`, no `--volumes`). | Removes this stack's containers and Compose network. Named volumes, `.local` and backups remain; `install` can later recreate containers. |

`process.run` output contains `ExitCode`, `StandardOutput`, `StandardError` and duration; Compose output uses the same process model. The helper prints understandable success messages: URLs, checked content path/ID and backup path. Generated passwords and tokens do not need to be read for this.

<!-- documentation-anchors:start -->
<a id="doc-what-does-the-helper-do-for-each-action"></a>
<!-- documentation-anchors:end -->
### What does the helper do for each action?

| Helper action | Internal process and limits |
| --- | --- |
| `prepare` | Checks the `pm-sensenet-…` name, two distinct ports in 1024–65535, explicit license acceptance and SHA-256 image digests. Matching containers' working directories and volumes' owner labels must agree. Generates its own runtime files once; different bindings or a corrupt/incomplete earlier runtime cause an error rather than silent replacement. |
| `verify` | Using an HTTPS client pinned to the project certificate, checks meaningful `/Root` OData content, OpenID discovery and signing keys; adminui client metadata; actual admin login with authorization code + PKCE; and reading Admin(Id=1) content with the access token. Reads the callback address as data rather than navigating to an external page. Also reads back the specified content when `ExpectedContentPath` is supplied. |
| `demo-content` | The same admin login; requests its own sample folder, creates it as Folder only on 404, then verifies a positive ID and exact Path read back. It is not a general import or an operation modifying all content. |
| `backup` | Checks ownership and completed installation, stops the stack, archives both owned volumes as tar.gz through a temporary networkless helper container from the already-local pinned SQL image. Copies runtime secrets and certificate; lists sizes/hashes. Restarts previously running services. There is downtime during backup. |
| `restore` | Only a directory under this project's `.local/backups`; exact stack-name confirmation; matching binding, images and certificate; names/sizes/hashes of five files. All are checked before replacing data. Replaces its own stopped volumes' contents and restores private files. Leaves services stopped after a partial failure. The complete plot subsequently starts them and checks login. |

<!-- documentation-anchors:start -->
<a id="doc-a-first-installation-from-the-gui"></a>
<!-- documentation-anchors:end -->
### A: first installation from the GUI

1. Open the fourth project → `development` → `Guided setup`.
2. `Target`: check the runner host. Enter a unique `pm-sensenet-…` name and free API and Identity ports. Do not reuse another copy's stack name.
3. `Settings`: read the SQL Developer license and select acceptance only if you accept it.
4. `Save answers →` saves the `SenseNet` overrides in `project.json`.
5. `Run static preflight` → `Continue to run →` → `Run sample installation`. Static success does not yet prove that Docker is running or the port is free.
6. `Run history`: six rows; the final `verify-repository-and-login` success message proves actual OData and admin login checks. On error, `status` followed by `logs` helps diagnosis. Do not interrupt first startup merely because repository initialization takes several minutes.
7. Open the API/Identity localhost URL reported in output. The private certificate is not automatically installed in the OS trusted store, so a browser warning is expected. The API page is not a separately installed Admin UI.

<!-- documentation-anchors:start -->
<a id="doc-b-daily-management-and-data-persistence"></a>
<!-- documentation-anchors:end -->
### B: daily management and data persistence

1. `Plot editor` → `demo-content` → preflight → full run. Record the positive ID of `/Root/Content/PlotManagerDemo`.
2. Rerun `demo-content`: it reads the same folder with the same ID.
3. `stop` → `status`: services stop and data remains.
4. `start` → `verify-demo-content`: the folder is available with the same ID.
5. Use `restart`, then `logs` if needed. Reading logs does not repair a failure; `verify` checks application-level functionality.
6. To try container removal, use `remove-containers-keep-data` → `install` → `verify-demo-content`. This also preserves data; there is no reset plot.

<!-- documentation-anchors:start -->
<a id="doc-c-backup-and-deliberate-restore"></a>
<!-- documentation-anchors:end -->
### C: backup and deliberate restore

1. First have a successful installation and `demo-content`. Do not run parallel writing/management operations against the same stack.
2. `backup` → after success, record the created `.local/backups/<UTC-időpont>-<azonosító>` directory from run output. The backup contains `db-data.tar.gz`, `app-data.tar.gz`, `runtime.env`, `snapp.pfx`, `prepared.json` and a `manifest.json` listing them. It is not a plain SQL `.bak` file.
3. Before restoring, understand that your data created after backup will be lost in the stack being restored. Add this to the **project** layer in `Configuration`, preserving existing fields:

   ```json
   {
     "Restore": {
       "BackupPath": ".local/backups/A-MENTES-KONYVTARA",
       "ConfirmStackName": "pm-sensenet-a-sajat-stack-neve"
     }
   }
   ```

4. `Save selected layer` → `restore` → preflight → full run. The name must exactly match the prepared stack name; an actual restore stops with an error for the empty source values. Static preflight does not check a backup's files or whether the confirmation is meaningful.
5. After success, use `verify-demo-content` if the folder already existed when backed up. The final basic check in `restore` only verifies repository/login operation.
6. Remove both Restore overrides or set them to empty, then save. An accidental later rerun then cannot restore the same backup again.

This version supports local backups for the same stack and same pinned images. It is not a migration tool for another machine or version upgrade; hash checks detect corruption and do not replace an external digital signature. Backups contain passwords: preserve restricted access and do not upload them to the PR.

<!-- documentation-anchors:start -->
<a id="doc-single-step-environment-rerun-and-cleanup"></a>
<!-- documentation-anchors:end -->
### Single step, environment, rerun and cleanup

SenseNet plots have no `steps.…Output` references; much of their ordering depends on files and external state. A successful static single-step check of `start-services` therefore does not create a missing `.local/runtime.env`. Complete plots supply the necessary preparation. Nor do `backup` and `restore` become harmless tests because each is one process row: every internal operation of the action executes.

Source has one `development` environment with empty overrides; the project layer is also empty in a fresh sample. There is no ready production profile, automatic image update or production deployment. On rerun, `.local/settings.json` is refreshed, generated secrets and certificate remain, and `install` starts with the existing volumes. `backup` creates a new backup directory every time.

Before machine shutdown, `stop` stops this stack; closing the Plot Manager window does not. `remove-containers-keep-data` performs more extensive cleanup but deliberately preserves data, images and backups. There is no fully destructive data-cleanup plot. Do not delete `.local` from an installation you intend to resume: the data volumes also require their corresponding local secrets. **Request stop · terminate worker** in `Run history` requests worker termination, not Docker rollback.

If the repository admin password has changed, name the Runner secret `SENSENET_ADMIN_PASSWORD` and use this project setting:

```json
{
  "Authentication": {
    "AdminPassword": {"$env":"PLOTMANAGER_SECRET_SENSENET_ADMIN_PASSWORD"}
  }
}
```

This passes an already existing password to the verification client; it does not modify the SenseNet account. Do not save a new actual password in raw JSON.

<!-- documentation-anchors:start -->
<a id="doc-cli-the-same-layers-and-engine"></a>
<!-- documentation-anchors:end -->
## CLI: the same layers and engine

The GUI uses the native Plot Manager engine. Run these commands from the checkout root. For another project copy, **all three configuration paths and WorkDirectory must point to that same copy**. Direct CLI execution does not create a Run history record in the GUI service.

<!-- documentation-anchors:start -->
<a id="doc-01-guided-file-installer"></a>
<!-- documentation-anchors:end -->
### 01: guided file installer

```powershell
pwsh -NoProfile -File ./src/Deployment/Scripts/Run.ps1 install `
  -DefaultConfigPath ./examples/management-demos/01-vezetett-telepito/default.json `
  -ConfigPath ./examples/management-demos/01-vezetett-telepito/project.json `
  -EnvironmentConfigPath ./examples/management-demos/01-vezetett-telepito/environments/development.json `
  -WorkDirectory ./examples/management-demos/01-vezetett-telepito
```

<!-- documentation-anchors:start -->
<a id="doc-02-exporting-development-settings"></a>
<!-- documentation-anchors:end -->
### 02: exporting development settings

```powershell
pwsh -NoProfile -File ./src/Deployment/Scripts/Run.ps1 show-settings `
  -DefaultConfigPath ./examples/management-demos/02-retegek-es-hivatkozasok/default.json `
  -ConfigPath ./examples/management-demos/02-retegek-es-hivatkozasok/project.json `
  -EnvironmentConfigPath ./examples/management-demos/02-retegek-es-hivatkozasok/environments/development.json `
  -WorkDirectory ./examples/management-demos/02-retegek-es-hivatkozasok
```

Use `production` instead of `development` in the filename for the other environment. Replacing the plot name with `hibas-sorrend` produces the expected dependency error.

<!-- documentation-anchors:start -->
<a id="doc-03-production-package"></a>
<!-- documentation-anchors:end -->
### 03: production package

```powershell
pwsh -NoProfile -File ./src/Deployment/Scripts/Run.ps1 package `
  -DefaultConfigPath ./examples/management-demos/03-json-xml-zip/default.json `
  -ConfigPath ./examples/management-demos/03-json-xml-zip/project.json `
  -EnvironmentConfigPath ./examples/management-demos/03-json-xml-zip/environments/production.json `
  -WorkDirectory ./examples/management-demos/03-json-xml-zip
```

<!-- documentation-anchors:start -->
<a id="doc-04-sensenet-static-preview"></a>
<!-- documentation-anchors:end -->
### 04: SenseNet static preview

```powershell
pwsh -NoProfile -File ./src/Deployment/Scripts/Run.ps1 install `
  -DefaultConfigPath ./examples/sensenet-docker/default.json `
  -ConfigPath ./examples/sensenet-docker/project.json `
  -EnvironmentConfigPath ./examples/sensenet-docker/environments/development.json `
  -WorkDirectory ./examples/sensenet-docker -WhatIf
```

`-WhatIf` can also be added to the first three commands; `-Explain` prints the plan and value origins without execution. Before an actual SenseNet `install`, complete the project layer, accept the license and check local prerequisites; then omit `-WhatIf`. Any documented SenseNet plot can replace the plot name. CLI `-Step` runs a native Step separately; it does not select an invocation ID from an existing plot.

<!-- documentation-anchors:start -->
<a id="doc-relationship-between-github-source-and-installed-copies"></a>
<!-- documentation-anchors:end -->
## Relationship between GitHub source and installed copies

The 14 input JSON files of the first three source projects are byte/hash-identical copies of the original inputs for demos previously created in the application. A fresh copy downloaded from GitHub does not yet contain local result files or run history. SQL license acceptance in the fourth project's source is deliberately not enabled in advance. A wizard-modified value in a local copy can differ.

On a new machine, copy the entire project directory under the runner service's allowed project root and register it with the application's **Open project**. Do not attempt to open another running instance's whole data store simultaneously. Projects are independent; none requires the previous demo's output.
