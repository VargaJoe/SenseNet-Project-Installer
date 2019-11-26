[CmdletBinding(SupportsShouldProcess=$True)]
Param(
[Parameter(Mandatory=$true)]
[string]$IndexerPath,
[Parameter(Mandatory=$false)]
[string]$AsmFolderPath = "..\bin"
)

$Output = if ($ShowOutput -eq $True) {"Out-Default"} else {"Out-Null"}

Write-Verbose "Index will running: $IndexerPath -ASM $AsmFolderPath"
& $IndexerPath -ASM "$AsmFolderPath" | & $Output
Write-Verbose "Import was running: $IndexerPath -ASM $AsmFolderPath"

