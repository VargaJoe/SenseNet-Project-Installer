# Build server integration

The native CLI is non-interactive, returns JSON run results, and exits 1 on preflight or step failure. Select packages with -AutoPath. Supply a project configuration with -ConfigPath, optionally inheriting -DefaultConfigPath and overriding it with -EnvironmentConfigPath. Use -Params for explicit invocation overrides. Pass -WorkDirectory explicitly on a build agent.

Run ./tests/Run-Tests.ps1 for dependency-free runtime verification. The repository workflow runs the suite on Windows PowerShell 5.1 and PowerShell 7.

Historical TFS/global-settings scripts are documented in [legacy/build-server-basic-steps.md](legacy/build-server-basic-steps.md) and use -Legacy.
