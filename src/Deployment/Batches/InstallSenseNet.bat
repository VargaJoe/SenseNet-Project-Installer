ECHO OFF

IF NOT "%PRJVARSLOADED%"=="Yes" (
	ECHO ===============================================================================
	ECHO                                Load Project Variables
	ECHO ===============================================================================

	call ProjectVariables.bat
)

ECHO ===============================================================================
ECHO                              Call Install Sense/Net 
ECHO ===============================================================================

attrib -r "%SNSRCTOOLSPATH%\Import.exe.config"
xcopy "%CONFIGSPATH%\Import.exe.config"  "%SNSRCTOOLSPATH%" /Y

attrib -r "%SNSRCTOOLSPATH%\Indexpopulator.exe.config"
xcopy "%CONFIGSPATH%\Indexpopulator.exe.config"  "%SNSRCTOOLSPATH%" /Y

PUSHD %SNSRCBASEPATH%\Deployment
call InstallSenseNet.bat DATASOURCE:%DATASOURCE% INITIALCATALOG:%INITIALCATALOG%
POPD


IF NOT "%FULLINSTALL%"=="Yes" (
	ECHO ===============================================================================
	ECHO             Call Index Populating
	ECHO ===============================================================================
	
	call Indexpopulator.bat
)

ECHO Done.
