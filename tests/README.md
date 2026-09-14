# Runtime regression tests

Run from the repository root:

```powershell
pwsh -NoProfile -File ./tests/Run-Tests.ps1
powershell.exe -NoProfile -File ./tests/Run-Tests.ps1
```

No Pester installation or live infrastructure is required. The suite uses real files in a newly created temporary directory and mock IIS commands. It validates package selection, module isolation, collisions before imports, configuration layering/copies/references, preflight before side effects, failure stopping, WhatIf and CLI exit codes.

The suite deletes only its own randomly named test directory after validating its absolute path. Test failures exit 1. Both native package functions and the CLI are exercised; parser checks include retained legacy scripts. Live IIS/SQL/Docker and the historical GUI are not exercised.
