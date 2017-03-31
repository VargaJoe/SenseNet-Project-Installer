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
%PROJECTTOOLSPATH%\Import.exe -SOURCE ..\UsersStructure -TARGET /Root -ASM %ASSEMBLYPATH% 

IF NOT "%FULLINSTALL%"=="Yes" (
	ECHO ===============================================================================
	ECHO             Call Index Populating
	ECHO ===============================================================================

	call Indexpopulator.bat
)


ECHO Done.
