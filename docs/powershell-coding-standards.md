# PowerShell conventions

These conventions apply to the native runtime and packages. Historical AutoExt scripts remain behind the explicit compatibility runner.

- Support PowerShell 5.1 and 7 without requiring external tooling for the engine.
- Use approved Verb-Noun function names; keep plot step IDs separate from function names.
- Export only the commands declared in the package manifest.
- Accept validated Settings plus a small Context object; avoid global variables.
- Return structured data on the success stream. Throw on failure.
- Check native executable exit codes immediately and convert failures to terminating errors.
- Use Write-Verbose/Write-Information for diagnostics. Never dump configurations or credentials.
- Guard mutating commands with SupportsShouldProcess and a real ShouldProcess call.
- Treat package imports as definition-only operations.
- Resolve package resources from Context.PackageRoot, and operator file paths from Context.WorkDirectory.
- Define parameter types and defaults in the manifest. Avoid false/zero truthiness checks for presence.
- Preserve input settings; merge into independent copies, with documented array/null behavior.
- Add tests for behavior, failure paths, package isolation and CLI results.
- Keep all PowerShell files parseable, including retained compatibility files.

[Authoring guide](custom-steps.md) · [Settings contract](settings.md) · [Test commands](../tests/README.md)

The repository currently uses a dependency-free runtime suite and parser checks. PSScriptAnalyzer is not bundled; the suite must not be described as a full analyzer pass.
