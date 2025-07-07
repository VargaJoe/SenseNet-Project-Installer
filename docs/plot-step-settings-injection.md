# Plot/Step Settings Injection Problem & Solution

## Problem Statement
Many steps require extra parameters or settings that are not standardized across all steps. This makes it difficult to inject settings from plots (workflows) in a uniform and maintainable way.

### Current Issues
- Steps expect different parameters: some use `$GlobalSettings`, others require direct parameters.
- No standard for required/optional step parameters.
- Plots (workflows) may need to pass custom settings to steps, but there is no uniform interface.

## Solution Proposal

### 1. Standardize Step Parameter Interface
- All step functions should accept a `[hashtable]$StepSettings` (or similar) parameter for extra settings.
- Document required and optional settings for each step.
- Use `[Parameter(Mandatory=$false)]` for extensibility.

### 2. Settings Injection Utility
- Create a utility function (e.g., `Merge-StepSettings`) to merge global, plot, and step-specific settings.
- The utility should resolve conflicts and provide a single settings object to the step.

### 3. Step Invocation Wrapper
- Implement a `Step-Invoke` function that:
  - Accepts the step name and a settings object.
  - Validates required parameters for the step.
  - Calls the step with the merged settings.
  - Handles error reporting and logging.

### 4. Documentation
- Each step must document its required and optional settings.
- Plots should declare which settings they provide to each step.

## Example
```powershell
function Step-Example {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory=$false)]
        [hashtable]$StepSettings
    )
    $foo = $StepSettings['Foo']
    $bar = $StepSettings['Bar']
    # ...
}

function Step-Invoke {
    param(
        [string]$StepName,
        [hashtable]$Settings
    )
    # Validate, merge, and call the step
    & $StepName -StepSettings $Settings
}
```

## Benefits
- Uniform interface for all steps.
- Easier to inject and override settings from plots.
- Improved maintainability and extensibility.

---

This document is a draft and will be refined as Story 03 progresses.
