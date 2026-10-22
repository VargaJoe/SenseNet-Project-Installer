# Plot Manager workspace

The same React application is used by the desktop window and the browser. It
connects only to its own ASP.NET service. The runner card and project context show
the actual service host, operating system, and execution identity. In hosted mode,
steps run on that server; selecting a browser file does not make the browser a
runner. Additional machine agents are future work.

## Connect and open a project

Start the service with the documented management launcher or desktop application.
The local launcher opens a one-time bootstrap fragment, which the UI immediately
removes before exchanging it for an HttpOnly session cookie. In hosted mode, enter
your operator token on the sign-in screen. Tokens and passwords are not stored in
browser localStorage or sessionStorage. Sign out revokes the browser cookie;
closing the browser leaves an active run under service control.

In **Workspace**, create a project or open a directory containing
`plot-project.json` on the service host. All directories must be within the
administrator-configured project root. The optional directory field is a path on
the service host. Project ownership is enforced by the API. Check **Include the
generic guided installation** to begin with the public text/filesystem example.

Choose an environment at the top right. **Project layers only** omits the
environment layer and works with portable projects that declare no environments.
Create another environment in Workspace. The expandable project-definition editor
changes relative configuration paths and the declarative wizard; it saves with a
version check. Keep machine-specific secrets outside this portable file.

## Edit configuration without flattening inheritance

Choose **Configuration** and explicitly select Default, Project, or the chosen
environment layer. The source JSON editor reads and saves only that original
file. The right pane shows the saved effective configuration and exact file
provenance returned by the PowerShell engine. Unsaved edits are never presented as
an engine-computed effective result.

The native rules remain unchanged: objects merge recursively, arrays replace as
a whole, and missing properties inherit. Explicit `null`, `false`, `0`, and `[]`
are values, each distinct from a missing property. Unknown valid properties are
preserved. Existing native key spelling, including lowercase `plots`, `steps`, and
parameter names, is retained when editing known fields visually.

Raw layers use precision-preserving JSON parsing and serialization. Unknown large
integers, exact decimal literals, and JSON numbers beyond JavaScript's finite
range remain numeric literals through unrelated edits and saves. Safe API
counters stay ordinary numbers. An unsafe numeric parameter is edited through its
JSON value field; the native engine still decides whether that parameter type is
supported. The effective view reflects the engine's numeric types and may differ
in precision from the raw source; it is never used to overwrite unknown raw data.

To restore inheritance, remove the override property from the source JSON, or use
the JSON-pointer helper, for example `/Sample/Message`. Escape `/` in a key as
`~1` and `~` as `~0`. The helper removes object properties; remove the entire array
property to inherit an array. Save the selected layer, then inspect the refreshed
effective result. It never writes the effective object over a source layer.

Each save carries the last-read file version. Another edit or an active project
run returns a conflict instead of overwriting changes. Keep your draft, reload the
latest version, compare, and reapply your change. Navigation that switches the
active source asks before discarding a changed layer; closing a dirty page also
uses the browser’s unsaved-change prompt.

## Compose a sequential plot

In **Plot editor**, select a saved plot or create one. The installed catalog comes
from package manifests and shows platform support, required tool availability,
parameter descriptions, defaults, declared outputs, and versions. A missing tool
is an actionable prerequisite on the displayed runner. Windows-only packages do
not become cross-platform through the UI.

Add a catalog step, select its invocation, and configure its generated parameter
form. The same step can appear repeatedly. Every new occurrence receives a stable
invocation ID. Copy, remove, and move controls operate on those occurrences; moving
an invocation retains its ID. Renaming an ID requires updating references that
point to it. Reordering may invalidate an earlier-output dependency: save and
preflight again before running.

The parameter source control distinguishes inherited/omitted values, ordinary
typed values, JSON arrays/objects, explicit null where allowed, settings/output
references, and runner environment/secret references. A JSON field applies only
after valid JSON is entered and the field loses focus; an inline error retains
the last valid value. Correct any displayed field error before saving.

Native references remain ordinary JSON:

```json
{"$ref":"settings.Sample.Message"}
{"$ref":"steps.compose.Output.Text"}
{"$env":"PLOTMANAGER_SECRET_EXAMPLE"}
```

Output suggestions include only earlier invocation IDs. The engine, rather than
the UI, performs reference resolution, schema validation, settings merging, and
execution. Deferred output values and their final types are checked when the
consumer executes. Unknown invocation/plot metadata survives visual changes.
The source JSON view is available for fields beyond the generated form. Editing
an inherited plot explicitly overrides its complete step array in the selected
layer. The array comes from the exact raw file identified by engine provenance;
its invocation metadata is retained. Other inherited plot properties stay
inherited rather than being copied into the selected layer. Existing properties
already present in that selected plot object remain intact.

Run overrides are a separate JSON map keyed by invocation ID. They apply after
saved layers for that request only. They are not saved into project files. Use
environment references rather than literal secrets in this map.

## Preflight, preview, and execute

Save before execution. **Preflight plot** calls the real engine’s static plan
operation and shows effective invocation settings, parameter-setting layers,
exact originating file/path, and reference-origin chains. It does not invoke
step commands or test live external connections. **WhatIf preview** creates a
durable preview run whose package commands are skipped. It also performs no
active connection test.

**Run plot** starts the full sequential plot. **Run invocation** selects only that
occurrence after engine preflight. A single invocation cannot depend on outputs
from earlier invocations or another run; the service rejects that request instead
of silently running its prerequisites. Statically invalid configuration is
rejected before any package command executes.

Starting a run records an immutable copy of selected configuration and package
versions/hashes. Later edits cannot change that run. Only one conflicting run
holds a project at a time, and saving configuration is blocked while it runs.

**Run history** contains durable run IDs, state, per-step state and duration,
structured results, the snapshot fingerprints, and an event log. The UI polls
durable events using the returned cursor, retries interrupted connections, and
replays history after reload. The URL contains project/environment/run IDs only;
reopen it, authenticate if necessary, and select Run history to reconnect.

**Request stop** terminates the worker process tree. `Cancelled` is not a
successful rollback. Files or services already changed stay changed, and an
external service operation can continue. Service restart marks an unfinished run
`Interrupted` without retrying potentially non-idempotent work.

## Generic guided installation

Create a fresh sample project and open **Guided setup**:

1. Confirm the service-host execution identity and choose an output file such as
   `hello.txt` in the isolated project directory.
2. Enter the message to write and save the answers.
3. Run static preflight and inspect the two planned invocations.
4. Start the real installation.
5. Inspect `Succeeded`, the structured output, and the written UTF-8 file.

The portable `wizard` descriptor declares groups, typed fields, and ordinary
configuration `settingPath` bindings. Answers update its selected source layer,
retaining unrelated/unknown values. The generic example binds `target` to
`Sample.Target` and `message` to `Sample.Message`; the ordinary `install` plot
joins that message and writes it. The same saved configuration works from CLI:

```powershell
pwsh -NoProfile -File ./src/Deployment/Scripts/Run.ps1 install `
  -DefaultConfigPath <project>/default.json `
  -ConfigPath <project>/project.json `
  -EnvironmentConfigPath <project>/environments/development.json `
  -WorkDirectory <project>
```

Remove only your sample output file and, when finished, your isolated sample
project. Do not select an existing application directory for a disposable test.

## Files, secrets, and certificates

**Browse on the runner** lists paths on the service host within its allowed root.
It transfers nothing. **Upload a file from this computer** deliberately copies a
browser-selected file into the project’s `uploads/` directory on the service host
and returns its relative path. Use that path explicitly in configuration.

**Runner secrets** stores encrypted service-local values and returns only their
`$env` references. A secret is injected into the worker environment for the
authenticated operator; the secret value is not returned by list/read APIs or
written into run snapshots. Clear literal credentials from portable project
files. Package authors must not return secrets in step output.

Keep three separate concerns clear: the GUI/API HTTPS certificate protects the
browser-service connection; a step’s TLS/CA/client certificate settings belong to
the service the runner contacts; and certificates installed by a plot belong to
the target application. Runner identity and host paths determine where step
credentials and certificate stores are used. Do not disable certificate
verification as a default workaround.

## Frontend development and checks

The build was verified with Node.js 20.20.0 (the Vite toolchain requires at least
20.19 in the Node 20 line). Run from
`src/Management/Web`:

```powershell
npm ci
npm run build
npm test
```

The build writes `dist/`, which the service copies into its published static
assets. It needs no external font, image, or CDN at runtime. For integrated
acceptance tests, use `pwsh -NoProfile -File
./scripts/management/Test-Management.ps1` from the repository root. It builds an
isolated service and invokes the browser tests against the real worker. Install
the Playwright Chromium browser once with `npx playwright install chromium` in
the Web directory. The tests cover real wizard output bytes, typed unknown-data
roundtrip, reordered dependency rejection, full/single runs, and event replay.

The frontend unit suite covers typed layer edits, key-spelling preservation,
stable IDs, reference forms, hidden declared secrets, and cookie/CSRF transport.
Build success and these tests are separate from desktop installation/native
WebView smoke checks and actual Linux runner evidence; see the delivery report
and [management deployment and packaging](management-deployment.md) for the platform matrix.
