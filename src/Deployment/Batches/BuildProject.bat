@ECHO OFF

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
ECHO            					Build Project Solution
ECHO ===============================================================================

for /f "tokens=3*" %%x in ('reg query "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\App Paths\devenv.exe"') do set DEVENV="%%x %%y"
set DEVENV=%DEVENV:exe=com%
ECHO az utvonal: %DEVENV%
%DEVENV% %SOLUTIONDIR%\Project.sln /rebuild

@ECHO ON


