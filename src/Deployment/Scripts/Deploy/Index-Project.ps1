Write-Host ================================================ -foregroundcolor "green"
Write-Host INDEXPOPULATION -foregroundcolor "green"
Write-Host ================================================ -foregroundcolor "green"

$ProjectSnAdminFilePath = Get-FullPath $GlobalSettings.Project.SnAdminFilePath

Write-Host $ProjectSnAdminFilePath index
& $ProjectSnAdminFilePath index
