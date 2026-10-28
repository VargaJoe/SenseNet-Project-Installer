<!-- documentation-anchors:start -->
<a id="doc-sources-for-the-three-general-plot-manager-demos"></a>
<!-- documentation-anchors:end -->
# Sources for the three general Plot Manager demos

<!-- documentation-navigation -->
[English](README.md) | [Magyar](README-hu.md) · [Documentation](../../docs/README.md) · [Project](../../README.md)
<!-- /documentation-navigation -->

These are the portable, unchanged input configurations for the first three
demos shown in the installed application. They do not include generated output.

| Directory | Name in the application | Plots |
| --- | --- | --- |
| [01-vezetett-telepito](01-vezetett-telepito) | 01 – Vezetett fájltelepítő | `install` |
| [02-retegek-es-hivatkozasok](02-retegek-es-hivatkozasok) | 02 – Rétegek, típusok és hivatkozások | `show-settings`, `hibas-sorrend` |
| [03-json-xml-zip](03-json-xml-zip) | 03 – JSON, XML és ZIP csomagolás | `package` |

The fourth project runs in Docker and has its own directory:
[SenseNet Docker](../sensenet-docker/README.md).

**[Complete demo catalog, scenarios and explanations of every step](../../docs/management-demo-projects.md)**
· **[Complete GUI user manual](../../docs/management-user-guide.md)**

To use a demo, copy its complete project directory beneath the Plot Manager
service's allowed project root and select **Open project** in the project picker.
The path is on the service host. `plot-project.json` is the project descriptor;
the three configuration layers use the native engine's unchanged JSON format.

The copy is an independent project: it does not automatically follow its GitHub
source or synchronize between desktop and browser instances. The first three
demos require neither Docker nor an external service. Outputs are generated
inside your project copy; the detailed guide lists them and explains rerun effects.
