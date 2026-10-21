# Shared management architecture

The management application wraps the existing native PowerShell engine. The
React/TypeScript client, ASP.NET Core 8 service and Tauri 2 desktop host share a
same-origin web interface. The engine remains responsible for object merging,
whole-array replacement, reference resolution, schema validation, preflight and
sequential execution. There is no independent JavaScript/C# configuration engine.

## Components and contracts

| Component | Location / responsibility |
| --- | --- |
| Native CLI and execution engine | `src/Deployment/Scripts/Run.ps1`, `Core/PlotManager.psm1` |
| Retained JSON bridge / WinForms | `Core/PlotIntegration.psm1`, `Invoke-Request.ps1`, `Show-PlotRunner.ps1` |
| Managed worker bridge | `Core/PlotManagement.psm1`, `Invoke-ManagedRequest.ps1` |
| Project and run service | `src/Management/Server/` |
| Shared browser and desktop UI | `src/Management/Web/` |
| Desktop service lifecycle | `src/Desktop/` |
| Reproducible build and launch | `scripts/management/` |

See [API protocol 1](management-api.md), [deployment](management-deployment.md),
[user guide](management-user-guide.md), and [migration map](migration-map.md).

The worker reads an explicit request file and writes a JSON response file. Step
events go to a separate append-only NDJSON file as they happen. Standard output
is not a transport for hosted logs: packages may print arbitrary data. The
retained JSON bridge remains compatible with its earlier callers.

## Configuration and editing

Portable project definitions refer to configuration files relative to the
project. Machine-local ownership, storage roots, worker paths, identity and
credentials belong to service configuration. Ordered files are default, project,
then selected environment; per-invocation run overrides have final precedence.
Engine setting precedence is unchanged: step schema defaults, configuration
defaults, step configuration, section, plot defaults, invocation, run overrides.

Only the selected raw layer is saved. Removing an override restores inheritance.
Missing, null, false, zero, empty arrays and unknown extension properties are
retained. Saves require the version read by the editor. Active-run locks and
optimistic versions reject conflicting edits. External editing of files still
requires observing the service's storage/access conventions.

Inspection returns the effective configuration, original layers and source file
for each leaf (whole arrays have a single source). Plans return converted
effective invocation parameters, their engine setting layer, source file/path,
and recursive settings/environment/output reference provenance. Secret values
are redacted; reference names remain visible.

## Execution and durability

Every run performs complete static plot validation before invoking its first
step. WhatIf uses the same plan and emits Skipped steps; it does not call step
functions or test their service connections. Active connection tests require
explicitly running a readiness step. An individual invocation uses the same
whole-plot preflight and is rejected if its resolved inputs need earlier outputs.
Prerequisites are never run implicitly.

The service owns worker processes and durable run state independently of client
connections. It snapshots ordered configuration and native package/core files
and records hashes before execution. Live events can be replayed by cursor;
polling one durable channel is sufficient for the single service-host runner.
Restart recovery marks unfinished runs Interrupted instead of repeating effects.

Cancel terminates the owned worker process tree. It does not compensate completed
steps, restore files or undo database/container operations. An external operation
already submitted can continue after the client process dies. Application
shutdown and service-host failure are separate from closing a browser tab.

## Execution boundary

Protocol 1 identifies one runner, its OS, runtime identity and target. Local
browser and desktop modes execute on the local service host; hosted mode executes
on the server under its configured identity. Windows-only packages remain
Windows-only. Installed executable prerequisites are shown by the manifest
catalog; their presence alone does not prove authentication or readiness.

An authenticated operator can execute installed packages, including process.run,
under the service identity. Project ownership checks are access controls, not an
OS sandbox between mutually untrusted script authors. Run the service without
unnecessary privileges, restrict its storage and use separate service instances
for different trust boundaries. There is no implicit elevation.

Remote execution on additional machines is future work: use a versioned runner
interface and an outbound authenticated agent connection. Hosted browsers never
reach arbitrary localhost services. This delivery does not claim a remote-agent
fleet, branching, parallel steps, retry or automatic rollback.

GUI/API TLS and operator authentication, a step's destination TLS/client identity,
and certificates installed for a deployed application are distinct settings on
their respective machines. See deployment documentation for their configuration.
