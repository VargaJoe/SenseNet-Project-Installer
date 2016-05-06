ECHO OFF

ECHO ===============================================================================
ECHO         Load Project Variables, Set Full Install Flag, Stop IIS Site
ECHO ===============================================================================

call ProjectVariables.bat
SET FULLINSTALL=Yes
call StopIisSite.bat

ECHO ===============================================================================
ECHO                              Call Database Restore Script
ECHO ===============================================================================

call RestoreDb.bat

rem ECHO ===============================================================================
rem ECHO             				Call Project Files Importer
rem ECHO ===============================================================================

rem call BuildProject.bat

rem ECHO ===============================================================================
rem ECHO             				Call Project Files Importer
rem ECHO ===============================================================================

rem call ImportProject.bat

IF EXIST %LUCENEDIRLOCATION% (
	ECHO ===============================================================================
	ECHO                                Restore LuceneIndex
	ECHO ===============================================================================
	
	ECHO Remove read-only flags...
	attrib -r "%PROJECTAPPDATAPATH%\LuceneIndex\*.*" /s
	attrib -r "%PROJECTAPPDATAPATH%\BakLuceneIndex\*.*" /s
	attrib -r "%PROJECTAPPDATAPATH%\BakLuceneIndex_Backup\*.*" /s
	
	ECHO Delete backup folders...
	rmdir "%PROJECTAPPDATAPATH%\BakLuceneIndex\" /S /Q
	rmdir "%PROJECTAPPDATAPATH%\BakLuceneIndex_Backup\" /S /Q
	
	ECHO Backup local lucene folders...
	move /Y "%PROJECTAPPDATAPATH%\LuceneIndex" "%PROJECTAPPDATAPATH%\BakLuceneIndex" 
	move /Y "%PROJECTAPPDATAPATH%\LuceneIndex_Backup" "%PROJECTAPPDATAPATH%\BakLuceneIndex_Backup" 
	
	ECHO Restore lucene folders from remote backup...
	xcopy "%LUCENEDIRLOCATION%" "%PROJECTAPPDATAPATH%\LuceneIndex" /Y /E /I
	xcopy "%LUCENEDIRLOCATION%_Backup" "%PROJECTAPPDATAPATH%\LuceneIndex_Backup" /Y /E /I
) ELSE (
	IF NOT "%fullinstall%"=="yes" (
	ECHO ===============================================================================
	ECHO             				Call Index Populating
	ECHO ===============================================================================
	
	call indexpopulator.bat
	)
)

ECHO ===============================================================================
ECHO             				IIS And Hosts File Setup
ECHO ===============================================================================

call StartIisSite.bat
call SetupHostFile.bat

ECHO ===============================================================================
ECHO 							Clear Full Install Flag 
ECHO ===============================================================================

SET PRJVARSLOADED=No

ECHO Done.
