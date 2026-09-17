# Plot configuration

Configuration is a JSON object. The CLI reads up to three files in this order:

1. `-DefaultConfigPath`: shared baseline.
2. `-ConfigPath`: project configuration. Alternatively, `-Settings name` selects `Settings/project-name.json`.
3. `-EnvironmentConfigPath`: environment-specific overrides.

Each layer is optional; explicitly supplied files must exist and contain a JSON object. Later files override earlier files recursively. Omitted properties are inherited; arrays replace, including empty arrays, and null/false/zero are preserved. The same rules apply to settings and plot definitions. The loader finishes before any step executes.

```powershell
./src/Deployment/Scripts/Run.ps1 build-report -DefaultConfigPath ./default.json -ConfigPath ./project.json -EnvironmentConfigPath ./production.json
```

`-ConfigPath` and `-Settings` are mutually exclusive ways to select the project layer. Both can be combined with default and environment layers. Existing single-file invocations continue to work. File paths are resolved against the invoking working directory; `-WorkDirectory` controls step file operations, not configuration-file discovery. Native mode does not implicitly load legacy `Settings/project-default.json`; select the intended native baseline explicitly.

Through the module API, any number of files can be supplied in precedence order:

```powershell
$config = Read-PlotConfiguration -Path @('./default.json', './project.json', './production.json')
```

Use `Merge-PlotSettings -Layers` for configuration objects already in memory. `-Explain` lists the loaded ConfigurationFiles in order together with invocation parameter-source labels; `-Verbose` logs the loaded paths without their values. Parameter-source labels describe invocation layers, not individual source JSON files.

After the file layers are merged, the invocation precedence below applies. Explicit `-Params` overrides still win. An environment file overrides matching JSON property paths; a global default does not override a more specific invocation `With` value. See the complete [layered artifact example](generic-packages.md#complete-local-example).

```json
{
  "Message": { "Name": "operator" },
  "Plots": {
    "hello": {
      "Steps": [
        {
          "Id": "compose",
          "Step": "text.join",
          "With": {
            "Items": ["Hello", { "$ref": "settings.Message.Name" }],
            "Separator": ", "
          }
        },
        {
          "Id": "save",
          "Step": "filesystem.write",
          "With": {
            "Path": "hello.txt",
            "Content": { "$ref": "steps.compose.Output.Text" }
          }
        }
      ]
    }
  }
}
```

A step ID identifies a definition; an invocation ID identifies one occurrence in a plot. The same step may occur any number of times. Invocation IDs must start with a letter and contain letters, numbers, underscores or hyphens. Omitted IDs become `step1`, `step2`, etc.; explicit IDs are preferable for references.

## Precedence

Later layers override earlier layers:

1. Defaults in the step's parameter schema.
2. Configuration `Defaults`.
3. Configuration `StepDefaults["package.step"]`.
4. The invocation's selected top-level `Section`, if any.
5. The plot's `Defaults`.
6. The invocation's `With`.
7. Explicit run overrides, keyed by invocation ID.

Defaults apply only where appropriate: a common Defaults map must contain parameters accepted by every affected step. Use StepDefaults or explicit With mappings for heterogeneous plots. Unknown parameter names are rejected.

```powershell
# Override only one invocation. JSON values retain their types.
./src/Deployment/Scripts/Run.ps1 hello -ConfigPath ./hello.json -Params '{"save":{"Path":"other.txt","Overwrite":true}}'
```

Objects merge recursively. Arrays replace as a whole, including an empty array. Explicit null replaces; the schema must allow null. False and zero are values, not missing settings. Every invocation receives a deep copy, so changing it cannot change the base configuration or another invocation's inputs.

## References

- `{"$ref":"settings.Message.Name"}` selects a configuration value.
- `{"$ref":"steps.compose.Output.Text"}` selects an earlier invocation's output.
- `{"$env":"MY_SETTING"}` explicitly reads an environment variable.

Reference objects must contain exactly one directive. They are value references, not PowerShell expressions or string interpolation. Property paths use dots; keys containing dots are not addressable through this syntax. A reference to an output is allowed only for an earlier invocation. The actual output property and final type are checked immediately before the consuming step runs.

Environment references are resolved during planning. There is no hidden environment overlay in native mode. Missing variables fail validation; string values are converted only for declared int/bool parameters. Boolean strings must be true or false, so "false" never becomes truthy through a string cast.

## Schema validation

Types: `string`, `int`, `bool`, `array`, `object` (a map). Parameters may declare `Required`, `Default`, `AllowNull`, `ValidateSet`, numeric `Minimum`/`Maximum`, and `Secret`.

Missing required settings, unknown parameters, invalid scalar types and invalid static references fail preflight before any step runs. Deferred output references are validated after their producing step, because those values do not exist at preflight.

## Inspection

`-Explain` returns invocation IDs, resolved step IDs and parameter-source labels without executing package commands. `-Verbose` logs the selected step and source labels; it does not print settings values. `-WhatIf` returns skipped results and does not invoke any package command.

Declared secret scalar values are redacted if they occur in a step exception message. This is not a general data-loss-prevention boundary: package authors must never emit secrets in their own outputs, logs or exception records.

## Compatibility forms

A plot may use an array directly. String entries can use `package.step:Section` to select a settings section:

```json
{
  "Chosen": { "Items": ["one", "two"], "Separator": "-" },
  "Plots": { "example": ["text.join:Chosen"] }
}
```

These strings refer to native step IDs or registered aliases. Historical `Step-*` functions require `-Legacy`; their configurations use the historical loader. See [legacy configuration](legacy/settings.md).

JSON strings remain strings, including ISO timestamps with offsets. This applies to configuration layers, `-Params`, and the JSON package. An explicitly supplied empty or whitespace configuration path is an error; omit an optional argument to skip that layer.
