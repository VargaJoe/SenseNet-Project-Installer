ECHO OFF

IF NOT "%PRJVARSLOADED%"=="Yes" (
	ECHO ===============================================================================
	ECHO                                Load Project Variables
	ECHO ===============================================================================

	call ProjectVariables.bat
)

ECHO ===============================================================================
ECHO                                Restore Database
ECHO ===============================================================================
Echo.

ECHO restoring database...
sqlcmd.exe -S %DATASOURCE% -E -Q "RESTORE DATABASE %INITIALCATALOG% FROM DISK='%BACKUPREMOTEFOLDERLOCATION%\%DBBAKFILENAME%' WITH REPLACE, MOVE '%ROWSDATANAME%' TO '%SQLDATAPATH%%ROWSDATANAME%.mdf', MOVE '%LOGNAME%' TO '%SQLDATAPATH%%LOGNAME%.ldf'"

ECHO Done.
