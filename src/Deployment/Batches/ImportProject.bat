ECHO OFF

IF NOT "%PRJVARSLOADED%"=="Yes" (
	ECHO ===============================================================================
	ECHO                                Load Project Variables
	ECHO ===============================================================================

	call ProjectVariables.bat
)

ECHO ===============================================================================
ECHO             Import Project Files
ECHO ===============================================================================
IF EXIST ..\source\website\Root\System\Schema\ContentTypes\ (
	ECHO Contents import with CTD install
	%PROJECTTOOLSPATH%\Import.exe -SCHEMA %PROJECTSTRUCTUREPATH%\System\Schema -SOURCE %PROJECTSTRUCTUREPATH% -TARGET /Root -ASM %ASSEMBLYPATH% 
) ELSE (
	ECHO import only Contents
	%PROJECTTOOLSPATH%\Import.exe -SOURCE %PROJECTSTRUCTUREPATH% -TARGET /Root -ASM %ASSEMBLYPATH% 
)

IF NOT "%FULLINSTALL%"=="Yes" (
	ECHO ===============================================================================
	ECHO             Call Index Populating
	ECHO ===============================================================================

	call Indexpopulator.bat
)

ECHO Done.
