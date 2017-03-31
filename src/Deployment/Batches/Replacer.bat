@ECHO OFF

IF NOT "%PRJVARSLOADED%"=="Yes" GOTO :LOAD
IF NOT "%NESTEDLOOP%"=="Yes" GOTO :LOAD
GOTO :SKIP
:LOAD
ECHO ===============================================================================
ECHO                                Load Project Variables
ECHO ===============================================================================

call ProjectVariables.bat

ECHO ===============================================================================
ECHO          						Replace Values 
ECHO ===============================================================================
:SKIP

SET FROM=%1

IF [%2] == [] (
	FOR %%F IN ("%FROM%") DO SET CONFIGNAME=%%~nxF
	SET TO=!CONFIGSPATH!\!CONFIGNAME!
)  ELSE (
	SET TO=%2
)

SET SEARCHTEXT1=MySenseNetContentRepositoryDatasource;
SET REPLACETEXT1=%DATASOURCE%;

SET SEARCHTEXT2=SenseNetContentRepository;
SET REPLACETEXT2=%INITIALCATALOG%;

IF [%TO%] == [] GOTO:EOF
IF EXIST %TO% DEL %TO%

ECHO %TO% processing...
SETLOCAL DISABLEDELAYEDEXPANSION
for /f "tokens=1,* delims=¶" %%A in ( '"type %FROM%"') do (
	SET line=%%A
	SETLOCAL ENABLEDELAYEDEXPANSION
	SET line=!line:%SEARCHTEXT1%=%REPLACETEXT1%!
	SET line=!line:%SEARCHTEXT2%=%REPLACETEXT2%!
	rem ECHO !line! >> !TO!
	>> %TO% echo(!line!
	ENDLOCAL
)

ENDLOCAL

ECHO done!