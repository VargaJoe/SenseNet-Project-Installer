<!-- documentation-anchors:start -->
<a id="doc-plots-and-steps-audit--grouping-proposal"></a>
<!-- documentation-anchors:end -->
# Plots and Steps Audit & Grouping Proposal

<!-- documentation-navigation -->
[English](plots-steps-audit.md) | [Magyar](plots-steps-audit-hu.md) · [Documentation](README.md) · [Project](../README.md)
<!-- /documentation-navigation -->

<!-- documentation-anchors:start -->
<a id="doc-audit-date"></a>
<!-- documentation-anchors:end -->
## Audit Date
2025-07-07

<!-- documentation-anchors:start -->
<a id="doc-scope"></a>
<!-- documentation-anchors:end -->
## Scope
All step functions in `src/Deployment/Scripts/AutoExt/Default-Modules.ps1`

<!-- documentation-anchors:start -->
<a id="doc-step-functions-raw-list"></a>
<!-- documentation-anchors:end -->
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

<!-- documentation-anchors:start -->
<a id="doc-proposed-groupings"></a>
<!-- documentation-anchors:end -->
## Proposed Groupings

<!-- documentation-anchors:start -->
<a id="doc-system-operations"></a>
<!-- documentation-anchors:end -->
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

<!-- documentation-anchors:start -->
<a id="doc-database-operations"></a>
<!-- documentation-anchors:end -->
### Database Operations
- Step-BackupDb
- Step-AutoBackupDb
- Step-RestoreDb
- Step-DropDb
- Step-CreateEmptyDb
- Step-SetConnection
- Step-SetConfigs
- Step-DownloadDatabase

<!-- documentation-anchors:start -->
<a id="doc-build--deployment"></a>
<!-- documentation-anchors:end -->
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

<!-- documentation-anchors:start -->
<a id="doc-sensenetproject-operations"></a>
<!-- documentation-anchors:end -->
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

<!-- documentation-anchors:start -->
<a id="doc-settings--utility"></a>
<!-- documentation-anchors:end -->
### Settings & Utility
- Step-GetSettings
- Step-ListSettings

<!-- documentation-anchors:start -->
<a id="doc-notes--recommendations"></a>
<!-- documentation-anchors:end -->
## Notes & Recommendations
- Consider moving each group to its own module/file for clarity.
- Add a manifest or registry for available steps and their group.
- Document required/optional parameters for each step.
- For Docker/Kubernetes: add new step modules as needed.

---

<!-- documentation-anchors:start -->
<a id="doc-plotstep-settings-injection-problem"></a>
<!-- documentation-anchors:end -->
## Plot/Step Settings Injection Problem
Some steps require extra parameters/settings not standardized across all steps. This makes it difficult to inject settings in a uniform way.

<!-- documentation-anchors:start -->
<a id="doc-problem-statement"></a>
<!-- documentation-anchors:end -->
### Problem Statement
- Steps expect different parameters, some via `$GlobalSettings`, some via direct parameters.
- Plots (workflows) may need to pass custom settings to steps.

<!-- documentation-anchors:start -->
<a id="doc-solution-proposal-to-be-expanded-in-a-separate-document"></a>
<!-- documentation-anchors:end -->
### Solution Proposal (to be expanded in a separate document)
- Define a standard interface for step parameters (e.g., always accept a hashtable/object for extra settings).
- Document required/optional settings for each step.
- Use a settings injection utility to merge plot/step/global settings as needed.
- Consider a `Step-Invoke` wrapper that handles parameter mapping and validation.

See also: `docs/plot-step-settings-injection.md` (to be created)
