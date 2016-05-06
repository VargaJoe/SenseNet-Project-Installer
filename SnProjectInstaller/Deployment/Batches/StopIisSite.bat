ECHO OFF

IF NOT "%PRJVARSLOADED%"=="Yes" (
	ECHO ===============================================================================
	ECHO                                Load Project Variables
	ECHO ===============================================================================

	call ProjectVariables.bat
)

%APPCMD% list apppool /name:%APPPOOLNAME%
IF "%ERRORLEVEL%" EQU "0" (
	ECHO ===============================================================================
	ECHO                              Stop IIS Site
	ECHO ===============================================================================

	ECHO stop site...
    %APPCMD% stop site /site.name:%SITENAME%
)

ECHO Done.
