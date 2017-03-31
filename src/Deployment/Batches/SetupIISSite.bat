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
ECHO             					Check If IIS Site Exists 
ECHO ===============================================================================

@ECHO OFF

%APPCMD% list apppool /name:%APPPOOLNAME%
IF "%ERRORLEVEL%" EQU "0" (
    ECHO %APPPOOLNAME% application pool ALREADY EXISTS
) ELSE (
    ECHO NOT EXISTS
	ECHO %SITEPATH%
	%APPCMD% add apppool /name:%APPPOOLNAME% /managedRuntimeVersion:"v4.0" /managedPipelineMode:"Integrated" /processmodel.identityType:SpecificUser 
	IF %ERRORLEVEL% NEQ 0 ECHO application pool added
)


%APPCMD% list site /name:%SITENAME%
IF "%ERRORLEVEL%" EQU "0" (
    ECHO %SITENAME% site ALREADY EXISTS
) ELSE (
    ECHO NOT EXISTS
	ECHO %SITEPATH%
	%APPCMD% add site /name:%SITENAME% /physicalPath:"%SITEPATH%" /bindings:%BINDINGTYPE%://%HOSTNAME%:%BINDINGPORT% 
	%APPCMD% set site /site.name:%SITENAME% /[path='/'].applicationPool:%APPPOOLNAME%
	IF %ERRORLEVEL% NEQ 0 ECHO site added
)

ECHO Done.
