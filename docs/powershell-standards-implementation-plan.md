# Runtime refactor status

The native runtime refactor is implemented on feature/powershell-standardization.

Delivered:
- Explicit package registry, collision detection, dependency checks and isolated module dispatch.
- Validated per-invocation settings, deep-copy merge, references and source diagnostics.
- Repeated step invocations with distinct inputs and IDs.
- CLI planning, WhatIf, structured results and exit codes.
- Independently installable text, filesystem and IIS packages.
- A separate-process legacy entry point, preserving historical workflows.
- IIS polling repair, backup parser repair and legacy false/zero override repair.
- Automated runtime tests for PowerShell 5.1 and 7, plus a CI workflow.

Historical AutoExt steps retain their original implementations except for the explicitly documented fixes. They are not implicitly imported into the new registry. The old GUI remains separate. These boundaries are described in [runtime architecture](plot-manager-runtime.md).

The next cross-repository comparison must begin only after this refactor is verified. Company-specific configurations and Git history must not be copied into this repository.
