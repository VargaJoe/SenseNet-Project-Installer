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
ECHO             					Copy Necessary Files 
ECHO ===============================================================================

attrib -r %ASSEMBLYPATH%\Import.exe 
attrib -r %ASSEMBLYPATH%\Export.exe 
attrib -r %ASSEMBLYPATH%\Indexpopulator.exe 
attrib -r %ASSEMBLYPATH%\LiveExportImport.dll 
xcopy %SNTOOLSPATH%\Import.exe %ASSEMBLYPATH% /Y
xcopy %SNTOOLSPATH%\Export.exe %ASSEMBLYPATH% /Y
xcopy %SNTOOLSPATH%\Indexpopulator.exe %ASSEMBLYPATH% /Y
xcopy %CUCTOMFERENCESPATH%\LiveExportImport.dll %ASSEMBLYPATH% /Y