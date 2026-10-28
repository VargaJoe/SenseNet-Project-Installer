<!-- documentation-anchors:start -->
<a id="doc-custom-step-declaration"></a>
<!-- documentation-anchors:end -->
# Custom step declaration

<!-- documentation-navigation -->
[English](custom-steps.md) | [Magyar](custom-steps-hu.md) · [Documentation](../README.md) · [Project](../../README.md)
<!-- /documentation-navigation -->

For the automation above to work and to allow arbitrary additional steps, a step must have the following structure:

```powershell
Function Step-Lepesneve {
<#
.SYNOPSIS
Lépés rövid leírása
.DESCRIPTION
lépés leírásának bővebb kifejtése
#>
[CmdletBinding(SupportsShouldProcess=$True)]
Param(
[parameter(Mandatory=$false)]
[String]$section="Project"
)

try {
$ProjectSiteName = $GlobalSettings."$section".WebAppName
& "$ScriptBaseFolderPath\Ops\Stop-IISSite.ps1" $ProjectSiteName
$script:Result = $LASTEXITCODE
}
catch {
$script:Result = 1
}
}
```

In the example above, the step can be invoked directly through Run if no scenario has the same name:
```powershell
.\Run.ps1 -Legacy lepesneve
```

Or, more explicitly (do not be confused by the parameter being named plot here):
```powershell
.\Run.ps1 -Legacy -Plot lepesneve -Settings local
```

When the step runs, the synopsis from its script help is displayed, approximately as follows:

```console
================================================
============= Plotneve/Lepesneve =============
================================================
Synopsis: Lépés rövid leírása
Progress: 100
```

Fill in the description for future users; other supported help comments can also be used here. These can be retrieved with the PowerShell Get-Help function.

The following parameter lets the step target a settings section. In this example the default section is "Project". A step that does not need it does not have to declare it, but remember that the step will throw an error if called with a Section parameter.
```powershell
[CmdletBinding(SupportsShouldProcess=$True)]
Param(
[parameter(Mandatory=$false)]
[String]$section="Project"
)
```

Wrap business logic in try/catch to ensure a return value is available even on failure. By convention, a general error returns 1. Other values may be used; to my knowledge nothing consumes the return values yet, and for now they are passed along only as information.

The settings file values are accessed from a global variable together with the section parameter. This variable already contains the merged project and default settings.
```powershell
$GlobalSettings."$section".beállításnév
```

Finally, after a normal execution, return the value of the exitcode environment variable. For console applications this will probably provide an appropriate value; custom scripts should emulate it:
```powershell
$script:Result = $LASTEXITCODE
```
