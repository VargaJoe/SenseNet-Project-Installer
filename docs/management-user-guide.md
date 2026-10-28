<!-- documentation-anchors:start -->
<a id="doc-plot-manager--complete-user-guide"></a>
<!-- documentation-anchors:end -->
# Plot Manager – complete user guide

<!-- documentation-navigation -->
[English](management-user-guide.md) | [Magyar](management-user-guide-hu.md) · [Documentation](README.md) · [Project](../README.md)
<!-- /documentation-navigation -->

This guide describes the current Plot Manager desktop and browser interface. English labels appear exactly as they do in the GUI, followed by an explanation of their meaning and effect. You can follow the page descriptions on GitHub without the local machine or a running application.

A detailed, step-by-step presentation of the four prepared projects is available in [Demo projects and scenarios](management-demo-projects.md). The `04 – SenseNet Docker telepítés és menedzsment` project also has a separate [installation and operations guide](../examples/sensenet-docker/README.md).

The editing-state preservation fixes described below belong to the `codex/management-editing-safety` source branch. The previously delivered installers built from `a8cb561b` still contain the interface from before these fixes. The [validation results](management-validation.md#doc-editing-safety-follow-up) distinguish source checks from package checks.

<!-- documentation-anchors:start -->
<a id="doc-contents"></a>
<!-- documentation-anchors:end -->
## Contents

1. [What are projects, plots and steps?](#doc-1-what-are-projects-plots-and-steps)
2. [Where does it run and store data, and what happens when it closes?](#doc-2-where-does-it-run-and-store-data-and-what-happens-when-it-closes)
3. [Signing in and the screen layout](#doc-3-signing-in-and-the-screen-layout)
4. [Workspace – projects and environments](#doc-4-workspace--projects-and-environments)
5. [Configuration – source layers and inheritance](#doc-5-configuration--source-layers-and-inheritance)
6. [Plot editor – composing steps](#doc-6-plot-editor--composing-steps)
7. [Validation, preview and actual execution](#doc-7-validation-preview-and-actual-execution)
8. [Run history – results, logs and stopping](#doc-8-run-history--results-logs-and-stopping)
9. [Guided setup – guided configuration](#doc-9-guided-setup--guided-configuration)
10. [Runner secrets – managing secrets](#doc-10-runner-secrets--managing-secrets)
11. [Complete workflows](#doc-11-complete-workflows)
12. [Errors and frequently asked questions](#doc-12-errors-and-frequently-asked-questions)
13. [Current limits and further documentation](#doc-13-current-limits-and-further-documentation)

<!-- documentation-anchors:start -->
<a id="doc-1-what-are-projects-plots-and-steps"></a>
<!-- documentation-anchors:end -->
## 1. What are projects, plots and steps?

| Term | Meaning | Example |
| --- | --- | --- |
| **Workspace** | The projects registered for the current user in this Plot Manager service. | The four demos appearing on the opening page. |
| **Project** | A directory containing the portable project definition, configuration and any input files or helper programs. | The SenseNet Docker project with its own `compose.yaml` file. |
| **Plot** | A named sequence of operations to execute in order. A project can have several plots. | `install`, `status`, `backup`. |
| **Step / step definition** | A reusable operation from an installed package, with defined parameters and a result. | `text.join`, `filesystem.write`, `compose.up`. |
| **Invocation / step occurrence** | A particular step call in a plot, with its own stable ID and parameters. | The `filesystem.write` call with ID `save`. |
| **Environment** | A selected configuration layer that overrides, for example, a development filename or port. | `development`, `production`; the name alone does not mean a live production system. |
| **Runner** | The machine and operating-system user running the Plot Manager service. | The machine/identity shown on the bottom-left card and top bar. |
| **Run** | A particular execution of a saved plot, with its own run ID, state and durable result. | Starting the same `install` plot twice creates two runs. |
| **Preflight** | The engine's static validation before actual package operations are invoked. | Are parameters valid, does the step exist, and are dependencies in the correct order? |

A plot is linear: the first step is followed by the second, then the third. An earlier step's output can be a later step's input. The GUI uses the same PowerShell engine as native command-line execution.

<!-- documentation-anchors:start -->
<a id="doc-2-where-does-it-run-and-store-data-and-what-happens-when-it-closes"></a>
<!-- documentation-anchors:end -->
## 2. Where does it run and store data, and what happens when it closes?

<!-- documentation-anchors:start -->
<a id="doc-the-browser-is-the-interface-the-service-does-the-work"></a>
<!-- documentation-anchors:end -->
### The browser is the interface; the service does the work

```text
Desktop window or browser
          │ configuration, starting runs, displaying results
          ▼
Plot Manager service on the displayed machine
          │ with the displayed operating-system user's permissions
          ▼
PowerShell engine → files / Docker / HTTP / other installed packages
```

This is an explanatory diagram, not a screenshot. **PROJECT DIRECTORY** is a directory on the service machine. **EXECUTION TARGET** shows which machine and user perform operations. In a browser connected to a remote server, `localhost`, Docker and file paths are interpreted from the runner's perspective unless the step defines another target.

The same React application runs in the desktop window and browser and connects only to its own ASP.NET service. The **Environment** selector changes configuration; it does not select another runner machine. The current GUI uses one service's own runner. There is no interface for selecting multiple remote agents yet.

<!-- documentation-anchors:start -->
<a id="doc-storage-locations-and-format"></a>
<!-- documentation-anchors:end -->
### Storage locations and format

The following are the standard launchers' defaults on Windows. The operator can configure another data store and allowed project root.

| Launch mode | Default data store | Default project root |
| --- | --- | --- |
| Installed desktop application | `%LOCALAPPDATA%\io.github.vargajoe.plotmanager` | The data store's `projects` subdirectory. |
| `Start-Management.ps1` browser launcher | `%LOCALAPPDATA%\PlotManager\browser` | The data store's `projects` subdirectory. |
| Directly started or hosted service | The operator's `PLOTMANAGER_DATA` setting; for direct startup the service default is `%LOCALAPPDATA%\PlotManager`. | `PLOTMANAGER_PROJECT_ROOT`, or the data store's `projects` directory if it is unset. |

Linux uses the corresponding user application-data directory; the actual project path is always visible in the GUI. The desktop launcher's project root can be changed through the local `PLOTMANAGER_DESKTOP_PROJECT_ROOT` launch setting; see the [deployment guide](management-deployment.md#doc-native-desktop).

The program's installation directory contains program files. Settings live in the project's selected JSON files; the service data store contains the project registry, run history and local secret store. Projects are not automatically registered from the source-code checkout.

A typical portable project has this structure:

```text
project/
├── plot-project.json             # name, configuration files, optional wizard
├── default.json                  # shared defaults and plots
├── project.json                  # this project's own overrides
├── environments/
│   └── development.json          # environment override
├── uploads/                     # files deliberately uploaded through the GUI
└── ...                          # the project's own files and results
```

`default.json` and `project.json` are conventional names, not required filenames: the relative paths in `plot-project.json` determine which files are used. Configuration retains the native engine's existing JSON format. `plot-project.json` adds a portable GUI project definition; the GUI does not turn the layers into a new, flattened settings file. Historical `-Legacy` configuration has a separate compatibility path; see [the legacy format](legacy/settings.md).

Demos with the same name in the desktop and browser instances' separate data stores are independent copies. Changes in one do not automatically synchronize to the other. Copy the whole project when moving it, but do not treat local secrets, the run data store or, for example, SenseNet's generated `.local` directory as shareable source.

<!-- documentation-anchors:start -->
<a id="doc-closing-signing-out-and-shutting-down-the-machine"></a>
<!-- documentation-anchors:end -->
### Closing, signing out and shutting down the machine

| Action | Effect |
| --- | --- |
| Closing a browser tab | The service and run can continue. Unsaved edits may be lost. |
| **Sign out** | Signs out of the GUI; it does not stop a run. |
| Stopping the browser launcher terminal or service | Also stops the service's own worker processes. |
| Closing the desktop window | Requests confirmation: **Close and stop** stops its own local service and workers; **Keep open** leaves the application open. |
| Shutting down the machine | The local service and its processes stop. Saved files and run records remain. The outcome of external operations already started must be checked separately. |

A Docker container started earlier has its own lifecycle; closing the GUI is different from running the project's `stop` plot. To stop the SenseNet stack, run the project's dedicated plot. Cancelling a run does not undo changes already made.

<!-- documentation-anchors:start -->
<a id="doc-3-signing-in-and-the-screen-layout"></a>
<!-- documentation-anchors:end -->
## 3. Signing in and the screen layout

<!-- documentation-anchors:start -->
<a id="doc-signing-in"></a>
<!-- documentation-anchors:end -->
### Signing in

The standard local launcher and desktop application prepare their own authenticated connection. If the sign-in page appears, enter the operator token supplied for the service in **Access token**, then select **Connect to workspace**.

This signs in to Plot Manager; it is not the SenseNet `admin` password, a Docker Hub password or a value from **Runner secrets**. The interface exchanges the token for an HttpOnly session cookie. The frontend does not save it in browser `localStorage`, `sessionStorage` or project files. The one-time bootstrap token fragment in the local launch URL is immediately removed from the address before the exchange. Signing out revokes the browser cookie.

<!-- documentation-anchors:start -->
<a id="doc-layout-map"></a>
<!-- documentation-anchors:end -->
### Layout map

The diagram illustrates the shared structure rather than the exact dimensions of any particular screen.

```text
┌──────────────────────┬──────────────────────────────────────────────────────┐
│ Plot Manager         │ Workspace / project name / current page    identity  │
│ ACTIVE PROJECT       ├──────────────────────────────────────────────────────┤
│ project, plot count  │ Page title                        Environment [▼]     │
│                      │ Error / success / unsaved-change notice              │
│ Workspace            │ PROJECT DIRECTORY     EXECUTION TARGET     [Ready]    │
│ Plot editor          ├──────────────────────────────────────────────────────┤
│ Configuration        │ This page's toolbar and panels                       │
│ Run history          │                                                      │
│ Guided setup         │ For example, Plot editor:                            │
│ Runner secrets       │ [steps + catalog]      [selected step's parameters]   │
│                      │                                                      │
│ runner host / OS     │ For example, Configuration:                          │
│ mode / protocol      │ [editable source]      [saved effective configuration]│
│ Sign out             │                                                      │
└──────────────────────┴──────────────────────────────────────────────────────┘
```

| Shared element | What does it show or do? |
| --- | --- |
| **Plot Manager** logo | Returns to **Workspace**. |
| **ACTIVE PROJECT** | The currently selected project, available plot count and environment. |
| Six navigation buttons on the left | Open the pages described in the following chapters. Without a project, only **Workspace** and **Runner secrets** are available. |
| Top breadcrumb | Shows the current project and page. |
| Top machine identity and bottom-left runner card | The runner's actual machine, OS, `local`/`hosted` mode, operating-system identity and protocol. |
| **Environment** | Selects from the already declared environments. **Project layers only** uses the default and project layers without an environment layer. |
| **PROJECT DIRECTORY** | The selected project's absolute directory on the service machine. |
| **EXECUTION TARGET** | The service machine and actual execution user. |
| **Ready / Running** badge | Whether this project has an active run holding a lock. `Ready` is not a health check for the Docker stack or another external application. |
| **×** on an error/success message | Dismisses the message only; it does not undo the operation. |
| **Unsaved changes** warning | The selected configuration layer has an unsaved draft. **Save selected layer** saves the same layer as the editor's **Save layer** button. |
| **Unsaved project definition changes** warning / **Open project definition** | The separate portable project-definition draft has not been saved. The button returns to the definition panel in **Workspace**, where you can save or reload it. |
| **Unapplied parameter edits** warning | Text entered in a parameter field has not yet been applied. Saving and running remain blocked until you correct it or confirm discarding it. |
| Controls disabled during an operation | The GUI prevents another conflicting operation or layer writes during a run. Follow the run in **Run history**. |
| **Sign out · …** | Signs out of the current operator session. |
| Expandable rows and JSON panels | Click the title to expand/collapse. A JSON display panel is a readable result; a text-area JSON editor is editable source. |

<!-- documentation-anchors:start -->
<a id="doc-4-workspace--projects-and-environments"></a>
<!-- documentation-anchors:end -->
## 4. Workspace – projects and environments

![Workspace: project list, creation, shortcuts and project definition](images/management/01-workspace.png)

*Actual interface with demo 01; machine, account and directory details are anonymized.*

<!-- documentation-anchors:start -->
<a id="doc-statistics-and-project-selection"></a>
<!-- documentation-anchors:end -->
### Statistics and project selection

| Panel/control | Use |
| --- | --- |
| **PROJECTS** | Number of projects registered for the current operator. |
| **INSTALLED STEPS** | Size of the service's installed step catalog. |
| **ACTIVE PLOTS** | Number of plots in the selected project's saved, merged configuration. |
| **Your projects** | Project cards with names and actual directories. Click a card to select the project. |
| **Open existing project on the service host** | Enter an existing runner-side directory containing `plot-project.json`. |
| **Open project** | Registers/opens this existing project in the workspace. It does not upload a directory from your browser computer. |

The path must be within the service's allowed project root. The service rejects unknown paths, paths belonging to another user, disallowed paths and paths it cannot resolve safely. The API enforces project ownership.

<!-- documentation-anchors:start -->
<a id="doc-new-project"></a>
<!-- documentation-anchors:end -->
### New project

| Field/button | Use |
| --- | --- |
| **Project name** | Display name for the new project, up to 120 characters. |
| **Service-host directory (optional)** | A new or empty directory on the runner machine. If left empty, the service creates its own folder under the allowed root. |
| **Include the generic guided installation** | When checked, creates the generic text/filesystem sample and its guided form. It does not generate a SenseNet installer. |
| **+ Create project** | Creates the project and layer files; when created with the sample, it opens **Guided setup** immediately. Use **Open project** to open an existing nonempty project. |

<!-- documentation-anchors:start -->
<a id="doc-continue-with--panel"></a>
<!-- documentation-anchors:end -->
### Continue with … panel

| Control | Destination |
| --- | --- |
| **Guided setup** | The project's declared guided form. |
| **Build your plot** | **Plot editor**. |
| **Inspect configuration** | **Configuration**. |
| **Add environment** field | New environment name: 1–64 letters, digits, `_` or `-`, for example `staging`. |
| **Create environment** | Creates an environment JSON file and a corresponding project-definition entry, then selects it. It does not install a separate application or infrastructure. |
| **Portable project definition** | A readable JSON view of the registered project's portable definition. |

<!-- documentation-anchors:start -->
<a id="doc-edit-portable-project-definition-"></a>
<!-- documentation-anchors:end -->
### Edit portable project definition …

This expandable advanced panel edits `plot-project.json`. **Portable project definition JSON** shows the name, relative configuration paths, environments and `wizard` descriptor.

- **Reload definition** loads the latest project definition and asks for confirmation before discarding local changes.
- **Save definition** saves the definition with a version check and refreshes related project data. It is disabled during a run or while a configuration layer is unsaved.

This save is separate from **Save layer**. The project-definition draft survives navigation between GUI pages; switching projects requires confirmation to discard it, and closing the window/browser may also warn about an unsaved definition. A successful **Save definition** clears the definition's own unsaved state. Unknown valid metadata is preserved. The service checks the format version, file paths and wizard bindings. This file is not a secret store.

Minimal portable definition:

```json
{
  "formatVersion": 1,
  "name": "Saját példa",
  "configuration": {
    "default": "default.json",
    "project": "project.json",
    "environments": {
      "development": "environments/development.json"
    }
  }
}
```

<!-- documentation-anchors:start -->
<a id="doc-5-configuration--source-layers-and-inheritance"></a>
<!-- documentation-anchors:end -->
## 5. Configuration – source layers and inheritance

![Configuration: selected source layer and effective configuration](images/management/03-configuration.png)

*Actual interface with demo 01; machine, account and directory details are anonymized.*

<!-- documentation-anchors:start -->
<a id="doc-the-top-editing-toolbar"></a>
<!-- documentation-anchors:end -->
### The top editing toolbar

This bar appears on both **Configuration** and **Plot editor**.

| Control | Effect |
| --- | --- |
| **Editing source layer** | Selects the specific source file you edit: default, project or the selected environment's layer. |
| Adjacent path and **version …** | The original layer file and a short identifier for its last-read version. |
| **Reload** | Reloads the layer and effective configuration. Asks for confirmation before discarding an unsaved draft. |
| **Save layer** | Saves only the selected source file, then asks the engine to recompute effective configuration. Disabled for invalid JSON, an active run or no changes. |

**Environment and Editing source layer are two separate choices.** For example, in `development` you can still edit the default layer; the project or development layer may continue to override that value in the result.

<!-- documentation-anchors:start -->
<a id="doc-source-and-effective-configuration"></a>
<!-- documentation-anchors:end -->
### Source and effective configuration

| Panel/expandable section | Meaning |
| --- | --- |
| **Source layer / Editable layer JSON** | Editable content of the single selected JSON file. Its root must be a JSON object. |
| **Effective configuration / Engine resolved** | Configuration merged by the PowerShell engine from saved files. It is not a live preview of unsaved text on the left. References can still appear as references here; preflight shows a step's final parameters. |
| **Exact file provenance** | Shows which source file supplied the winning value at each configuration path. |
| **Ordered source files** | The files read by the engine, in order. |
| **Restore inheritance at JSON pointer** | Removes a specific override from the selected layer. |
| **Remove override** | Removes the specified object property from the editing draft; **Save layer** is then required. |

<!-- documentation-anchors:start -->
<a id="doc-two-successive-orders"></a>
<!-- documentation-anchors:end -->
### Two successive orders

First, configuration files are merged:

```text
default file → project file → selected environment file
            a later layer overrides the earlier value at the same location
```

Then an invocation's parameters receive their values. Later entries in this list take precedence:

1. The step parameter schema's own defaults.
2. Configuration `Defaults`.
3. `StepDefaults["package.step"]` settings for the particular step.
4. The top-level `Section` selected by the invocation.
5. The plot's own `Defaults`.
6. The invocation's `With` parameters.
7. Run overrides addressed by invocation ID for this particular run.

Changing a general default therefore does not automatically override a value already specified in a step's `With`. For steps with different parameter sets, do not put a parameter that has no meaning for every step into global `Defaults`; use `StepDefaults` or a specific `With` field.

<!-- documentation-anchors:start -->
<a id="doc-inheritance-rules-with-an-example"></a>
<!-- documentation-anchors:end -->
### Inheritance rules with an example

| Source value | Meaning |
| --- | --- |
| Missing property | Inherits the earlier layer's value. |
| Object | Its properties merge recursively. |
| Array, for example `["a"]` | Replaces the entire earlier array. |
| Empty array `[]` | An intentionally empty array; it does not mean inherited. |
| `null` | Explicit null; the consuming parameter must allow it. |
| `false`, `0`, `""` | Actual values, not missing settings. |

Example using three separate files:

`default.json`:

```json
{"Values":{"Message":"Alap","Enabled":true,"Items":["a","b"]}}
```

`project.json`:

```json
{"Values":{"Message":"Projekt","Enabled":false}}
```

`environments/development.json`:

```json
{"Values":{"Message":"Fejlesztői","Items":[]}}
```

The effective values for `development` are `Message = "Fejlesztői"`, `Enabled = false`, `Items = []`. With **Project layers only**, they are `Message = "Projekt"`, `Enabled = false`, `Items = ["a","b"]`.

To remove the project layer's `Values.Message` override, select the project layer, enter pointer `/Values/Message`, click **Remove override**, then **Save layer**. Encode `/` within a key as `~1` and `~` as `~0` in the pointer. The helper removes object properties; to restore inheritance of an array, remove the whole array property.

Saving does not write the merged right-hand object back into the left-hand layer. Unknown valid fields and original key spelling are preserved, including native lowercase `plots`, `steps` and parameter names when known fields are edited visually. The source JSON editor uses precision-preserving parsing and serialization: unknown large integers, exact decimal literals and numbers beyond JavaScript's finite range remain numeric literals through unrelated edits and saves. Safe API counters remain ordinary numbers. Edit an unsafe numeric parameter through its JSON value field; the native engine still decides whether that parameter type is supported. The engine's effective view uses its own numeric types and may have different precision, so do not copy that readable view back over a complete source layer.

<!-- documentation-anchors:start -->
<a id="doc-save-conflicts-and-unsaved-changes"></a>
<!-- documentation-anchors:end -->
### Save conflicts and unsaved changes

Every save refers to the last-read file version. If another window, operator or external editor changed the same file, the service rejects the overwrite with `409`/`changed`. Keep the necessary part of your draft, **Reload**, compare the latest content and reapply your change.

When switching projects, environments or source layers, the GUI asks before discarding a changed configuration draft. Closing the browser may also warn about an unsaved layer, definition or unapplied parameter input. Preflight and execution use saved files: resolve field errors and save before validating/running.

<!-- documentation-anchors:start -->
<a id="doc-files--locations--files-and-paths"></a>
<!-- documentation-anchors:end -->
### Files & locations – files and paths

This panel is at the bottom of **Configuration**.

| Control/panel | Behavior |
| --- | --- |
| **Browse on the runner** | Lists locations on the service machine within the allowed project root. |
| **Service-host path** | Enter the runner-side path here. An empty field requests the root. |
| **Browse runner** | Retrieves that directory's listing. **Allowed root** shows the permitted root. |
| Directory name in the list | Opens/lists the directory. |
| Filename in the list | Places its path into the field. It does not download or edit it, or automatically add it to a step. |
| **Upload a file from this computer / Local browser file** | Actually copies the browser-selected file to this project's `uploads/` directory on the service. |
| **Transferring file…** | Upload is in progress. The success message returns the created relative path. |

Upload copies one file, up to 10 MiB, with a unique filename. You must place the returned path, for example `uploads/…-input.json`, into the appropriate configuration parameter. Do not use this sample-file upload to manage secrets or private keys; use **Runner secrets** for secrets.

<!-- documentation-anchors:start -->
<a id="doc-6-plot-editor--composing-steps"></a>
<!-- documentation-anchors:end -->
## 6. Plot editor – composing steps

![Plot editor: sequential steps, installed catalog and selected invocation settings](images/management/02-plot-editor.png)

*Actual interface with demo 01; machine, account and directory details are anonymized.*

<!-- documentation-anchors:start -->
<a id="doc-plot-selector-and-the-two-main-panels"></a>
<!-- documentation-anchors:end -->
### Plot selector and the two main panels

| Element | Behavior |
| --- | --- |
| **Plot** selector | Selects from plots in the saved configuration and current draft. |
| **+ New plot** | Asks for a name and creates an empty plot in the current source layer's draft. A plot with the same name cannot be created again. Add steps, then **Save layer**. |
| **Sequential steps / In order** | The selected plot's execution order. The number indicates order, the larger label is the invocation ID, and the smaller label is the step definition. |
| Clicking a step row | Shows this particular occurrence's parameters in **INVOCATION SETTINGS** on the right. |
| **Installed step catalog** | Operations from packages installed in the service. Search filters by ID and description. |
| Catalog **+** / step card | Appends a new occurrence to the plot with a new stable ID and an initially empty `With` object. |

The catalog shows package name, version, description, platform restrictions, required external tools and their `available`/`missing on runner` state. An **Unsupported** step cannot be added on that platform. Docker, Git and other external tools must actually be available on the runner machine; software installed on the browser computer does not thereby become available on the server.

<!-- documentation-anchors:start -->
<a id="doc-step-row-buttons"></a>
<!-- documentation-anchors:end -->
### Step-row buttons

| Button | Effect |
| --- | --- |
| **↑** / **Move … earlier** | Moves the occurrence one position earlier. Disabled for the first row. |
| **↓** / **Move … later** | Moves it one position later. Disabled for the last row. |
| **⧉** / **Copy …** | Places a copy immediately after it with a new ID. Parameters are copied too. |
| **×** / **Remove …** | Removes the occurrence from the draft. **Save layer** makes the change durable. |

Reordering retains the ID. Copying retains the original targets of copied references; review whether those targets are still intended. If you remove or rename a producer step, separately repair references pointing to it. Run preflight again after saving.

Editing a plot's steps inherited from an earlier layer creates an override of the plot's **entire step array** in the selected layer. A later layer does not append array elements individually. The editor obtains the array from the exact raw file identified by engine provenance and preserves original invocation metadata. Other plot properties that are not overridden can remain inherited rather than being copied into the selected layer; properties already present in the selected plot object remain intact.

<!-- documentation-anchors:start -->
<a id="doc-invocation-settings--the-step-occurrences-parameters"></a>
<!-- documentation-anchors:end -->
### INVOCATION SETTINGS – the step occurrence's parameters

| Field/section | Meaning |
| --- | --- |
| **Stable invocation ID** | Unique identifier within the plot. Starts with a letter, followed by letters, digits, `_` or `-`. Steps referencing it must be updated separately after a rename. |
| **Configuration section (optional)** | Selects a top-level configuration section according to the native `Section` rule. It is not a new file path or working directory. |
| Schema-generated parameter fields | Accepted parameters, types, required status, descriptions and any allowed value list for the installed step. |
| **Declared output metadata** | The step's declared output fields. This describes possible output; actual results are produced only during execution. |
| Unknown-step warning | Configuration refers to a step absent from the installed catalog. It can be inspected as JSON, but the engine cannot execute it as an available step. |

For each parameter, select its source as well as its value:

| Parameter-source label | JSON / effect |
| --- | --- |
| **Inherited / omitted** | Omits the parameter from this occurrence; the engine looks for an inherited or default value according to precedence rules. This does not delete a property from the whole configuration file. |
| **Value** | Direct value. A `false`/`true` selector for bool, a number field for an integer, and an allowed-value list for `ValidateSet`. |
| **JSON value** | An array, object or other valid JSON value. It enters the draft only when valid and after you leave the field. |
| **Settings / output reference** | `{"$ref":"…"}` references a configuration value or an earlier invocation's output. The field also offers suggestions. |
| **Runner environment / secret** | `{"$env":"…"}` requests the **name** of a runner environment variable or a variable provided by the secret store, not the secret's value. |
| **Explicit null** | Explicit `null`, only if the parameter schema allows it. This does not mean inheritance. |

For parameters declared secret, the GUI does not offer direct `Value`/`JSON value` input. Use a `$env` reference from the secret store or an appropriate reference chain; the service rejects direct secret literals.

**Leaving the field matters when editing JSON.** If `Unapplied JSON` or `Invalid JSON` appears, the last valid value remains in the draft and saving, preflight, preview and execution are disabled. Correct the text, leave the field and only then save. The same protection applies to a cleared or invalid numeric value. When switching to another step or view with unapplied input, the GUI separately asks for confirmation to discard it; declining preserves the text. Pressing save in another field does not resolve an inline error.

<!-- documentation-anchors:start -->
<a id="doc-references-with-a-concrete-example"></a>
<!-- documentation-anchors:end -->
### References with a concrete example

```json
{"$ref":"settings.Values.Message"}
```

This uses `Values.Message` from the saved configuration merged from its layers.

```json
{"$ref":"steps.compose.Output.Text"}
```

This is the `Text` output of invocation `compose`, executed **earlier in the same run**. It is not a previous run's result or an automatic search for a package named `compose`.

```json
{"$env":"PLOTMANAGER_SECRET_EXAMPLE"}
```

This is the name of a variable available on the runner. A reference object must contain exactly one directive. `$ref` and `$env` are neither PowerShell expressions nor templates for substitution within text; for example, `"prefix {$ref:...}"` does not use this mechanism. Keys in a dot-separated reference path cannot themselves contain dots. Circular, missing and forward references are invalid. Output suggestions include only earlier invocation IDs. The engine resolves references, validates schemas, merges settings and executes operations; the GUI does not replace those native rules.

In this complete plot, the second step writes the first step's result to a file:

```json
{
  "Values": {"Message": "Szia"},
  "Plots": {
    "hello": {
      "Steps": [
        {
          "Id": "compose",
          "Step": "text.join",
          "With": {
            "Items": [{"$ref":"settings.Values.Message"}, "Plot Manager"],
            "Separator": " – "
          }
        },
        {
          "Id": "save",
          "Step": "filesystem.write",
          "With": {
            "Path": "hello.txt",
            "Content": {"$ref":"steps.compose.Output.Text"},
            "Overwrite": true
          }
        }
      ]
    }
  }
}
```

Relative path `hello.txt` is created in the project's working directory. Use the example in your own demo project: `Overwrite: true` overwrites an existing `hello.txt` in that location.

<!-- documentation-anchors:start -->
<a id="doc-additional-expandable-panels"></a>
<!-- documentation-anchors:end -->
### Additional expandable panels

| Panel | Behavior |
| --- | --- |
| **Run overrides · applied after every saved configuration layer** | JSON overrides for this run request; the field is **Run overrides JSON, keyed by invocation ID**. They are not saved to project files. |
| **Selected source JSON · unknown fields preserved** | The complete editable JSON of the selected source layer. It is the same draft as on **Configuration**; fields beyond the visual form can also be edited here. |
| **Engine preflight** | The last successful static validation result, detailed in the next chapter. |

For example, the `save` step above can use a different target file for a single run:

```json
{"save":{"Path":"hello-once.txt","Overwrite":true}}
```

This top-level override map is addressed by the `save` **invocation ID**, not by step name `filesystem.write`. Use references for secrets here too. Switching projects/environments resets the GUI's override field; keep any nonsecret sample separately if needed.

<!-- documentation-anchors:start -->
<a id="doc-7-validation-preview-and-actual-execution"></a>
<!-- documentation-anchors:end -->
## 7. Validation, preview and actual execution

Save the selected layer, check **Environment**, **PROJECT DIRECTORY** and **EXECUTION TARGET**, then choose an operation.

| Button | Scope | Performs actual package operations? | Where is the result? |
| --- | --- | --- | --- |
| **Preflight plot** | The whole selected plot. | No; static validation. | **Engine preflight** in the editor. |
| **WhatIf preview** | The whole plot. | No; step commands are skipped. | A new durable preview run in **Run history**. |
| **▶ Run plot** | The whole plot, in order. | Yes. | **Run history**. |
| **Preflight invocation** | Only the selected occurrence. | No. | **Engine preflight**. |
| **WhatIf invocation** | Only the selected occurrence. | No. | A preview run in **Run history**. |
| **Run invocation** | Only the selected occurrence. | Yes. | **Run history**. |

**Preflight and WhatIf do not actively test a connection to the target system.** A successful preflight does not prove that Docker is running, the target file is writable, the database is reachable or a server accepts a login. You must actually run a `http.*`, SQL, Docker or project-specific verification step to see its connection result.

Static validation checks the whole selected scope before the first package operation: step availability, settings, required parameters, static types, references and sequential dependencies. A producer output's actual field/type can be checked conclusively only after the producer has run, immediately before the consumer executes.

<!-- documentation-anchors:start -->
<a id="doc-engine-preflight-panel"></a>
<!-- documentation-anchors:end -->
### Engine preflight panel

Each planned invocation has its own expandable row. Inside the row:

| Label | Meaning |
| --- | --- |
| **Effective invocation settings** | Parameters determined by the engine for execution; secret values are masked. |
| **Setting layers** | Which parameter-source level supplied the value, for example schema default, `With` or override. |
| **Exact file / setting origins** | The specific source file, setting path and any reference origin. |
| **Complete plan response** | The complete structured engine response. |

<!-- documentation-anchors:start -->
<a id="doc-why-cannot-a-dependent-step-run-on-its-own"></a>
<!-- documentation-anchors:end -->
### Why cannot a dependent step run on its own?

In the `hello` example above, `compose` can run alone. `save` cannot, because it needs `steps.compose.Output.Text`. **Run invocation** does not automatically start earlier steps or load a previous run's output. Run the whole plot, or create a separate plot/occurrence whose inputs are all independently available.

<!-- documentation-anchors:start -->
<a id="doc-consequences-of-starting-a-run"></a>
<!-- documentation-anchors:end -->
### Consequences of starting a run

At startup, the service records copies of the selected configuration files and engine/packages, together with their versions and fingerprints. Referenced runner environment values are captured for the request; secret values do not enter the publicly readable configuration snapshot. Later configuration edits cannot change the inputs of an already started run.

An active run locks the project. A second conflicting run and configuration saves in the same project are rejected. `Succeeded` for a preview means the preview run succeeded; only runs with `whatIf: false` perform actual step operations.

<!-- documentation-anchors:start -->
<a id="doc-8-run-history--results-logs-and-stopping"></a>
<!-- documentation-anchors:end -->
## 8. Run history – results, logs and stopping

![Run history: run list, successful run, step results and structured output](images/management/05-run-history.png)

*Actual interface with demo 01; machine, account and directory details are anonymized.*

The left side of the page lists runs; the right side shows the selected run's details.

| Element | What does it show/do? |
| --- | --- |
| **Runs** counter | Number of run records available in the project. |
| **Refresh** | Refreshes the list, for example to show a run started in another window. |
| Run card | Plot name, invocation ID for a single-occurrence run, creation time, short run ID and state. Click to load its details. |
| **Preview · …** badge | A WhatIf run, not an active installation. |
| **Run ID** | The full durable run identifier. Record this for a bug report. |
| **Environment**, **Started**, **Completed** | The run's environment, start time and completion time. |
| Connection status line | Live tracking or an already loaded durable result; retries from the last event cursor after a network interruption. |
| Step-results table | **Invocation**, **State**, **Duration**: invocation and step name, state and duration. |
| **Structured result** | The engine's complete structured result: step outputs, result data and errors. Look here for file paths, hashes or states promised by the projects. |
| **Live event log** | Timestamp, continuous `#cursor`, event type, invocation/step, state and duration. The counter indicates loaded events. |
| **Run snapshot · immutable configuration and package fingerprints** | Fingerprints of configuration and packages captured for the run. This is not the project's current editing state or a general input-file editor. |
| **Request stop · terminate worker** | For an active run, requests termination of the worker and its process tree. |

<!-- documentation-anchors:start -->
<a id="doc-reading-states"></a>
<!-- documentation-anchors:end -->
### Reading states

| State | Interpretation |
| --- | --- |
| `Queued` | The request was accepted and the run scheduled. |
| `Running` | Execution is active. |
| `Succeeded` | This run completed successfully. For a preview, it means the preview succeeded. |
| `Failed` | An error occurred; inspect the error message, step and structured result. |
| `Cancelled` | Execution stopped because of the cancellation request. |
| `Interrupted` | An unfinished run was recovered as interrupted after the service stopped/restarted. It does not restart automatically. |
| Step-level `Skipped` | For example, a command was not invoked during WhatIf; this is not actual success of that operation. |

The system reads back durable events and refreshes regularly during active runs. After a lost connection it tries to continue from the last cursor. The address bar contains only project/environment/run IDs; reopen a saved URL and sign in if needed to inspect a previous run in the same available service. Reloading the page replays durable history rather than relying on the earlier browser session.

**Stopping is not rollback.** Files already created, containers already started and external database operations may remain, and an operation started in an external service may continue. After `Cancelled` or `Interrupted`, check the target state before restarting. SenseNet's `stop` plot is a normal application-lifecycle operation; **Request stop** cancels an in-progress Plot Manager run.

<!-- documentation-anchors:start -->
<a id="doc-9-guided-setup--guided-configuration"></a>
<!-- documentation-anchors:end -->
## 9. Guided setup – guided configuration

![Guided setup: target selection and settings fields in the five-stage wizard](images/management/04-guided-setup.png)

*Actual interface with demo 01; machine, account and directory details are anonymized.*

This is not a separate installation engine. The form declared in the project's `plot-project.json` writes ordinary configuration fields, then starts an ordinary plot. Without such a definition, **No guided form in this project** appears; the project is still usable from **Plot editor**.

The five stages at the top show your position: **Target → Settings → Preflight → Run → Result**. Use the buttons to move between them.

| Stage and controls | Action/effect |
| --- | --- |
| **Target / Choose the execution target** | Check the displayed machine and identity. Fields belonging to the project's `target` groups appear here. This is currently the service's own machine. |
| **Continue to settings →** | Moves to settings; no installation runs yet. |
| **Settings / Configure the sample** | The other form fields. `*` marks a required field; **Configuration: …** below the description shows which ordinary setting it writes. |
| **Back** | Returns to target settings. |
| **Save answers →** | Saves answers to the configuration layer selected by the wizard, preserving unrelated fields, then moves to preflight. This is an actual file save, but not yet installation. |
| **Preflight / Run static preflight** | Statically validates the wizard's plot. The detailed plan can be expanded here too. There is no external connection test. |
| **Back to settings** | Returns to the fields. |
| **Continue to run →** | Moves to the stage before execution after a successful static plan. |
| **Run / ▶ Run sample installation** | Actually starts the ordinary plot specified by the wizard's `plot` field. The label is generic: the project definition determines the operation, for example `install` in the SenseNet project. |
| **Result / Installation result** | Run ID, state, step results and structured result. |
| **Open run history** | Follow the same run on the detailed history page. |
| **Open ordinary plot editor** | Opens the wizard's plot in the ordinary editor, showing its complete, regular step sequence. |

Supported form fields are text, integer, bool, JSON array and JSON object. Bool has separate `false` and `true` values. Object/array fields require valid JSON, applied when you leave the field. The service also validates the declared type and required fields.

The guided form loads answers for its `settingPath` fields from the selected project and environment's saved, merged configuration. It uses a declared default only when the setting is absent; `false`, `0`, `[]` and explicit `null` are not missing values. Switching projects or environments reloads the corresponding configuration. The form still displays only declared bindings, not every configuration field.

If a bound value contains a `$ref` or `$env` reference, the form warns and **Save answers** is disabled. Edit the reference in **Configuration**: the wizard neither reads the secret nor replaces the reference with a default or a resolved literal. Otherwise, **Save answers** really does rewrite the form-bound fields in the selected layer. Other layers can still override them: inspect effective configuration/preflight. The service also validates field types; an existing value of the wrong type must be corrected before saving.

The form preserves a reference in the raw target layer even when the active environment would override it with a literal. Saving uses the loaded target layer's file version: reload configuration after an external change. If the declared target layer is not among the loaded layers, select its environment and reload; the wizard does not save using a freshly fetched version unrelated to the answers.

The generic sample binds `target` to `Sample.Target` and `message` to `Sample.Message`; the ordinary `install` plot joins the message and writes it. The SenseNet form requests a stack name, local HTTPS ports and SQL Developer license acceptance. The license field's `false` default does not mean acceptance: decide on actual development use from the project's [guide](../examples/sensenet-docker/README.md). The [demo scenarios](management-demo-projects.md) explain stack name/port handling after initial preparation and the other management plots. Saved configuration also works through the native CLI described there. For the generic project, run `pwsh -NoProfile -File ./src/Deployment/Scripts/Run.ps1 install` with `-DefaultConfigPath <project>/default.json`, `-ConfigPath <project>/project.json`, `-EnvironmentConfigPath <project>/environments/development.json` and `-WorkDirectory <project>`, all pointing to the same project copy.

<!-- documentation-anchors:start -->
<a id="doc-10-runner-secrets--managing-secrets"></a>
<!-- documentation-anchors:end -->
## 10. Runner secrets – managing secrets

![Runner secrets: form for saving a local secret without reading a saved value](images/management/06-runner-secrets.png)

*Actual interface with demo 01; machine, account and directory details are anonymized.*

The secret store belongs to the authenticated operator on the service machine. It can be opened without a project. A secret does not automatically become available in another service instance or for another operator.

| Field/button/panel | Behavior |
| --- | --- |
| **Service-local secret references / Values never returned** | Manages references to locally stored values. There is no GUI button to read a saved value. |
| **Secret name** | Starts with a letter and contains letters, digits or `_`, up to 64 characters. The system normalizes names to uppercase. For example, `EXAMPLE`. |
| **Secret value** | The actual secret to store, entered in a password field. |
| **Store on service host** | Saves the encrypted value in the service data store. An existing secret with the same name is updated. On success the entered value is cleared from the form. |
| **Name / Configuration reference** table | Only the name and pasteable reference are shown, for example `{"$env":"PLOTMANAGER_SECRET_EXAMPLE"}`. |
| **Delete** | Deletes the local secret after confirmation. This does not repair project configuration referencing it; the next resolution may fail. |

Usage:

1. Store the secret, for example as `EXAMPLE`.
2. Select **Runner environment / secret** as the source for an invocation's secret parameter.
3. Enter the returned variable name `PLOTMANAGER_SECRET_EXAMPLE`.
4. **Save layer**, then preflight. Only the `$env` reference enters the project.

Do not paste actual secrets into layer JSON, run overrides, uploaded sample files or Git. A secret is injected into the worker environment for the authenticated operator; list/read APIs do not return its value, and it is not written into run snapshots. The system masks known secret values in supported engine responses; arbitrary custom package logging/output is still not a general secret-protection boundary. Custom packages must not print secrets.

Distinguish three certificate concerns: the GUI–API HTTPS connection certificate; the TLS/client certificate of a service contacted by the runner; and the certificate of the target application installed by a plot. They are not controlled by a shared “SSL switch” in **Runner secrets**. Follow the specific step parameters and project documentation. Runner identity and host paths determine where credentials and certificate stores are used. Do not disable certificate verification as a default workaround.

<!-- documentation-anchors:start -->
<a id="doc-11-complete-workflows"></a>
<!-- documentation-anchors:end -->
## 11. Complete workflows

<!-- documentation-anchors:start -->
<a id="doc-a-understanding-and-trying-the-four-demos"></a>
<!-- documentation-anchors:end -->
### A. Understanding and trying the four demos

1. Select the project under **Workspace → Your projects**.
2. Open its entry in the [demo catalog](management-demo-projects.md), which lists plot names, ordering, parameters, side effects and verifiable results.
3. Check **Environment**, **PROJECT DIRECTORY** and **EXECUTION TARGET** at the top.
4. In **Configuration**, inspect the layers separately and the effective configuration.
5. Select a plot in **Plot editor**. Click each step row and read its inputs and references.
6. **Preflight plot**, then **WhatIf preview** if needed. The plot's operations have not happened yet.
7. With the effects described in the scenario understood, select **▶ Run plot**.
8. Check the result under **Run history → Structured result**. For file creation, inspect the file; for application startup, also examine the project's actual health/login checks.

<!-- documentation-anchors:start -->
<a id="doc-b-a-new-generic-project-with-a-guided-form"></a>
<!-- documentation-anchors:end -->
### B. A new generic project with a guided form

1. **Workspace → Create a project**: enter a name; the directory can be automatic.
2. Leave **Include the generic guided installation** checked.
3. **+ Create project** opens **Guided setup**.
4. Inspect the runner and enter your own sample filename and message.
5. **Save answers → Run static preflight → Continue to run → ▶ Run sample installation**.
6. In **Result**, then **Open run history**, inspect the created file path and step results.
7. **Open ordinary plot editor** shows that this is an ordinary text/filesystem plot rather than a hidden second installer.

Use an isolated sample project, not an existing application directory for a disposable test. When finished, remove only your own sample output file and isolated sample project.

<!-- documentation-anchors:start -->
<a id="doc-c-the-same-plot-with-different-settings-without-changing-defaults"></a>
<!-- documentation-anchors:end -->
### C. The same plot with different settings without changing defaults

1. Select the environment and its appropriate source layer.
2. Specify only the setting you want to change; leave the others absent to inherit.
3. **Save layer**; check the effective result and **Exact file provenance** on the right.
4. **Preflight plot**; inspect the particular invocation's settings and origins.
5. Run the plot. If a change is needed for only one request, a run override under the appropriate invocation ID can be used instead of an environment file.

<!-- documentation-anchors:start -->
<a id="doc-d-sensenet-docker-from-installation-to-daily-management"></a>
<!-- documentation-anchors:end -->
### D. SenseNet Docker: from installation to daily management

1. Select **04 – SenseNet Docker telepítés és menedzsment**.
2. In **Guided setup**, check the separate stack name, nonconflicting local ports and development SQL license condition.
3. Inspect `install`, then preflight and actual execution. Docker must work on the runner.
4. In `Run history` structured results, check installation, OData and actual login results; preflight success alone does not establish these.
5. Use `status`/`logs` for daily state/logs and the project's dedicated lifecycle plots for normal stopping/restarting.
6. Follow the project's backup scenario before changes; restore changes data and requires separate project-side confirmation.

The complete plot list and detailed backup/restore procedure are in the [SenseNet project guide](../examples/sensenet-docker/README.md), with step sequences in the [demo guide](management-demo-projects.md). Copy the whole project directory into the runner's allowed project root and **Open project** for your own environment; do not copy generated `.local` credentials. The installed browser/desktop demos have separate state.

<!-- documentation-anchors:start -->
<a id="doc-e-following-a-run-after-reopening-the-screen"></a>
<!-- documentation-anchors:end -->
### E. Following a run after reopening the screen

1. Leave the service/launcher terminal running for long operations. Closing the desktop window stops its own service, so keep that window open during the operation.
2. Record the run ID or run URL.
3. When reopening the browser, connect to the same available service and sign in if necessary.
4. Select the project, **Run history**, then the run. The durable record and events reload.
5. For `Interrupted`, examine target state. The application does not automatically retry a sequence that may already have partly executed.

<!-- documentation-anchors:start -->
<a id="doc-12-errors-and-frequently-asked-questions"></a>
<!-- documentation-anchors:end -->
## 12. Errors and frequently asked questions

| Symptom | Meaning / next step |
| --- | --- |
| Empty project list | This service instance/data store has no registered projects yet, or you signed in as another operator. Check runner details and the instance; open a complete portable project from the service's allowed root. |
| Cannot find `plot-project.json` | The supplied runner-side directory is not a GUI project root. Open the correct complete project directory. |
| `Create requires a new or empty project directory` | Use **Open project** for an existing project. |
| Forbidden/disallowed path | The directory is outside the allowed root, belongs to another operator or traverses a disallowed link. Configure the service project root correctly; the browser's own file picker cannot resolve this. |
| `The document must be a JSON object` / JSON parse error | The layer root must be an object with quoted keys. JSON does not accept comments or trailing commas. |
| `409`, `changed`, `etag_conflict` | The source file changed since it was read. Preserve your edit, **Reload**, compare, reapply and save. |
| `project_busy`, **Running** | A run or another conflicting operation holds a project lock. Follow it in **Run history** and wait for completion. |
| Run button is greyed out | There may be an unsaved layer, an active request/run or no selected plot. Inspect the shared message bar, save and select a plot. |
| Changed value does not appear in the effective view | Save the draft; check the active environment and winning source layer. A later file or a stronger invocation-parameter level can override it. |
| `Unapplied JSON` / `Invalid JSON` field error | The edited field text has not been applied. Correct it, leave the field and only then save. |
| Missing/invalid required parameter | The generated form shows its type and required status. Supply a value of the appropriate type in the right layer or through a reference. |
| Missing, circular or forward `$ref` | Correct the source path and order. The producer must precede its consumer. |
| Running a single step is disallowed | It requires an earlier invocation's output. Run the whole plot or make its inputs independent. |
| Missing `$env` variable / secret | The referenced variable must be available on the runner, in the current operator's secret store. Another desktop/browser instance does not share its secrets. |
| `Secret parameters must use … reference` | A literal was supplied for a secret parameter. Store it in **Runner secrets** and use the returned `$env` reference. |
| `Unsupported` / `missing on runner` | The step targets another platform or its tool is absent on the runner machine. Provide the runner prerequisites. |
| Preflight succeeds but actual execution fails | The static plan is not a connection or target-system test. Inspect the actual error, failing step, permissions and target state. |
| `Connection interrupted. Retrying …` | The interface lost its connection and is trying to reconnect from the last event cursor. This alone does not prove that execution stopped. |
| `Your session expired` / `401` | Sign in again, then open the same run record. |
| Upload `413` | The selected file exceeds the 10 MiB upload limit. |
| **No guided form in this project** | The project does not declare a wizard. The ordinary configuration and plot editors remain usable. |
| No “download”, “delete project” or “add machine” button | These GUI operations are not currently available. **Browse runner** and the **Remove …** invocation button perform different tasks. |

A bug report should include project/plot name, environment, failing invocation ID, run ID, exact message, and whether it was preflight, WhatIf or actual execution. Do not include tokens, passwords or private keys.

<!-- documentation-anchors:start -->
<a id="doc-13-current-limits-and-further-documentation"></a>
<!-- documentation-anchors:end -->
## 13. Current limits and further documentation

- Desktop and browser use the same React interface and service API. Platform and service-machine differences come from the runner and launch mode.
- Execution is sequential on one service's own machine. Multiple-machine agent selection, parallel graph editing and automatic rollback are not present in the current interface.
- **Run history** provides durable state/event tracking. It is not an arbitrary interactive terminal; a project's own `logs`-type plot can provide detailed application logs.
- The service runs with the displayed OS identity's permissions. An approved plot can perform actual system/Docker/file operations; GUI sign-in does not separately elevate OS permissions.
- Portable projects can be reviewed and shared in Git. Installed instances' state, secrets and generated data require separate handling; source readable in a PR does not depend on leaving a development machine running.

For frontend development, the build was verified with Node.js 20.20.0; the Vite toolchain requires at least 20.19 in the Node 20 line. From `src/Management/Web`, run `npm ci`, `npm run build` and `npm test`. The build writes `dist/`, which the service copies into published static assets. It requires no external font, image or CDN at runtime.

For integrated acceptance tests, run `pwsh -NoProfile -File ./scripts/management/Test-Management.ps1` from the repository root. It builds an isolated service and invokes browser tests against the real worker. Install Playwright Chromium once with `npx playwright install chromium` in the Web directory. Tests cover actual wizard output bytes, typed unknown-data roundtrip, reordered dependency rejection, full/single runs and event replay. The frontend unit suite covers typed layer edits, key-spelling preservation, stable IDs, reference forms, hidden declared secrets and cookie/CSRF transport. Build and test success are separate from desktop installation/native WebView smoke checks and actual Linux runner evidence; consult the validation and deployment reports for the platform matrix.

Related guides:

| Document | Purpose |
| --- | --- |
| [Demo projects and scenarios](management-demo-projects.md) | The four projects' purposes, plots, every step's role and verifiable results. |
| [SenseNet Docker project](../examples/sensenet-docker/README.md) | Actual stack installation, daily management, local data, backup and restore. |
| [Native configuration rules](settings.md) | Complete configuration format, precedence, references and CLI. |
| [Deployment, startup and packaging](management-deployment.md) | Desktop/browser/hosted startup, prerequisites, data stores and service settings. |
| [Management API](management-api.md) | Programmatic project, configuration and run management. |
| [Generic step packages](generic-packages.md), [platform packages](platform-packages.md), [operations packages](operations-packages.md) | Step schemas, parameters and examples by package. |
| [Validation and acceptance results](management-validation.md) | What was actually tested, on which platform and with what limitations. |

Control names in this guide come from [App.tsx](../src/Management/Web/src/App.tsx) and [components.tsx](../src/Management/Web/src/components.tsx). The client displays actual results from the native engine and [service](../src/Management/Server/Program.cs); the documentation therefore consistently distinguishes the static plan, preview and actual operations.
