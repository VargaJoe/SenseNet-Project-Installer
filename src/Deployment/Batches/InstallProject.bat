ECHO OFF

Rem ================================== Important Note!
Rem #1 Before running this batch file 
Rem Check the connectionstrings section of the Import tool.

ECHO ===============================================================================
ECHO         Load Project Variables, Set Full Install Flag, Initiate Sn Files
ECHO ===============================================================================

call ProjectVariables.bat
SET FULLINSTALL=Yes
rem call InitiateSnFiles.bat 		rem extract packages
call BuildSnPackage.bat 		rem get basic webstructures and assemblies
call GetBaseConfigs.bat 		rem create custom configs by basic package configs and predefined variables
call InitiateAssemblies.bat 	rem copy base assemblies from package and configs from custom configs
call UpdateReferences.bat 		rem update core references for project solution

ECHO ===============================================================================
ECHO                              Call Sense/Net 6.0 Installer
ECHO ===============================================================================

call InstallSenseNet.bat

rem ECHO ===============================================================================
rem ECHO             				Call Admin User Importer
rem ECHO ===============================================================================

rem call ImportAdminUsers.bat

ECHO ===============================================================================
ECHO             		Call Live Export / Import Tool Importer
ECHO ===============================================================================

call ImportLiveFeature.bat

ECHO ===============================================================================
ECHO             				Call Project Files Importer
ECHO ===============================================================================

call BuildProject.bat


rem ECHO ===============================================================================
rem ECHO             				Call Project Files Importer
rem ECHO ===============================================================================

rem call ImportProject.bat

ECHO ===============================================================================
ECHO             				Call Index Populating
ECHO ===============================================================================

call Indexpopulator.bat

ECHO ===============================================================================
ECHO             				IIS And Hosts File Setup
ECHO ===============================================================================

call SetupIISSite.bat
call SetupHostFile.bat

ECHO ===============================================================================
ECHO 							Clear Full Install Flag 
ECHO ===============================================================================

SET PRJVARSLOADED=No

ECHO Done.
