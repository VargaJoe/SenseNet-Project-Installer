<!-- documentation-anchors:start -->
<a id="doc-documentation"></a>
<!-- documentation-anchors:end -->
# Documentation

<!-- documentation-navigation -->
[English](README.md) | [Magyar](README-hu.md) · [Documentation](README.md) · [Project](../README.md)
<!-- /documentation-navigation -->

English is the default. Every page below has a complete Hungarian counterpart, accessible through the language links at its top. Start with the [guided reading path](management-guide-index.md), [complete GUI manual](management-user-guide.md), or [all four demo projects](management-demo-projects.md). The [project overview](../README.md) covers the CLI and installed packages.

<!-- documentation-anchors:start -->
<a id="doc-user-guides-and-demo-projects"></a>
<!-- documentation-anchors:end -->
## User guides and demo projects

| Topic | Guide |
| --- | --- |
| Plot Manager: complete guide to the four demo projects | [Read](management-demo-projects.md) |
| Plot Manager — English user documentation | [Read](management-guide-index.md) |
| Plot Manager – complete user guide | [Read](management-user-guide.md) |
| Plot Manager demo projects | [Read](../examples/README.md) |
| Sources for the three general Plot Manager demos | [Read](../examples/management-demos/README.md) |
| SenseNet Docker project for Plot Manager | [Read](../examples/sensenet-docker/README.md) |
| Verification — 2026-10-22 | [Read](../examples/sensenet-docker/VALIDATION.md) |

<!-- documentation-anchors:start -->
<a id="doc-runtime-and-development"></a>
<!-- documentation-anchors:end -->
## Runtime and development

| Topic | Guide |
| --- | --- |
| How to contribute | [Read](../CONTRIBUTING.md) |
| Plot Manager | [Read](../README.md) |
| Build server integration | [Read](build-server-basic-steps.md) |
| Author a step package | [Read](custom-steps.md) |
| General-purpose packages | [Read](generic-packages.md) |
| Execute a plot | [Read](how-to-execute-a-plot.md) |
| Execute one step | [Read](how-to-execute-steps.md) |
| Local GUI and structured integration | [Read](local-integration.md) |
| Component and migration map | [Read](migration-map.md) |
| Generic operational packages | [Read](operations-packages.md) |
| SQL Server, IIS, web maintenance and Compose | [Read](platform-packages.md) |
| Plot Manager runtime | [Read](plot-manager-runtime.md) |
| Plot/step settings injection | [Read](plot-step-settings-injection.md) |
| PowerShell conventions | [Read](powershell-coding-standards.md) |
| Plot configuration | [Read](settings.md) |
| Runtime regression tests | [Read](../tests/README.md) |

<!-- documentation-anchors:start -->
<a id="doc-management-application"></a>
<!-- documentation-anchors:end -->
## Management application

| Topic | Guide |
| --- | --- |
| Management application acceptance | [Read](management-acceptance.md) |
| Management API, protocol 1 | [Read](management-api.md) |
| Shared management architecture | [Read](management-architecture.md) |
| Management build, desktop packaging and deployment | [Read](management-deployment.md) |
| Management validation record | [Read](management-validation.md) |

<!-- documentation-anchors:start -->
<a id="doc-historical-guides"></a>
<!-- documentation-anchors:end -->
## Historical guides

Retained historical material and proposals describe their original scope; they are not promises of current implementation.

| Topic | Guide |
| --- | --- |
| Build server basic steps | [Read](legacy/build-server-basic-steps.md) |
| Custom step declaration | [Read](legacy/custom-steps.md) |
| How to execute a "plot" | [Read](legacy/how-to-execute-a-plot.md) |
| How to execute steps | [Read](legacy/how-to-execute-steps.md) |
| Configuration Settings | [Read](legacy/settings.md) |
| SNOnlineInstaller | [Read](../src/GUI/README.md) |

<!-- documentation-anchors:start -->
<a id="doc-historical-plans-and-audit-reports"></a>
<!-- documentation-anchors:end -->
## Historical plans and audit reports

Retained historical material and proposals describe their original scope; they are not promises of current implementation.

| Topic | Guide |
| --- | --- |
| Implementation Tasks and Project Analysis | [Read](implementation-tasks.md) |
| Plots and Steps Audit & Grouping Proposal | [Read](plots-steps-audit.md) |
| PowerShell Codebase Audit Summary | [Read](powershell-audit-summary.md) |
| Runtime refactor status | [Read](powershell-standards-implementation-plan.md) |
| Story 01 - Foundation Transformation | [Read](stories/story01-foundation-transformation.md) |
| Story 02 - Angular Frontend Modernization | [Read](stories/story02-angular-modernization.md) |
| Story 03 - PowerShell Code Standardization | [Read](stories/story03-powershell-standardization.md) |
| Story 04 - Comprehensive Testing Framework | [Read](stories/story04-testing-framework.md) |
| Story 05 - Enhanced Security and Authentication | [Read](stories/story05-security-authentication.md) |
| Story 06 - Docker Orchestration and Container Management | [Read](stories/story06-docker-orchestration.md) |
| Story 07 - Cloud Platform Integration | [Read](stories/story07-cloud-platform-integration.md) |
| Story 08 - Monitoring and Observability Platform | [Read](stories/story08-monitoring-observability.md) |
| Story 09 - Plugin Architecture and Extensibility | [Read](stories/story09-plugin-architecture.md) |
| Story 10 - Configuration Management Enhancement | [Read](stories/story10-configuration-management.md) |

<!-- documentation-anchors:start -->
<a id="doc-maintain-both-languages"></a>
<!-- documentation-anchors:end -->
## Maintain both languages

Canonical filenames without a language suffix contain English; `-hu.md` siblings contain Hungarian. Translate full pages, not summaries. Keep code examples, CLI/API identifiers, UI captions and literal configuration values unchanged. Preserve the distinction between historical evidence, current source and older packages. Add both pages to [the language manifest](documentation-languages.json), link them from this index and update both when behavior changes. Stable section anchors keep cross-page links usable in either language.

Run the independent documentation checks from the repository root:

```powershell
node ./scripts/management/Test-Documentation.mjs --self-test
node ./scripts/management/Test-Documentation.mjs
```

Explanatory text diagrams may be translated when explicitly listed under `localizedTextBlocks` in the manifest. Executable examples remain identical.
