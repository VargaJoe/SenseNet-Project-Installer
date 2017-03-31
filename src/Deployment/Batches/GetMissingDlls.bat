@ECHO OFF

IF NOT "%PRJVARSLOADED%"=="Yes" GOTO :LOAD
IF NOT "%FULLINSTALL%"=="Yes" GOTO :LOAD
GOTO :SKIP
:LOAD
ECHO ===============================================================================
ECHO                                Load Project Variables
ECHO ===============================================================================

call ProjectVariables.bat
:SKIP

ECHO ===============================================================================
ECHO             					Copy GAC Dlls to Project Bin
ECHO ===============================================================================

xcopy %REFERENCESFOLDER%\Missing\*.dll %ASSEMBLYPATH% /Y /I
