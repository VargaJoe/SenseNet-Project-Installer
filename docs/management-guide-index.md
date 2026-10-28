<!-- documentation-anchors:start -->
<a id="doc-plot-manager--english-user-documentation"></a>
<!-- documentation-anchors:end -->
# Plot Manager — English user documentation

<!-- documentation-navigation -->
[English](management-guide-index.md) | [Magyar](management-guide-index-hu.md) · [Documentation](README.md) · [Project](../README.md)
<!-- /documentation-navigation -->

This is the starting point for the current shared desktop and browser version of
Plot Manager. The four demos, project files and guides are in the repository:
reading them does not require the development machine or local service to run.
Trying the operations themselves requires a running Plot Manager.

<!-- documentation-anchors:start -->
<a id="doc-what-should-i-open-first"></a>
<!-- documentation-anchors:end -->
## What should I open first?

| Question | Reading |
|---|---|
| What do project, plot, step and configuration layer mean? | The beginning of the [complete GUI guide](management-user-guide.md). |
| What is each page, button, view and panel for? | The [complete GUI guide](management-user-guide.md), using the actual English screen labels. |
| What do the four projects do, and what should I see after running them? | [Demo projects and scenarios](management-demo-projects.md). |
| Where are the actual configurations of the first three demos? | [The three general demos](../examples/management-demos/README.md), containing clean project inputs without generated output. |
| Where is the SenseNet Docker project? | [SenseNet usage](../examples/sensenet-docker/README.md), [configuration](../examples/sensenet-docker/default.json), [Compose file](../examples/sensenet-docker/compose.yaml). |
| How do I install or start the management application? | [Build, desktop and browser deployment](management-deployment.md), the technical guide. |
| How do native JSON, inheritance and references work? | [Settings](settings.md) and the [native runtime](plot-manager-runtime.md), the detailed technical background. |
| What behavior was actually verified? | [Management validation](management-validation.md) and [SenseNet project verification](../examples/sensenet-docker/VALIDATION.md). |

<!-- documentation-anchors:start -->
<a id="doc-the-purpose-of-the-four-demos"></a>
<!-- documentation-anchors:end -->
## The purpose of the four demos

| Project | What it teaches | External dependency / effect |
|---|---|---|
| **01 — Guided file installer** | Turning questions into settings, two dependent steps and an actual file. | Writes text in its own project directory. |
| **02 — Layers, types and references** | Default → project → development/production, overrides and the origin of an effective value. | Writes a JSON result file in its own project directory. |
| **03 — JSON, XML and ZIP packaging** | A real sequential pipeline, previous-step output, file generation, packaging and verification. | Creates its own build, ZIP and extracted files. |
| **04 — SenseNet Docker installation and management** | A real application's installation and operations lifecycle using the same engine. | Own Docker stack, SQL and App_Data volumes, local HTTPS, backup and restore. |

The [demo catalog](management-demo-projects.md) lists every project's plots,
invocation IDs, called steps, inputs, outputs, ordering dependencies,
scenarios and verifiable results separately.

<!-- documentation-anchors:start -->
<a id="doc-suggested-learning-order"></a>
<!-- documentation-anchors:end -->
## Suggested learning order

1. Read the GUI guide's terminology and screen map.
2. Open project **01**. Follow Guided setup, then see which file receives the
   answers on the **Configuration** page.
3. Open the same plot in **Plot editor**: its two invocations and output reference
   demonstrate the engine's basic idea. Check and run the saved version, then
   read the detailed result in **Run history**.
4. In project **02**, switch environments and compare the source layer with the
   effective configuration. Try removing an override.
5. In project **03**, follow where the JSON, XML and ZIP come from; notice why
   not every output-dependent step can be started on its own.
6. Start project **04** once Docker and the development SQL prerequisites are
   available. Restore replaces data: use the documented backup and exact
   stack-name confirmation.

<!-- documentation-anchors:start -->
<a id="doc-review-using-github-alone"></a>
<!-- documentation-anchors:end -->
## Review using GitHub alone

The PR's **Files changed** view shows the changes. To read a long guide more
comfortably, open the Markdown file itself and select the rendered view. The
relative links above point to files on the same branch.

The GUI belongs to **PR #32**. The SenseNet project, versioned definitions of
the first three demos and this complete documentation belong to the stacked
**PR #33**. Until these are merged, the default branch's documentation may
differ: read the PR branch or the commit referenced in the handoff.

The editing-state preservation fixes and complete English/Hungarian documentation
pairs belong to **PR #34**. Both language indexes expose the same topics;
English is the default. The previous `a8cb561b` installer packages do not
include the editing fixes.

| What can I verify without running anything? | Where is it visible? |
|---|---|
| How does each project name its plots and steps? | `default.json` → `Plots` → `Steps`, and the demo catalog's invocation tables. |
| Which values inherit and which are overrides? | Compare the project's `default.json`, `project.json` and `environments/*.json`. |
| What does Guided setup ask? | `plot-project.json` → `wizard.groups[].fields[]`. `settingPath` identifies the ordinary setting receiving an answer. |
| What does a generic step do? | The demo catalog's explanation and the step's [package manifest](../src/Deployment/Scripts/Auto/). |
| What does SenseNet preparation or restore do? | The [project script](../examples/sensenet-docker/scripts/Manage-SenseNet.ps1), its separate usage guide and the catalog. |
| What is the source of the GUI's exact button/panel descriptions? | [App.tsx](../src/Management/Web/src/App.tsx), [parameter fields](../src/Management/Web/src/components.tsx), and the related server and engine logic. |

GitHub does not execute these plots, and localhost URLs on a switched-off
machine are not reachable from GitHub. Durable run history stays in the
application's own data store; portable inputs and descriptions of verification
belong in the repository.

<!-- documentation-anchors:start -->
<a id="doc-short-acceptance-checklist"></a>
<!-- documentation-anchors:end -->
## Short acceptance checklist

- [ ] I can name the purpose and main output of all four projects.
- [ ] I can find each plot's step order and output dependencies.
- [ ] I can distinguish an edited source layer from saved effective configuration.
- [ ] I understand preflight, WhatIf and actual execution.
- [ ] I know where the execution host, run state and individual step results appear.
- [ ] I understand cancellation and the external effects that can remain.
- [ ] I know where projects, secrets and backups live and which copy I am editing.
- [ ] Before a SenseNet restore, I understand which owned stack's data it replaces.
