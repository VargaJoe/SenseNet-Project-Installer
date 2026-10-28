<!-- documentation-anchors:start -->
<a id="doc-component-and-migration-map"></a>
<!-- documentation-anchors:end -->
# Component and migration map

<!-- documentation-navigation -->
[English](migration-map.md) | [Magyar](migration-map-hu.md) · [Documentation](README.md) · [Project](../README.md)
<!-- /documentation-navigation -->

Source preservation reference before management UI work:
[`98b483e4214a4299e30e70ba90f71f51eed953d8`](https://github.com/VargaJoe/SenseNet-Project-Installer/tree/98b483e4214a4299e30e70ba90f71f51eed953d8).
No historical component is removed in this preparation.

| Component | Disposition | Replacement / boundary |
| --- | --- | --- |
| `Core/PlotManager.psm1`, native `Auto/*/package.psd1` | Retain, authoritative | Configuration resolution, validation and sequential execution shared by CLI and management UI |
| `Run.ps1`, JSON plot/settings format | Retain, compatible | Supported PowerShell 5.1 / 7 CLI |
| `Core/PlotIntegration.psm1`, `Invoke-Request.ps1` | Retain, extend | Existing catalog/plan/run v1 calls remain usable |
| `Show-PlotRunner.ps1` | Retain, transitional | Windows Forms launcher; shared management UI is its planned successor |
| Historical Angular GUI and HTTP listener | Retain, deprecated for new work | Fresh `src/Management/` React and ASP.NET Core implementation; historical clients are not the new API |
| `Run-Legacy.ps1`, `AutoExt/`, original installer assets | Retain pending user acceptance | Separate-process compatibility, existing Windows/tool/admin prerequisites; no full native parity claim |
| `docs/legacy/` | Retain as historical reference | Current entry point is `docs/README.md` |
| `src/Management/Server/` | New component location | Authenticated local/hosted API, project and run lifecycle, isolated native workers |
| `src/Management/Web/` | New component location | Shared React/TypeScript UI |
| `src/Desktop/` | New component location | Tauri Windows/Linux packaging and local service lifecycle |

Legacy retirement and repository rename are separate later decisions after user
acceptance. Native plots remain sequential; parallelism, branching, retry and
remote-agent execution must not be advertised without actual engine support.
This personal repository must not receive corporate source, configuration,
credentials, history or application-specific installation assets.
