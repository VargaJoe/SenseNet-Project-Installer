# Runtime regression tests

Run from the repository root:

```powershell
pwsh -NoProfile -File ./tests/Run-Tests.ps1
powershell.exe -NoProfile -File ./tests/Run-Tests.ps1
```

No Pester installation or live infrastructure is required. The suite uses real files in a newly created temporary directory and mock IIS commands. It validates package selection, module isolation, collisions before imports, configuration layering/copies/references, preflight before side effects, failure stopping, WhatIf and CLI exit codes.

The suite deletes only its own randomly named test directory after validating its absolute path. Test failures exit 1. Both native package functions and the CLI are exercised; parser checks include retained legacy scripts. Live IIS/SQL/Docker and the historical GUI are not exercised.

The runner also includes Configuration.Tests.ps1 and GenericPackages.Tests.ps1. These cover ordered default/project/environment files, real CLI overrides, missing/invalid files, literal filesystem paths, scoped removal, ZIP roundtrips and invalid entries, JSON object merges, XML namespace/attribute updates, independent package installation, direct WhatIf and the shipped layered artifact example. Windows runs also create and remove a temporary junction to check link rejection. No live services or external downloads are used.

## Operational packages

`Operations.Tests.ps1` runs automatically in the main suite. Requires Git on PATH; HTTP tests compile the small `HttpFixture.cs` loopback fixture with Add-Type and use an ephemeral port. No internet endpoints, Docker daemon or database are needed.

Coverage includes ISO string preservation (JSON/config/CLI), blank CLI layer rejection, exact process argument boundaries, concurrent stdout/stderr draining, exit failures and timeouts, child-only environment, checksummed/atomic downloads, size limits, redirects, retries, slow response deadlines, TCP availability, real Git clone/fetch/checkout and dirty-worktree refusal. Build/NuGet and Docker command construction is tested against a process dependency fixture; their actual SDK/daemon behavior depends on the installed tools. Direct adapter WhatIf is also covered.

## Recursive settings references

`References.Tests.ps1` covers indirect environment values through actual layered CLI files, nested map/array expansion without input mutation, repeated sibling references, null/false/zero, a 64-reference chain and its depth limit, self/mutual/object cycles, missing values and type errors before earlier side effects. It also checks case-insensitive earlier-output aliases, forward/self-output rejection, missing runtime output properties and literal directive-shaped data returned by a step.
