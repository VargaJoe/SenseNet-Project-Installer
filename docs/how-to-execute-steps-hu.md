<!-- documentation-anchors:start -->
<a id="doc-execute-one-step"></a>
<!-- documentation-anchors:end -->
# Egy lépés végrehajtása

<!-- documentation-navigation -->
[English](how-to-execute-steps.md) | [Magyar](how-to-execute-steps-hu.md) · [Dokumentáció](README-hu.md) · [Projekt](../README-hu.md)
<!-- /documentation-navigation -->

Használd a Run.ps1 -Step package.step parancsot. Az egyetlen hívás azonosítója single; paramétereit JSON-ként add át a -Params kapcsolóval, például:

    ./src/Deployment/Scripts/Run.ps1 -Step text.join -Params '{"single":{"Items":["one","two"],"Separator":"-"}}'

A típusvalidációt, hivatkozásokat és felülírási szabályokat lásd a [beállításoknál](settings-hu.md). A történeti Step-* végrehajtást a [legacy/how-to-execute-steps-hu.md](legacy/how-to-execute-steps-hu.md) írja le; az -Legacy módot használ.
