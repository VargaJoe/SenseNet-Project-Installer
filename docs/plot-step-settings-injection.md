# Plot/step settings injection

The earlier StepSettings proposal has been implemented as the native runtime's per-invocation Settings contract.

See [settings.md](settings.md) for precedence, deep merge, null/array behavior, explicit environment references, earlier-step outputs and validation. See [custom-steps.md](custom-steps.md) for package schemas and the Settings/Context command contract.

The runner resolves settings before calling a registered command. Context carries execution metadata; the step does not need to inspect global project settings. Historical Section/global-variable behavior is available only through the legacy runner.
