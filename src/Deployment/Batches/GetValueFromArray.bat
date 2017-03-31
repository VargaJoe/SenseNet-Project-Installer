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
ECHO             					Get Value From Array with Index
ECHO ===============================================================================
:SKIP

SET ARRAYNAME=%1
SET ARRAYINDEX=%2
set OUTVARNAME=%3

REM ECHO NAME: %ARRAYNAME%
REM ECHO INDEX: %ARRAYINDEX%


for /f "delims=[=] tokens=1,2,3" %%a in ('set %ARRAYNAME%[') do (
	if %%b==%ARRAYINDEX% set %OUTVARNAME%=%%c
)

REM ECHO VAR: %OUTVARNAME%
REM ECHO VALUE: %OUTPUT%