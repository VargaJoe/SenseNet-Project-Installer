ECHO OFF

Rem ================================== Important Note!
Rem #1 Before running this batch file 
Rem Check the connectionstrings section of the Import tool.

IF NOT "%PRJVARSLOADED%"=="Yes" (
	ECHO ===============================================================================
	ECHO                                Load Project Variables
	ECHO ===============================================================================

	call ProjectVariables.bat
)

ECHO ===============================================================================
ECHO                              Install Sense/Net 6.0 
ECHO ===============================================================================

Echo.

ECHO ===============================================================================
ECHO                                Install Database
ECHO ===============================================================================

ECHO Creating database...

sqlcmd.exe -S %DATASOURCE% -i "%SNSRCDBSCRIPTSPATH%\Create_SenseNet_Database.sql" -v dbname = %INITIALCATALOG%
sqlcmd.exe -S %DATASOURCE% -d %INITIALCATALOG% -i "%SNSRCDBSCRIPTSPATH%\Install_01_Schema.sql"
sqlcmd.exe -S %DATASOURCE% -d %INITIALCATALOG% -i "%SNSRCDBSCRIPTSPATH%\Install_02_Procs.sql"
sqlcmd.exe -S %DATASOURCE% -d %INITIALCATALOG% -i "%SNSRCDBSCRIPTSPATH%\Install_03_Data_Phase1.sql"
sqlcmd.exe -S %DATASOURCE% -d %INITIALCATALOG% -i "%SNSRCDBSCRIPTSPATH%\Install_04_Data_Phase2.sql"
sqlcmd.exe -S %DATASOURCE% -d %INITIALCATALOG% -i "%SNSRCDBSCRIPTSPATH%\Install_TaskDatabase_Schema.sql"

ECHO ===============================================================================
ECHO			         Install Workflow Store
ECHO ===============================================================================

sqlcmd.exe -S %DATASOURCE% -d %INITIALCATALOG% -i "%SNSRCDBSCRIPTSPATH%\SqlWorkflowInstanceStoreSchema.sql"
sqlcmd.exe -S %DATASOURCE% -d %INITIALCATALOG% -i "%SNSRCDBSCRIPTSPATH%\SqlWorkflowInstanceStoreLogic.sql"


ECHO ===============================================================================
ECHO             Install FieldConfig and ContentTypes, Import Demo Files
ECHO ===============================================================================

"%PROJECTTOOLSPATH%\Import.exe" -SCHEMA "%DEFAULTSTRUCTUREPATH%\System\Schema" -SOURCE "%DEFAULTSTRUCTUREPATH%" -TARGET /Root -ASM "%ASSEMBLYPATH%" 
sqlcmd.exe -S %DATASOURCE% -d %INITIALCATALOG% -i "%SNSRCDBSCRIPTSPATH%\Install_05_Data_Phase3.sql"

IF NOT "%FULLINSTALL%"=="Yes" (
	ECHO ===============================================================================
	ECHO             Call Index Populating
	ECHO ===============================================================================



	call Indexpopulator.bat
)

ECHO Done.
