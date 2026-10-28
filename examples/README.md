<!-- documentation-anchors:start -->
<a id="doc-plot-manager-demo-projects"></a>
<!-- documentation-anchors:end -->
# Plot Manager demo projects

<!-- documentation-navigation -->
[English](README.md) | [Magyar](README-hu.md) · [Documentation](../docs/README.md) · [Project](../README.md)
<!-- /documentation-navigation -->

These reusable example projects belong to the repository. Their inputs are
versioned; generated output files, local passwords and backups are not source
files. They demonstrate Plot Manager step by step using fresh project copies.

| Demo | Source | Demonstrated capability |
|---|---|---|
| 01 – Guided file installer | [Project](management-demos/01-vezetett-telepito) | Guided questions, saved settings, output dependencies and actual file writing. |
| 02 – Layers, types and references | [Project](management-demos/02-retegek-es-hivatkozasok) | Default/project/environment layers, value types and inheritance, detection of intentionally incorrect ordering. |
| 03 – JSON, XML and ZIP packaging | [Project](management-demos/03-json-xml-zip) | A nine-step file generation, packaging, hashing and verification pipeline. |
| 04 – SenseNet Docker installation and management | [Project](sensenet-docker/README.md) | Installing and managing a real application, authenticated verification, and backup/restore. |

**[Documentation — start here](../docs/management-guide-index.md)**
· [Every demo, scenario and step](../docs/management-demo-projects.md)
· [Every GUI page, button and panel](../docs/management-user-guide.md)

The first three require only Plot Manager's native packages. The fourth creates
its own Docker Linux containers and volumes; read its prerequisites and its
data-replacing restore operation before running it.

A working copy registered in the application is independent of the repository's
clean example. For a new demonstration, copy the complete project directory
beneath the service's allowed project root, then enter that copy's runner-side
path in **Workspace → Open project**. Adding a project to the repository does
not register it in every desktop/browser data store. Always choose a new name
and free ports for SenseNet; do not copy `.local` to another instance.
