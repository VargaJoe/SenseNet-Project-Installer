<!-- documentation-anchors:start -->
<a id="doc-plotstep-settings-injection"></a>
<!-- documentation-anchors:end -->
# Plot-/lépésbeállítások injektálása

<!-- documentation-navigation -->
[English](plot-step-settings-injection.md) | [Magyar](plot-step-settings-injection-hu.md) · [Dokumentáció](README-hu.md) · [Projekt](../README-hu.md)
<!-- /documentation-navigation -->

A korábbi StepSettings-javaslat a natív futtatókörnyezet hívásonkénti Settings szerződéseként megvalósult.

A precedenciát, mély összefésülést, null-/tömbviselkedést, kifejezett környezeti hivatkozásokat, korábbi lépéskimeneteket és validációt lásd a [settings-hu.md](settings-hu.md) oldalon. A csomagsémákat és a Settings/Context parancsszerződést lásd a [custom-steps-hu.md](custom-steps-hu.md) oldalon.

A futtató a regisztrált parancs meghívása előtt feloldja a beállításokat. A Context végrehajtási metaadatokat hordoz; a lépésnek nem kell globális projektbeállításokat vizsgálnia. A történeti Section/globálisváltozó-viselkedés csak a legacy futtatón keresztül érhető el.
