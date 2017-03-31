ECHO OFF

Rem ================================== Important Note!
Rem #1 Before running this batch file 
Rem Check the connectionstrings section of the Import tool.

ECHO ===============================================================================
ECHO         Load Project Variables, Set Full Install Flag, Stop IIS Site
ECHO ===============================================================================

call ProjectVariables.bat
SET FULLINSTALL=Yes
call StopIisSite.bat

ECHO ===============================================================================
ECHO                              Call Database Restore Script
ECHO ===============================================================================

call RestoreDb.bat %1

ECHO ===============================================================================
ECHO                              Call LuceneIndex Script
ECHO ===============================================================================

call RestoreLucene.bat %1

ECHO ===============================================================================
ECHO             				IIS And Hosts File Setup
ECHO ===============================================================================

call StartIisSite.bat
call SetupHostFile.bat

ECHO ===============================================================================
ECHO 							Clear Full Install Flag 
ECHO ===============================================================================

SET PRJVARSLOADED=No

ECHO Done.
