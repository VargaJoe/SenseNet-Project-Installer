ECHO OFF

IF NOT "%PRJVARSLOADED%"=="Yes" (
	ECHO ===============================================================================
	ECHO                                Load Project Variables
	ECHO ===============================================================================

	call ProjectVariables.bat
)

ECHO ===============================================================================
ECHO             					Unzip SenseNet Files
ECHO ===============================================================================

rem %INSTALLERTOOLSFOLDER%\7zip\7za.exe x %SNRELEASESPATH%\%SNWEBPINAME%.zip -o%SNRELEASESPATH%\%SNWEBPINAME% -y >Log1.txt 2>&1
%INSTALLERTOOLSFOLDER%\7zip\7za.exe x %SNRELEASESPATH%\%SNSRCNAME%.zip -o%SNRELEASESPATH%\%SNSRCNAME% -y >Log2.txt 2>&1

ECHO Done.
