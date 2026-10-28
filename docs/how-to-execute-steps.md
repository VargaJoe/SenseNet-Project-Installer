<!-- documentation-anchors:start -->
<a id="doc-execute-one-step"></a>
<!-- documentation-anchors:end -->
# Execute one step

<!-- documentation-navigation -->
[English](how-to-execute-steps.md) | [Magyar](how-to-execute-steps-hu.md) · [Documentation](README.md) · [Project](../README.md)
<!-- /documentation-navigation -->

Use Run.ps1 -Step package.step. The single invocation ID is single; pass its parameters as JSON with -Params, for example:

    ./src/Deployment/Scripts/Run.ps1 -Step text.join -Params '{"single":{"Items":["one","two"],"Separator":"-"}}'

See [settings](settings.md) for type validation, references and override rules. Historical Step-* execution is described in [legacy/how-to-execute-steps.md](legacy/how-to-execute-steps.md) and uses -Legacy.
