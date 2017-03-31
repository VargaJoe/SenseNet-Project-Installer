ECHO OFF

IF NOT "%PRJVARSLOADED%"=="Yes" (
	ECHO ===============================================================================
	ECHO                                Load Project Variables
	ECHO ===============================================================================

	call ProjectVariables.bat
)


IF EXIST %LUCENEDIRLOCATION%%1 (
	ECHO ===============================================================================
	ECHO                                Restore LuceneIndex
	ECHO ===============================================================================
	
	ECHO Remove read-only flags...
	attrib -r "%PROJECTAPPDATAPATH%\LuceneIndex%1\*.*" /s
	attrib -r "%PROJECTAPPDATAPATH%\BakLuceneIndex%1\*.*" /s
	attrib -r "%PROJECTAPPDATAPATH%\BakLuceneIndex_Backup%1\*.*" /s
	
	ECHO Delete backup folders...
	rmdir "%PROJECTAPPDATAPATH%\BakLuceneIndex%1\" /S /Q
	rmdir "%PROJECTAPPDATAPATH%\BakLuceneIndex_Backup%1\" /S /Q
	
	ECHO Backup local lucene folders...
	move /Y "%PROJECTAPPDATAPATH%\LuceneIndex" "%PROJECTAPPDATAPATH%\BakLuceneIndex%1" 
	move /Y "%PROJECTAPPDATAPATH%\LuceneIndex_Backup" "%PROJECTAPPDATAPATH%\BakLuceneIndex_Backup%1" 
	
	ECHO Restore lucene folders from remote backup...
	xcopy "%LUCENEDIRLOCATION%%1" "%PROJECTAPPDATAPATH%\LuceneIndex" /Y /E /I
	xcopy "%LUCENEDIRLOCATION%_Backup%1" "%PROJECTAPPDATAPATH%\LuceneIndex_Backup" /Y /E /I
) ELSE (
	IF NOT "%fullinstall%"=="yes" (
	ECHO ===============================================================================
	ECHO             				Call Index Populating
	ECHO ===============================================================================
	
	rem call indexpopulator.bat
	)
)

ECHO Done.
