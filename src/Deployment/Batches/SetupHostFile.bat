ECHO OFF

IF NOT "%PRJVARSLOADED%"=="Yes" GOTO :LOAD
IF NOT "%FULLINSTALL%"=="Yes" GOTO :LOAD
GOTO :SKIP
:LOAD
ECHO ===============================================================================
ECHO                                Load Project Variables
ECHO ===============================================================================

call ProjectVariables.bat
:SKIP

ECHO ===============================================================================
ECHO             				Check If Host Record Is Prepared
ECHO ===============================================================================

@ECHO OFF

SET HOSTSPATH=%WINDIR%\System32\drivers\etc\hosts
SET NEWLINE=^& echo.

FIND /C /I "%HOSTNAME%" %HOSTSPATH%
IF %ERRORLEVEL% NEQ 0 (
	ECHO %NEWLINE%>>%HOSTSPATH% 
	ECHO 127.0.0.1 	%HOSTNAME%>>%HOSTSPATH%
) ELSE (
	ECHO %HOSTNAME% host ALREADY EXISTS 
)

ipconfig /flushdns

ECHO Done.
