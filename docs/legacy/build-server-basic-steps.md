<!-- documentation-anchors:start -->
<a id="doc-build-server-basic-steps"></a>
<!-- documentation-anchors:end -->
# Build server basic steps

<!-- documentation-navigation -->
[English](build-server-basic-steps.md) | [Magyar](build-server-basic-steps-hu.md) · [Documentation](../README.md) · [Project](../../README.md)
<!-- /documentation-navigation -->

Even I don't go in details with external script we have created several steps we use for everyday sensenet development environment management. I will use only the "short name" for the steps, but you will find them with the prefix "Step-" in the scripts under AutoExt folder. The prefix is needed to distinguish them from ordinary powershell functions. For example "stop" step can be found as "Step-Stop" in "Default-Modules.ps1". External scripts are separate files and could be execute manual parametrizing, but we would lose the comfort and automatism of using the predefined settings. These external script files from the other folders. There is no time and place to write here all the external scripts and parameters we use. Maybe later.

*stop*
- it's job: Stop the IIS site and it's app pool
- settings: it will use the options of the given section of the setting json, default section is Project
- external script: .\Ops\Stop-IISSite.ps1 $ProjectSiteName

start
- it's job: Start the IIS site and it's app pool
- settings: it will use the options of the given section of the setting json, default section is Project
- external script: .\Ops\Start-IISSite.ps1 $ProjectSiteName

getlatest
- it's job: Get latest version of the project solution from TFS
- settings: Always uses SourceFolderPath from the Project section and VisualStudio from the Tools section
- external script: .\Dev\GetLatestSolution.ps1 -tfexepath $TfExePath -location $ProjectSourceFolderPath

restorepckgs
- it's job: Downloads and updates the NuGet packages used by the project
- settings: Always uses NuGetSourceUrl and NuGetFilePath from the Tools section, and SolutionFilePath from the Project section
- external script: .\Dev\Download-File.ps1 -Url $NuGetSourcePath -Output $NuGetFilePath
- special: The external script updates only the utility (nuget.exe); the step updates the packages directly using the console application

prbuild
- it's job: Build visual studio solution
- settings: Also always uses SolutionFilePath from the Project section
- external script: .\Dev\Build-Solution.ps1 -slnPath $ProjectSolutionFilePath

snservices
- it's job: Install services package which will create the basic api layer of sensenet
- settings: Uses WebConfigFilePath, ToolsFolderPath, DataSource, InitialCatalog and SnAdminFilePath from the targeted section (Project by default)
- external script: .\Deploy\Tool-Module.ps1 -SnAdminPath $SnAdminPath -ToolName install-services -ToolParameters "datasource:$DataSource","initialcatalog:$InitialCatalog","FORCEDREINSTALL:true"

snwebpages
- it's job: Install webpages package which will create the webforms functionality of sensenet
- settings: Uses SnAdminFilePath from the targeted section (Project by default)
- external script: .\Deploy\Tool-Module.ps1 -SnAdminPath $SnAdminPath -ToolName install-webpages

removedemo
- it's job: Runs an snadmin package we created to remove demo content installed by sn webpages
- settings: Always uses PackagesPath from the Source section and the fixed-name package path built from it, plus SnAdminFilePath from the targeted section (Project by default)
- external script: .\Deploy\Package-Module.ps1 -SnAdminPath $SnAdminPath -PackagePath $PackagePath

adminusers
- it's job: A sample snadmin package we created to configure a custom admin user and deactivate the default admin user
- settings: Always uses PackagesPath from the Source section and the fixed-name package path built from it, plus SnAdminFilePath from the targeted section (Project by default)
- external script: .\Deploy\Package-Module.ps1 -SnAdminPath $SnAdminPath -PackagePath $PackagePath

install
- it's job: A step for executing custom content and other preparation settings declared in the project settings
- settings: Uses SnAdminFilePath and DeployFolderPath from the targeted section (Project by default)
- external script: .\Deploy\Package-Module.ps1 -SnAdminPath $SnAdminPath -PackagePath $PackagePath

createsite
- it's job: A step for creating an IIS site and application pool
- settings: Uses WebFolderPath, WebAppName, AppPoolName and Hosts from the targeted section (Project by default)
- external script: .\Ops\Create-IISSite.ps1 -DirectoryPath $ProjectWebFolderPath -SiteName $ProjectSiteName -PoolName $ProjectAppPoolName -SiteHosts $ProjectSiteHosts

sethost
- it's job: A step for adding the configured URLs to the local machine hosts file
- settings: Uses Hosts from the targeted section (Project by default)
- external script: .\Ops\Set-Host.ps1 -SiteHosts $ProjectSiteHosts

deploywebfolder
- it's job: Deploys a prepared webfolder "template"
- settings: Always uses SnWebFolderFilePath from the Source section and WebFolderPath from the targeted section
- external script: .\Tools\Unzip-File.ps1 -filename $SnWebfolderPackPath -destname $ProjectWebFolderPath

index
- it's job: Populates the Lucene index
- settings: Uses SnAdminFilePath from the targeted section (Project by default)
- external script: .\Deploy\Index-Project.ps1 -SnAdminPath $SnAdminPath

import
- it's job: Uses Snadmin to import project content from the path specified in the settings
- settings: Uses RepoFsFolderPath and SnAdminFilePath from the targeted section (Project by default)
- external script: .\Deploy\Import-Module.ps1 -SnAdminPath $SnAdminPath -SourcePath $ProjectRepoFsFolderPath
export
- it's job: Uses Snadmin to export project content into a dated folder beneath App_Data in the webfolder specified in the settings
- settings: Uses RepoFsFolderPath and SnAdminFilePath from the targeted section (Project by default)
- external script: .\Deploy\Export-Module.ps1 -SnAdminPath $SnAdminPath -TargetPath $ProjectWebFolderPath\App_Data\Export$CurrentDateTime

setrepourl
- it's job: Sets the configured URLs on the corresponding sites in the repository
- settings: Uses SnAdminFilePath from the targeted section (Project by default)
- external script: .\Deploy\Tool-Module.ps1 -SnAdminPath $SnAdminPath -ToolName seturl -ToolParameters "site:$ProjectSiteName","url:$HostnameToLower","authenticationType:$AuthenticationType"

backupdb
- it's job: Creates a database backup
- settings: Uses DataSource, InitialCatalog and DbBackupFilePath from the targeted section (Project by default)
- external script: .\Ops\Backup-Db.ps1 -ServerName $DataSource -CatalogName $InitialCatalog -FileName $DbBackupFilePath

autobackupdb
- it's job: Creates a database backup
- settings: Uses DataSource, InitialCatalog and DatabasesPath from the targeted section (Project by default)
- external script: .\Ops\Backup-Db.ps1 -ServerName "$DataSource" -CatalogName "$InitialCatalog" -FileName "$DatabaseBackupsFolderPath\$BackupName"

restoredb
- it's job: Restores a database from the specified path (network paths are not yet supported)
- settings: Uses DataSource, InitialCatalog and DbBackupFilePath from the targeted section (Project by default)
- external script: .\Ops\Restore-Db.ps1 -ServerName $DataSource -CatalogName $InitialCatalog -FileName $DbBackupFilePath

dropdb
- it's job: Deletes the database from SQL Server
- settings: Uses DataSource and InitialCatalog from the targeted section (Project by default)
- external script: .\Ops\Drop-Db.ps1 -ServerName "$DataSource" -CatalogName "$InitialCatalog"

setconnection
- it's job: Sets the connection string in web.config and the snadminruntime configuration; these two settings are the minimum required to run snadmin packages
- settings: Uses DataSource, InitialCatalog, SnAdminRCFilePath and WebConfigFilePath from the targeted section (Project by default)
- external script: .\Deploy\Set-Connection.ps1 -ConfigFilePath "$aConfigFilePath" -DataSource "$DataSource" -InitialCatalog "$InitialCatalog"

downloaddatabase
- it's job: Downloads a database backup from a URL and saves it to the configured path
- settings: Always uses DbBackupFileUrl and DbBackupFilePath from the Source section
- external script: .\Dev\Download-File.ps1 -Url $WebPath -Output $LocalPath

downloadwebpack
- it's job: Downloads the webfolder "template" from a URL and saves it to the configured path
- settings: Always uses SnWebFolderFileUrl and SnWebFolderFilePath from the Source section
- external script: .\Dev\Download-File.ps1 -Url $WebPath -Output $LocalPath

stopremote
- it's job: Stops the IIS site on a remote machine
- settings: Uses WebAppName and MachineName from the targeted section (Project by default)
- external script: .\Ops\Run-Remote.ps1 -RemoteServerName $MachineName -PsFilePath .\Ops\Stop-IISSite.ps1 -PsFileArgumentList $ProjectSiteName

startremote
- it's job: Starts the IIS site on a remote machine
- settings: Uses WebAppName and MachineName from the targeted section (Project by default)
- external script: .\Ops\Run-Remote.ps1 -RemoteServerName $MachineName -PsFilePath .\Ops\Start-IISSite.ps1 -PsFileArgumentList $ProjectSiteName

The steps above are not organized yet. They may later be split into separate files by function, or simply grouped to make them easier to navigate.

The steps discussed here can be extended freely as mentioned earlier. Create a project-specific ps1 file (for example Sajátproject-Modules.ps1) and place it in the "AutoExt" folder. Its declared steps then become available automatically. (The filename currently ends in "Modules"; this should not confuse PowerShell users. "Steps" would be more appropriate, but it has not been renamed here yet.)

Example custom scripts
"Deploy-Modules.ps1":

prinstall
- it's job: Matches the install step among the default steps, except that it always uses the Project section as the source
- settings: Uses SnAdminFilePath from the targeted section (Project by default), and always DeployFolderPath from the Project section
- external script: .\Deploy\Package-Module.ps1 -SnAdminPath $SnAdminPath -PackagePath $PackagePath

primport
- it's job: Matches the import step among the default steps, except that it always uses the Project section as the source
- settings: Uses SnAdminFilePath from the targeted section (Project by default), and always RepoFsFolderPath from the Project section
- external script: .\Deploy\Import-Module.ps1 -SnAdminPath $SnAdminPath -SourcePath $ProjectRepoFsFolderPath

prasmdeploy
- it's job: Copies the contents of the project bin folder into the destination webfolder bin folder
- settings: Uses AsmFolderPath from the targeted section (Project by default), and always AsmFolderPath from the Project section
- external script: No external script is used; the copy logic is declared in the step

"Old-Modules.ps1"

proldimport
- it's job: Content import based on the import tool used in sensenet versions before sn7
- settings: Always uses RepoFsFolderPath from the Project section, plus ImporterPath and AsmFolderPath from the targeted section (Project by default)
- external script: .\Old\Import-Module.ps1 -ImporterPath $ImporterPath -SourcePath $ProjectRepoFsFolderPath -AsmFolderPath $AsmFolderPath
- note: To run on a remote machine from a network path, remote assembly loading must be enabled in the tool configuration

proldexport
- it's job: Content export based on the import tool used in sensenet versions before sn7
- settings: Always uses RepoFsFolderPath from the Project section, plus WebFolderPath, ExporterPath and AsmFolderPath from the targeted section (Project by default)
- external script: .\Old\Export-Module.ps1 -ExporterPath $ExporterPath -TargetPath $ProjectWebFolderPath\App_Data\Export$CurrentDateTime -AsmFolderPath $AsmFolderPath
- note: To run on a remote machine from a network path, remote assembly loading must be enabled in the tool configuration

proldindex
- it's job: Lucene indexing based on the import tool used in sensenet versions before sn7
- settings: Always uses IndexerPath and AsmFolderPath from the targeted section (Project by default)
- external script: .\Old\Index-Module.ps1 -IndexerPath $IndexerPath -AsmFolderPath $AsmFolderPath
- note: To run on a remote machine from a network path, remote assembly loading must be enabled in the tool configuration
