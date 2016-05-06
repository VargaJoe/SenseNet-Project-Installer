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
IF EXIST %PROJECTSTRUCTUREPATH%\System\Schema (
	ECHO Contents import with CTD install
	%PROJECTTOOLSPATH%\Import.exe -SCHEMA %PROJECTSTRUCTUREPATH%\System\Schema -SOURCE %PROJECTSTRUCTUREPATH% -TARGET /Root -ASM %ASSEMBLYPATH% -TRANSFORM ExcludeFields.xslt
) ELSE (
	ECHO import only Contents
	%PROJECTTOOLSPATH%\Import.exe -SOURCE %PROJECTSTRUCTUREPATH% -TARGET /Root -ASM %ASSEMBLYPATH% -TRANSFORM ExcludeFields.xslt
)

IF NOT "%FULLINSTALL%"=="Yes" (
	ECHO ===============================================================================
	ECHO             Call Index Populating
	ECHO ===============================================================================

	call Indexpopulator.bat
)

ECHO Done.
