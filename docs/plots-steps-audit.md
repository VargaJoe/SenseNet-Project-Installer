# Plots and Steps Audit & Grouping Proposal

## Audit Date
2025-07-07

## Scope
All step functions in `src/Deployment/Scripts/AutoExt/Default-Modules.ps1`

## Step Functions (Raw List)
- Step-Stop
- Step-Start
- Step-GetLatest
- Step-GetLatestVsTemplates
- Step-RestorePckgs
- Step-PrBuild
- Step-CrArtifact
- Step-Publish
- Step-CleanPublishFolder
- Step-SnServices
- Step-SnWebPages
- Step-SnWorkspaces
- Step-SnWorkflow
- Step-SnNotification
- Step-RemoveDemo
- Step-AdminUsers
- Step-Install
- Step-CreateSite
- Step-SetHost
- Step-Index
- Step-Import
- Step-Export
- Step-CreatePackage
- Step-SetRepoUrl
- Step-BackupDb
- Step-AutoBackupDb
- Step-RestoreDb
- Step-DropDb
- Step-CreateEmptyDb
- Step-SetConfigs
- Step-GetSettings
- Step-ListSettings
- Step-SetConnection
- Step-DownloadDatabase
- Step-DownloadWebPack
- Step-StopRemote
- Step-StartRemote
- Step-WebAppOff
- Step-WebAppOn
- Step-WarmApp
- Step-TestWebfolder

## Proposed Groupings

### System Operations
- Step-Stop
- Step-Start
- Step-StopRemote
- Step-StartRemote
- Step-WebAppOff
- Step-WebAppOn
- Step-WarmApp
- Step-CreateSite
- Step-SetHost

### Database Operations
- Step-BackupDb
- Step-AutoBackupDb
- Step-RestoreDb
- Step-DropDb
- Step-CreateEmptyDb
- Step-SetConnection
- Step-SetConfigs
- Step-DownloadDatabase

### Build & Deployment
- Step-GetLatest
- Step-GetLatestVsTemplates
- Step-RestorePckgs
- Step-PrBuild
- Step-CrArtifact
- Step-Publish
- Step-CleanPublishFolder
- Step-CreatePackage
- Step-DownloadWebPack
- Step-TestWebfolder

### Sensenet/Project Operations
- Step-SnServices
- Step-SnWebPages
- Step-SnWorkspaces
- Step-SnWorkflow
- Step-SnNotification
- Step-RemoveDemo
- Step-AdminUsers
- Step-Install
- Step-Import
- Step-Export
- Step-Index
- Step-SetRepoUrl

### Settings & Utility
- Step-GetSettings
- Step-ListSettings

## Notes & Recommendations
- Consider moving each group to its own module/file for clarity.
- Add a manifest or registry for available steps and their group.
- Document required/optional parameters for each step.
- For Docker/Kubernetes: add new step modules as needed.

---

## Plot/Step Settings Injection Problem
Some steps require extra parameters/settings not standardized across all steps. This makes it difficult to inject settings in a uniform way.

### Problem Statement
- Steps expect different parameters, some via `$GlobalSettings`, some via direct parameters.
- Plots (workflows) may need to pass custom settings to steps.

### Solution Proposal (to be expanded in a separate document)
- Define a standard interface for step parameters (e.g., always accept a hashtable/object for extra settings).
- Document required/optional settings for each step.
- Use a settings injection utility to merge plot/step/global settings as needed.
- Consider a `Step-Invoke` wrapper that handles parameter mapping and validation.

See also: `docs/plot-step-settings-injection.md` (to be created)
