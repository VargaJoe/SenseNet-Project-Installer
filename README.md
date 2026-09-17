# Plot Manager

Plot Manager composes scriptable tasks from small, parameterized steps. A plot describes the step invocations and their inputs. Operators install only the capability packages they need by copying their directories into `src/Deployment/Scripts/Auto/`.

The repository's historical name, **SenseNet-Project-Installer**, describes its first use case. SenseNet installation is one of the retained legacy workflows; it is not a restriction on the engine.

## Run a plot

Requires PowerShell 5.1 or PowerShell 7. The engine, text package and filesystem package do not require administrator privileges or external modules. IIS steps require Windows and WebAdministration when executed.

From the repository root:

```powershell
# Discover the installed steps.
./src/Deployment/Scripts/Run.ps1 -Help steps

# Resolve and validate the example without executing steps.
./src/Deployment/Scripts/Run.ps1 compose-files -ConfigPath ./src/Deployment/Scripts/Examples/compose-files.json -Explain

# WorkDirectory must exist. This example creates greeting.txt and farewell.txt.
New-Item -ItemType Directory ./plot-output
./src/Deployment/Scripts/Run.ps1 compose-files -ConfigPath ./src/Deployment/Scripts/Examples/compose-files.json -WorkDirectory ./plot-output

# WhatIf skips every step, including steps that consume earlier results.
./src/Deployment/Scripts/Run.ps1 compose-files -ConfigPath ./src/Deployment/Scripts/Examples/compose-files.json -WhatIf
```

The example calls `text.join` twice with different inputs, then passes their outputs into two `filesystem.write` invocations. Existing files are preserved unless an explicit `Overwrite: true` parameter is supplied.

CLI success is exit code 0; validation or execution failure is exit code 1. Executed runs return JSON containing the run ID, plot status and each executed step's output, error and duration. Execution stops at the first failure.

## Packages and configuration

- `Auto/<package>/package.psd1`: package identity, version, module, dependencies and exported step schemas.
- `Auto/<package>/*.psm1`: isolated PowerShell functions. Package import must only define functions and initialize local state.
- `Core/PlotManager.psm1`: discovery, collision detection, parameter resolution and execution.
- `Examples/compose-files.json`: portable example with independently configured invocations.
- `Run-Legacy.ps1` and `AutoExt/`: retained historical execution path.

Installed native packages: **text**, **filesystem**, **archive**, **json**, **xml**, **process**, **http**, **git**, **build**, **docker**, **iis**. See the [general-purpose package catalog and complete local example](docs/generic-packages.md). Copy a whole package folder, including its module and any resources, to another Auto directory; select that directory with `-AutoPath`. Missing dependencies and duplicate names are rejected before package imports. Canonical step IDs are qualified by package, such as `filesystem.copy`. Repeating a step in a plot is supported through separate invocation IDs.

See [configuration and execution](docs/settings.md), [package authoring](docs/custom-steps.md), [architecture and compatibility](docs/plot-manager-runtime.md) and [testing](tests/README.md).

## Layered configuration

Default settings are inherited by the project, then overridden by the selected environment. Explicit run parameters override the resolved invocation settings.

```powershell
./src/Deployment/Scripts/Run.ps1 my-plot -DefaultConfigPath ./default.json -ConfigPath ./project.json -EnvironmentConfigPath ./environment.json
```

Layers are optional. Nested objects merge; arrays replace; explicit null, false and zero remain values. Existing single-file commands work unchanged. The [layered artifact example](docs/generic-packages.md#complete-local-example) exercises these layers with real JSON/XML, directory, ZIP and hash operations.

## Historical workflows

Existing section/global-variable scripts remain available in a separate PowerShell process:

```powershell
./src/Deployment/Scripts/Run.ps1 -Legacy -Help steps
./src/Deployment/Scripts/Run.ps1 -Legacy -Plot fullinstall -Settings local
```

Review the selected legacy configuration before executing it: these workflows can modify IIS, databases and deployments. The compatibility runner retains their platform/tool requirements and administrator requirement for execution. Historical steps are not native packages and cannot be mixed into a native plot. Legacy preview is rejected because those scripts do not consistently implement WhatIf.

The Angular GUI and experimental HTTP listener are historical clients; this refactor does not modernize or expose them. Native CLI/API functionality does not depend on them. Original historical guides are under [docs/legacy](docs/legacy/).

## Development

```powershell
pwsh -NoProfile -File ./tests/Run-Tests.ps1
powershell.exe -NoProfile -File ./tests/Run-Tests.ps1
```

The suite uses PowerShell/.NET and local Git to check configuration, package isolation, CLI exit codes, temporary files, child processes, loopback HTTP/TCP, real local Git operations and mocked IIS/CLI adapters. It does not operate deployed infrastructure. [MIT license](LICENSE).
