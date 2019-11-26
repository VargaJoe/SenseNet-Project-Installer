[CmdletBinding(SupportsShouldProcess=$True)]
Param(
[Parameter(Mandatory=$true)]
[string]$ImporterPath,
[Parameter(Mandatory=$true)]
[string]$SourcePath,
[Parameter(Mandatory=$false)]
[string]$AsmFolderPath = "..\bin"
)


$Output = if ($ShowOutput -eq $True) {"Out-Default"} else {"Out-Null"}

write-host $SourcePath\System\Schema\ContentTypes
if ((Test-Path $SourcePath\System\Schema\ContentTypes)) {
	Write-Verbose "Import will running: $ImporterPath -SCHEMA $SourcePath\System\Schema -SOURCE $SourcePath $ToolParameters -ASM $AsmFolderPath"
	#& $ImporterPath -SCHEMA $SourcePath\System\Schema -SOURCE "$SourcePath" -TARGET /Root -ASM "$AsmFolderPath" | & $Output
	& $ImporterPath -SCHEMA $SourcePath\System\Schema -SOURCE "$SourcePath" -TARGET /Root -ASM "$AsmFolderPath" | & $Output
	Write-Verbose "Import was running: $ImporterPath -SCHEMA $SourcePath\System\Schema -SOURCE $SourcePath $ToolParameters -ASM $AsmFolderPath"
} ELSE {
	Write-Verbose "Import will running: $ImporterPath -SOURCE $SourcePath $ToolParameters -ASM $AsmFolderPath"
	& $ImporterPath -SOURCE "$SourcePath" -TARGET /Root -ASM "$AsmFolderPath" | & $Output
	Write-Verbose "Import was running: $ImporterPath -SOURCE $SourcePath $ToolParameters -ASM $AsmFolderPath"
}


