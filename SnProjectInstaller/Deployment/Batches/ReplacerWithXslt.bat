ECHO OFF

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

ECHO From: %FROM% processing...
%INSTALLERTOOLSFOLDER%\MsXml\msxsl.exe %FROM% ConfigSetter.xslt -o %TO% srv=%DATASOURCE% ctg=%INITIALCATALOG% url=%HOSTNAME%
ECHO To: %TO% ...done!
ECHO .