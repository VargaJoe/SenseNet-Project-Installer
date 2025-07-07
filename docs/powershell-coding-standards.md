# PowerShell Coding Standards (Draft)

## 1. Function Naming
- Use `Verb-Noun` format (e.g., `Start-Service`, `Get-Config`).
- Use approved PowerShell verbs where possible.

## 2. CmdletBinding and Advanced Functions
- All functions must use `[CmdletBinding()]`.
- Use advanced parameter blocks with `[Parameter()]` attributes.

## 3. Parameter Definitions
- Clearly define all parameters with type, mandatory/optional, and validation attributes.
- Use `[ValidateNotNullOrEmpty()]`, `[ValidateSet()]`, etc., as appropriate.

## 4. Error Handling
- Use `try/catch` blocks for error handling.
- Use `Write-Error` for user-facing errors, `throw` for terminating errors.
- Always set `$ErrorActionPreference = 'Stop'` at the top of scripts.

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
- Avoid deprecated cmdlets and syntax (e.g., `Write-Host`, legacy array syntax).

## 9. Plot/Step Grouping
- Group steps by logical domain (system, Docker, Kubernetes, etc.).
- Use folders or naming prefixes for grouping.

## 10. Settings Injection
- Design a standard mechanism for injecting settings into steps.
- Use parameter objects or hashtables for extensibility.
- Document required/optional settings for each step.

---

This document is a draft and will be updated as Story 03 progresses.
