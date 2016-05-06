ECHO OFF

IF NOT "%PRJVARSLOADED%"=="Yes" (
	ECHO ===============================================================================
	ECHO                                Load Project Variables
	ECHO ===============================================================================

	call ProjectVariables.bat
)

ECHO ===============================================================================
ECHO             					Copy Base Configs
ECHO ===============================================================================

attrib -r "%PROJECTPATH%\Web.config"
attrib -r "%CONFIGSPATH%\*.*" /s
attrib -r "%PROJECTADMINPATH%\*.*" /s
attrib -r "%PROJECTTOOLSPATH%\*.*" /s
attrib -r "%PROJECTPATH%\TaskManagement\*.*" /s

ECHO ===============================================================================
ECHO             					Copy Base Assemblies
ECHO ===============================================================================

xcopy "%SNSRCASSEMBLYPATH%\*.dll" "%ASSEMBLYPATH%" /Y /I
xcopy "%SNSRCASSEMBLYPATH%\*.exe" "%ASSEMBLYPATH%" /Y

xcopy "%SNSRCTOOLSPATH%" "%PROJECTTOOLSPATH%" /Y /E /I
xcopy "%SNSRCADMINPATH%" "%PROJECTADMINPATH%" /Y /E /I
xcopy "%SNSRCTASKMANAGEMENTPATH%" "%PROJECTTASKMANAGEMENTPATH%" /Y /E /I


ECHO ===============================================================================
ECHO             					Copy Custom Configs
ECHO ===============================================================================

xcopy "%CONFIGSPATH%\Import.exe.config"  "%PROJECTTOOLSPATH%" /Y
xcopy "%CONFIGSPATH%\Export.exe.config"  "%PROJECTTOOLSPATH%" /Y
xcopy "%CONFIGSPATH%\Indexpopulator.exe.config"  "%PROJECTTOOLSPATH%" /Y
xcopy "%CONFIGSPATH%\SyncAD2Portal.exe.config"  "%PROJECTTOOLSPATH%" /Y
xcopy "%CONFIGSPATH%\SyncPortal2AD.exe.config"  "%PROJECTTOOLSPATH%" /Y

xcopy "%CONFIGSPATH%\Web.config"  "%PROJECTPATH%" /Y


ECHO Done.
