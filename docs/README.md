# Documentation

Start with [README](../README.md) for the CLI and installed packages.

## Magyar felhasználói útmutatók

- [Itt kezdd: olvasási sorrend, négy demó és GitHub-ellenőrzés](management-guide-index-hu.md).
- [Teljes GUI-útmutató: oldalak, gombok, nézetek, panelek és munkafolyamatok](management-user-guide-hu.md).
- [Demóprojektek: forgatókönyvek, minden plot és step, bemenetek és elvárt kimenetek](management-demo-projects-hu.md).

Az általános demók [tiszta projektfájljai](../examples/management-demos/README.md)
és a [SenseNet Docker projekt](../examples/sensenet-docker/README.md) is verziózottak;
olvasásukhoz nem kell az eredeti gépnek bekapcsolva lennie.

## Technical guides

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
| Management delivery evidence and limits | [Validation record](management-validation.md) |

Management UI source belongs under `src/Management/`; desktop packaging under
`src/Desktop/`. Both wrap the native engine under `src/Deployment/Scripts/`.
See the migration map before retiring historical components.
