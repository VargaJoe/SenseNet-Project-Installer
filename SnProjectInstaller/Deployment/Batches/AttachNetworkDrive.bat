ECHO OFF

IF NOT "%PRJVARSLOADED%"=="Yes" (
	ECHO ===============================================================================
	ECHO                                Load Project Variables
	ECHO ===============================================================================

	call ProjectVariables.bat
)

ECHO attach network drive...
net use x: %DBBAKREMOTEFOLDERLOCATION%

ECHO Done.
