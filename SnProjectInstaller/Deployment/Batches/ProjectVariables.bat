SET SNRELEASESPATH=..\..\Releases
SET SNSRCNAME=sn-enterprise-src-6.5.3.8855
SET INSTALLERTOOLSFOLDER=..\Tools
SET REFERENCESFOLDER=..\..\References
SET COREREFERENCESPATH=%REFERENCESFOLDER%\Core

rem initiate solution environment for install
SET SNSRCBASEPATH=%SNRELEASESPATH%\%SNSRCNAME%

SET DEFAULTSTRUCTUREPATH=%SNSRCBASEPATH%\Source\SenseNet\WebSite\Root
SET SNSRCDBSCRIPTSPATH=%SNSRCBASEPATH%\Source\SenseNet\Storage\Data\SqlClient\Scripts
SET SNSRCTOOLSPATH=%SNSRCBASEPATH%\Source\SenseNet\WebSite\Tools
SET SNSRCADMINPATH=%SNSRCBASEPATH%\Source\SenseNet\WebSite\Admin
SET SNSRCTASKMANAGEMENTPATH=%SNSRCBASEPATH%\Source\SenseNet\WebSite\TaskManagement
SET SNSRCASSEMBLYPATH=%SNSRCBASEPATH%\Source\SenseNet\WebSite\bin

rem sql variables for database connection -- osszeakad-e a termek installerrel
SET DATASOURCE=MySenseNetContentRepositoryDatasource
SET INITIALCATALOG=TestDb

rem project variables for installation and import processes
SET SOLUTIONDIR=..\..\Source
SET PROJECTDIRNAME=WebSite
SET PROJECTPATH=%SOLUTIONDIR%\%PROJECTDIRNAME%
SET OLDSNADMINPATH=%SOLUTIONDIR%\%PROJECTDIRNAME%_Admin
SET ASSEMBLYPATH=%PROJECTPATH%\bin
SET PROJECTSTRUCTUREPATH=%PROJECTPATH%\Root
SET PROJECTADMINPATH=%PROJECTPATH%\Admin
SET PROJECTTOOLSPATH=%PROJECTPATH%\Tools
SET PROJECTTASKMANAGEMENTPATH=%PROJECTPATH%\TaskManagement

SET CONFIGSPATH=%PROJECTPATH%\configs

rem IIS setup variables
SET SITENAME=TestSite
SET APPPOOLNAME=%INITIALCATALOG%
SET APPPOOLUSER=
SET APPPOOLPSW=
SET BINDINGPORT=80
SET BINDINGTYPE=http
SET HOSTNAME=testsite
SET APPCMD=CALL %WINDIR%\system32\inetsrv\appcmd
FOR /F %%i IN ("%PROJECTPATH%") DO SET SITEPATH=%%~fi

rem config list
set config[0]=%SNSRCBASEPATH%\Source\SenseNet\WebSite\web.config
set config[1]=%SNSRCTOOLSPATH%\Import.exe.config
set config[2]=%SNSRCTOOLSPATH%\Export.exe.config
set config[3]=%SNSRCTOOLSPATH%\IndexPopulator.exe.config
set config[4]=%SNSRCTOOLSPATH%\SyncPortal2AD.exe.config
set config[5]=%SNSRCTOOLSPATH%\SyncAD2Portal.exe.config

SET PRJVARSLOADED=Yes
