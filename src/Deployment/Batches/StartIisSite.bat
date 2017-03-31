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
	ECHO                              Start IIS Site
	ECHO ===============================================================================

	ECHO start site...
	%APPCMD% start site /site.name:%SITENAME%
) ELSE (
	ECHO ===============================================================================
	ECHO                              Create IIS Site
	ECHO ===============================================================================

	call SetupIISSite.bat
)

ECHO Done.
