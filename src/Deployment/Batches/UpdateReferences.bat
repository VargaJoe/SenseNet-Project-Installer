rem ECHO OFF

IF NOT "%PRJVARSLOADED%"=="Yes" (
	ECHO ===============================================================================
	ECHO                                Load Project Variables
	ECHO ===============================================================================

	call ProjectVariables.bat
)

ECHO ===============================================================================
ECHO             					Release Core Assemblies
ECHO ===============================================================================

attrib -r %COREREFERENCESPATH%\*.* /s

ECHO ===============================================================================
ECHO             					Copy Core Assemblies
ECHO ===============================================================================

xcopy "%SNSRCASSEMBLYPATH%\*.dll" "%COREREFERENCESPATH%" /Y /I
xcopy "%SNSRCASSEMBLYPATH%\*.exe" "%COREREFERENCESPATH%" /Y

ECHO Done.
