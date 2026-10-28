<!-- documentation-anchors:start -->
<a id="doc-build-server-integration"></a>
<!-- documentation-anchors:end -->
# Buildszerver-integráció

<!-- documentation-navigation -->
[English](build-server-basic-steps.md) | [Magyar](build-server-basic-steps-hu.md) · [Dokumentáció](README-hu.md) · [Projekt](../README-hu.md)
<!-- /documentation-navigation -->

A natív CLI nem interaktív, JSON futási eredményeket ad vissza, és preflight- vagy lépéshiba esetén 1 kóddal lép ki. A csomagokat az -AutoPath paraméterrel válaszd ki. Projektkonfigurációt a -ConfigPath paraméterrel adj meg, opcionálisan -DefaultConfigPath örökléssel és -EnvironmentConfigPath felülírással. Kifejezett hívásfelülírásokhoz használd a -Params paramétert. Buildügynökön a -WorkDirectory értékét kifejezetten add meg.

Függőségmentes futásidejű ellenőrzéshez futtasd a ./tests/Run-Tests.ps1 parancsot. A repository workflow-ja Windows PowerShell 5.1 és PowerShell 7 alatt futtatja a tesztcsomagot.

A történeti TFS/globális beállítási scripteket a [legacy/build-server-basic-steps-hu.md](legacy/build-server-basic-steps-hu.md) dokumentálja; ezek -Legacy módot használnak.
