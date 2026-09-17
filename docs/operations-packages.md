# Generic operational packages

These packages expose general operations without application-specific charts, services, repository URLs or credentials. Install their complete folders under any Auto directory. **Git, Build and Docker also require Process**; folder names may differ from manifest names. Http is independent. The existing native runtime, sequential failure behavior and layered configuration apply.

## Process: `process.run`

| Parameter | Meaning/default |
| --- | --- |
| FilePath | Required executable path or application name on PATH |
| Arguments | Array of individual strings, default `[]`; never a shell command string |
| WorkingDirectory | Existing directory, defaults to WorkDirectory |
| Environment | Child-only overrides; a null value removes an inherited variable |
| TimeoutSeconds | Total process/output deadline, 60; range 1–86400 |
| SuccessExitCodes | Accepted integer exit codes, `[0]` |

Paths with separators resolve against WorkDirectory. `.ps1`, `.cmd` and `.bat` require an explicit interpreter executable. Shell execution is disabled; metacharacters are ordinary argument text. stdin is closed. Output contains FilePath, ExitCode, StandardOutput, StandardError and DurationMilliseconds. Both streams are drained concurrently and buffered in memory: this step is for finite commands, not an indefinite log collector. Output is returned verbatim and may contain secrets printed by the executable; the CLI serializes it.

Timeout attempts to terminate the owned process tree (modern .NET) or uses Windows taskkill for PowerShell 5.1. A process that detaches or exits before its descendants cannot be guaranteed to leave no descendants. Waiting for inherited output pipes is still bounded. A timeout is a failure, not a rollback of filesystem, daemon or external effects. Errors omit arguments/environment and child output; inspect successful output or run the tool separately for detailed diagnostics. Every command can be previewed with plot `-Explain` / `-WhatIf`.

## HTTP and TCP

| Step | Required inputs | Optional inputs | Output |
| --- | --- | --- | --- |
| `http.download` | Url, Destination | Headers `{}`, Sha256 `""`, Overwrite `false`, MaxBytes `1073741824`, TimeoutSeconds `300` | Path, Bytes, Sha256, StatusCode |
| `http.wait` | Url | Headers `{}`, StatusCodes `[200]`, TimeoutSeconds `60`, RequestTimeoutSeconds `5`, IntervalMilliseconds `500` | StatusCode, Attempts, DurationMilliseconds |
| `http.wait-tcp` | HostName, Port | TimeoutSeconds `60`, IntervalMilliseconds `500` | HostName, Port, Attempts, DurationMilliseconds |

HTTP accepts only HTTP(S) URLs without embedded credentials. Certificate validation uses the system defaults; redirects are disabled and cookies are not retained. Supply request headers through settings/environment references. HTTP readiness checks the response status, not application/database health; TCP readiness only proves a connection could be established.

Download writes a random temporary file beside the destination, bounds declared and streamed bytes, verifies optional SHA256, then publishes the file. The destination's parent must exist. Failure leaves an existing destination intact and removes the temporary file. A successful download always returns its computed SHA256. Overwrite must be explicit. The deadline includes header/body transfer; local filesystem/hash work is synchronous and checked before publication. Readiness retries transient status and transport failures within one overall deadline. Error results omit URLs, headers and response bodies.

## Git

All Git steps require Git on PATH. TimeoutSeconds defaults to 300 and Environment to `{}`. Configure noninteractive authentication outside argument strings (for example an existing credential helper and child environment).

| Step | Inputs | Behavior |
| --- | --- | --- |
| `git.clone` | Repository, Destination, optional Branch `""` | Destination must not already exist; no automatic deletion on failure |
| `git.fetch` | Directory, optional Remote `"origin"` | Fetches one remote; does not merge, prune or reset |
| `git.checkout` | Directory, Ref | Requires a clean worktree including untracked files; checks out a detached HEAD |

Directory/Destination resolve against WorkDirectory. Remote/revision operands cannot begin with `-`. Outputs use the process result contract. A failed clone may leave a partial destination for inspection; choose a new directory or explicitly clean it after review. Git hooks and executable repository content remain governed by the installed Git/tool configuration.

## Build and NuGet

Requires `dotnet` on PATH; no hardcoded SDK/Visual Studio paths or package lists. Both steps accept Directory (`.`), Arguments (`[]`), TimeoutSeconds (`300`) and Environment (`{}`). All paths resolve against WorkDirectory. Arguments are the tool's native argument vector; no string splitting occurs.

- `build.dotnet`: Project (existing project/solution path), Command (`build`; allowed: restore, build, test, publish, pack). Runs `dotnet <Command> <absolute Project> <Arguments...>`.
- `build.nuget`: Command (push, delete, list, locals, add, remove, update, enable, disable). Runs `dotnet nuget <Command> <Arguments...>`. Use `build.dotnet` with restore/pack for package restore/creation. Feed and API-key settings are operator supplied.

Outputs use the process result contract. Restore/build/test/publish may run project-defined code and contact configured feeds. Use native tool flags such as `--no-restore` or an explicit local source when that is intended.

## Docker

`docker.cli` requires Command and accepts Arguments (`[]`), Directory (`.`), TimeoutSeconds (`300`), Environment (`{}`). Requires Docker CLI on PATH and the selected daemon/context. Allowed commands:

- Image: build, pull, tag, push, inspect.
- Container: run, start, stop, rm.
- Network: network-create, network-inspect, network-connect, network-disconnect, network-rm (mapped to `docker network <verb>`).

Arguments are passed as individual strings. Resource names, tags, paths, ports and flags are supplied by the plot. Outputs use the process result contract. No implicit cleanup or daemon-wide prune occurs. Timeout stops the CLI process; an operation already accepted by the Docker daemon can continue. Compose is not included in this batch.

## Configuration example and commands

See `src/Deployment/Scripts/Examples/operations.json` for separate source/build, container build and readiness plots. Adapt its Values section through project/environment files. All examples use placeholder paths and endpoints.

```powershell
# Inspect without requiring executable tools or contacting endpoints.
./src/Deployment/Scripts/Run.ps1 source-build -ConfigPath ./src/Deployment/Scripts/Examples/operations.json -Explain

# After supplying your project paths/settings and installing the required tools:
./src/Deployment/Scripts/Run.ps1 source-build -DefaultConfigPath ./src/Deployment/Scripts/Examples/operations.json -ConfigPath ./my-project.json -WorkDirectory ./work
```

Run the tests with `pwsh -NoProfile -File ./tests/Run-Tests.ps1` and `powershell.exe -NoProfile -File ./tests/Run-Tests.ps1`. Tests use local processes, a loopback HTTP/TCP fixture, a real isolated Git repository and mock build/Docker dependency commands. They do not validate a production deployment or execute Docker daemon operations.
