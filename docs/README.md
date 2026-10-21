# Documentation

Start with [README](../README.md) for the CLI and installed packages.

| Topic | Guide |
| --- | --- |
| Runtime and compatibility | [Runtime](plot-manager-runtime.md) |
| Configuration layers and references | [Settings](settings.md) |
| Step package authoring | [Custom steps](custom-steps.md) |
| File, archive, JSON and XML packages | [Generic packages](generic-packages.md) |
| Processes, networking, Git and build | [Operational packages](operations-packages.md) |
| SQL Server, IIS, Compose and web | [Platform packages](platform-packages.md) |
| Existing Windows Forms and JSON integration | [Local integration](local-integration.md) |
| Retained and replacement components | [Migration map](migration-map.md) |
| Tests | [Test guide](../tests/README.md) |
| Shared desktop / browser management | [Architecture](management-architecture.md), [user guide](management-user-guide.md), [build and deployment](management-deployment.md), [API](management-api.md) |
| Manual management acceptance | [Fresh project, layers, plots, reconnect and CLI parity](management-acceptance.md) |

Management UI source belongs under `src/Management/`; desktop packaging under
`src/Desktop/`. Both wrap the native engine under `src/Deployment/Scripts/`.
See the migration map before retiring historical components.
