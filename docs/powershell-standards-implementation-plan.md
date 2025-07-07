# PowerShell Standards Implementation Plan

## 1. Function Naming
- All step functions must use the `Verb-Noun` format, with a unique, descriptive noun.
- Step functions should be prefixed by their logical group (e.g., `System-Stop`, `Db-Backup`, `Deploy-GetLatest`).
- No duplicate step names across files; use group or module prefix to ensure uniqueness.

## 2. CmdletBinding and Advanced Functions
- All functions must use `[CmdletBinding()]`.
- Use advanced parameter blocks with `[Parameter()]` attributes.

## 3. Parameter Definitions
- All step functions must accept a `[hashtable]$StepSettings` parameter for extensibility.
- Clearly define all required/optional parameters and document them.

## 4. Error Handling
- Use `try/catch` blocks for error handling.
- Use `Write-Error` for user-facing errors, `throw` for terminating errors.
- Set `$ErrorActionPreference = 'Stop'` at the top of scripts.

## 5. Logging
- Use `Write-Verbose`, `Write-Information`, and `Write-Error` for logging.
- Implement a logging function with severity levels (Info, Warning, Error, Debug).

## 6. Help Documentation
- All functions must include comment-based help (`<# .SYNOPSIS ... #>`).
- Provide usage examples for each function.

## 7. Variable Naming
- Use `camelCase` for local variables, `PascalCase` for global variables.
- Prefix private variables with `_` if needed.

## 8. Deprecated Syntax
- Mark deprecated steps/functions with a clear comment and add to a deprecation list.
- Remove deprecated code in a later cleanup phase.

## 9. Grouping and Refactoring
- Group step functions by logical domain (System, Db, Deploy, Project, etc.).
- Move each group to its own module/file for clarity.
- Add a manifest or registry for available steps and their group.

## 10. Next Steps
- Refactor a sample group (e.g., System Operations) to the new standard.
- Document deprecated/obsolete steps for review.
- Iterate through all groups, refactoring and documenting as you go.

---

This plan will be updated as implementation progresses. See also: `docs/powershell-coding-standards.md` and `docs/plots-steps-audit.md`.
