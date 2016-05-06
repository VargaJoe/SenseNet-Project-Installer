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
ECHO             					Process Configs From Array 
ECHO ===============================================================================

SET NESTEDLOOP=Yes
FOR /F "DELIMS=[=] TOKENS=1,2,3" %%K IN ('SET CONFIG[') DO (
	SETLOCAL ENABLEDELAYEDEXPANSION
	SET INPUT=%%M
	CALL ReplacerWithXslt.bat !INPUT!
	ENDLOCAL
)

@ECHO ON