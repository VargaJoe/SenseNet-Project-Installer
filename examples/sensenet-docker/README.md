<!-- documentation-anchors:start -->
<a id="doc-sensenet-docker-project-for-plot-manager"></a>
<!-- documentation-anchors:end -->
# SenseNet Docker project for Plot Manager

<!-- documentation-navigation -->
[English](README.md) | [Magyar](README-hu.md) · [Documentation](../../docs/README.md) · [Project](../../README.md)
<!-- /documentation-navigation -->

A real local development SenseNet installation: SQL Server Developer, SenseNet repository and IdentityServer. The project uses the existing `compose`, `process`, `json` and `filesystem` packages. The Plot Manager engine and configuration format are unchanged.

<!-- documentation-anchors:start -->
<a id="doc-starting-from-the-application"></a>
<!-- documentation-anchors:end -->
## Starting from the application

1. Copy this entire directory into the running Plot Manager's project root and open it with **Open project**. Do not copy the `.local` directory into another project.
2. In **Guided setup**, enter a unique `pm-sensenet-…` Compose name and two free ports. Settings are saved in the usual `project.json` layer.
3. After accepting the Microsoft SQL Server Developer terms, save, check preflight and start the `install` plot. The Developer edition is for development/testing. [Microsoft SQL container guide](https://learn.microsoft.com/en-us/sql/linux/quickstart-install-connect-docker).
4. The result shows the repository and sign-in service URLs, the OData check and the actual admin login result. Initial repository initialization can take several minutes.

Prerequisites: Docker Engine with Linux containers, Docker Compose v2 and PowerShell 7.2 or later on the runner machine's PATH; available memory and disk space for SQL Server. Steps run on the Plot Manager service machine under its user identity. With hosted Plot Manager, localhost URLs refer to the server.

<!-- documentation-anchors:start -->
<a id="doc-operations"></a>
<!-- documentation-anchors:end -->
## Operations

| Plot | Result |
|---|---|
| `prepare` | Validate and create project-local passwords and an HTTPS certificate once. |
| `install` | Prepare, validate Compose, start services, check OData and actual PKCE admin login. |
| `start`, `restart` | Start or restart and perform authenticated verification. |
| `status`, `logs` | Show project service status or the last 80 log lines per service. |
| `verify` | Active connection test, OpenID discovery and login, authenticated Admin content read. |
| `demo-content` | Create/read the project's sample folder through the OData API. The ID survives reruns. |
| `verify-demo-content` | Check that the previously created sample folder exists; fail if absent. |
| `stop` | Stop containers while preserving data. |
| `backup` | After stopping this stack, cold-back up the complete SQL and App_Data volumes with a hash manifest; restart services that were previously running. |
| `restore` | Restore a selected backup belonging to this stack with explicit name confirmation, then start and verify. Replaces this stack's current data. |
| `remove-containers-keep-data` | Remove this stack's containers and network; retain named volumes, secrets and backups. `install` starts it again. |

Preview/WhatIf is a static check; it does not attempt login, inspect Docker port allocation or create a backup. Before running individual steps, account for files created by preparation. Use full execution for a complete plot.

<!-- documentation-anchors:start -->
<a id="doc-data-https-and-secrets"></a>
<!-- documentation-anchors:end -->
## Data, HTTPS and secrets

The copy in the application's own AppData project directory is the working copy; the installation directory and source checkout are not automatic configuration sources. The configuration order remains `default.json` → `project.json` → `environments/development.json`.

Docker volumes: `<stack>_db-data` (`/var/opt/mssql`) and `<stack>_app-data` (`/app/App_Data`). No SQL port is published. The repository and IdentityServer are accessible only on the machine's loopback interface.

The generated `.local` directory is readable only by the current operating-system user: it contains the local runtime-env, PFX private key, preparation state and backups. It is deliberately excluded from Git. **A backup is also sensitive data**, because it contains a database and the local secrets needed for restoration. Source JSON files contain only public parameters. A user with Docker access can read container configuration.

The script does not install the localhost certificate into the OS trust store. Its HTTP client accepts only the certificate generated for this project, with hostname validation; it rejects other invalid certificates. A browser warning for the project's development certificate is expected. External/production HTTPS requires a separate real certificate and deployment configuration.

The official fresh repository's demo account is **admin / admin**. Built-in automatic verification uses this local demo account. For a changed password, save a Runner secret named `SENSENET_ADMIN_PASSWORD`, then change `Authentication.AdminPassword` to the reference `{"$env":"PLOTMANAGER_SECRET_SENSENET_ADMIN_PASSWORD"}`. The native process step receives the password as a separate environment variable captured for the run snapshot; this setting is not included in generated runtime JSON. The CLI can use an environment variable of the same name.

This sample is for development use; publishing it to the internet and switching to production authentication are separate tasks. The name and ports are fixed after initial preparation: a new instance requires a new project copy, another name and different ports. Images are pinned by SHA-256 digest, so a moving `preview` or `latest` tag cannot silently update them on a rerun.

Verification uses a separate `plotmanager-adminui` PKCE client whose callback points only to this repository's localhost address. The verification script reads the code from the callback redirect without navigating to that address. Connecting an external or separately installed Admin UI requires additional configuration for that interface's exact origin and callback; this project does not enable such external access.

<!-- documentation-anchors:start -->
<a id="doc-backup-and-restore"></a>
<!-- documentation-anchors:end -->
## Backup and restore

Run the `backup` plot. The output and `.local/backups` directory identify the completed backup. Set the following in the `project.json` layer:

```json
{
  "Restore": {
    "BackupPath": ".local/backups/A-MENTES-KONYVTARA",
    "ConfirmStackName": "pm-sensenet-a-sajat-stack-neve"
  }
}
```

Then run `restore`. The name must exactly match the prepared stack's name. Before restoring, the operation verifies the backup hashes and that the backup belongs to this stack. After restoration, delete these two overrides or set them to empty. This first version supports local backups for the same stack and the same pinned images; it does not upgrade a database to a new version.

<!-- documentation-anchors:start -->
<a id="doc-cli"></a>
<!-- documentation-anchors:end -->
## CLI

From the root of your Plot Manager checkout, after filling in `project.json`:

```powershell
pwsh -NoProfile -File ./src/Deployment/Scripts/Run.ps1 install `
  -DefaultConfigPath ./examples/sensenet-docker/default.json `
  -ConfigPath ./examples/sensenet-docker/project.json `
  -EnvironmentConfigPath ./examples/sensenet-docker/environments/development.json `
  -WorkDirectory ./examples/sensenet-docker
```

Replace `install` with any plot name above. Use `-WhatIf` for preview. When running a project copied into the application through the CLI, all three file paths and WorkDirectory must point to that copy.

<!-- documentation-anchors:start -->
<a id="doc-public-foundation-and-boundaries"></a>
<!-- documentation-anchors:end -->
## Public foundation and boundaries

This fresh standalone project builds on the public contracts of the official [SenseNet persistent Compose scenario](https://github.com/SenseNet/sensenet/blob/f889cfce16e724ad095d4ca976a2e0d7fa362c26/deployment/docker-compose.with-volume.yml), [service definitions](https://github.com/SenseNet/sensenet/blob/f889cfce16e724ad095d4ca976a2e0d7fa362c26/deployment/compose.services.yml) and [IdentityServer PKCE test](https://github.com/SenseNet/sensenet/blob/f889cfce16e724ad095d4ca976a2e0d7fa362c26/deployment/tests/Test-IdentityServerLogin.ps1). No code or configuration was transferred from a company installer.

There is no automatic image update, production publishing, multi-machine deployment or volume-deleting reset plot. Cancelling a Plot Manager run does not mean Docker rollback. The project's scripts and Compose files are external input files: do not edit them during a run; the run snapshot of the engine and JSON layers does not freeze these files.
