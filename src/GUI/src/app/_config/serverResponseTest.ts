const serverResponseTestJSON = {
    "Source": {
       "PackagesPath": "..\\Packages\\",
       "PackageFolderPath": "",
       "PackageName": "",
       "SourceFolderPath": "",
       "SolutionFilePath": "",
       "DbBackupFilePath": "..\\Databases\\project-latest.bak",
       "DatabasesPath": "..\\Databases\\",
       "SnWebFolderFilePath": "..\\Archives\\project-Web710.zip",
       "SnWebFolderPath": ""
    },
    "Project": {
       "DataSource": "MySenseNetContentRepositoryDatasource",
       "InitialCatalog": "project",
       "WebAppName": "project",
       "AppPoolName": "project",
       "Hosts": [
          "project",
          "sn7.sn.hu"
       ],
       "DotNetVersion": "v4.0",
       "SourceFolderPath": "..\\..\\",
       "WebFolderPath": "..\\..\\Source\\WebSite",
       "AsmFolderPath": "..\\..\\Source\\WebSite\\bin",
       "WebConfigFilePath": "..\\..\\Source\\WebSite\\web.config",
       "SnAdminFilePath": "..\\..\\Source\\WebSite\\Admin\\bin\\snadmin.exe",
       "ToolsFolderPath": "..\\..\\Source\\WebSite\\Tools",
       "SnAdminRCFilePath": "..\\..\\Source\\WebSite\\Tools\\SnAdminRuntime.exe.config",
       "RepoFsFolderPath": "..\\..\\Source\\WebSite\\Root",
       "DeployFolderPath": "..\\..\\Source\\WebSite\\deploy",
       "SolutionFilePath": "..\\..\\Source\\Project.sln"
    },
    "Production": {
       "DataSource": "MySenseNetContentRepositoryDatasource",
       "InitialCatalog": "projectlive",
       "WebAppName": "projectlive",
       "AppPoolName": "projectlive",
       "Hosts": [
          "projectlive"
       ],
       "DotNetVersion": "v4.0",
       "WebFolderPath": "D:\\web\\projectlivewebfolder",
       "AsmFolderPath": "D:\\web\\projectlivewebfolder\\bin",
       "WebConfigFilePath": "D:\\web\\projectlivewebfolder\\web.config",
       "SnAdminFilePath": "D:\\web\\projectlivewebfolder\\Admin\\bin\\snadmin.exe",
       "ToolsFolderPath": "D:\\web\\projectlivewebfolder\\Tools",
       "SnAdminRCFilePath": "D:\\web\\projectlivewebfolder\\Tools\\SnAdminRuntime.exe.config"
    },
    "Plots": {
       "fullinstall": [
          "stop",
          "getlatest",
          "restorepckgs",
          "prbuild",
          "sninstall",
          "removedemo",
          "adminusers",
          "prinstall",
          "setrepourl",
          "createsite",
          "sethost",
          "start"
       ],
       "updateproject": [
          "stop",
          "getlatest",
          "restorepckgs",
          "prbuild",
          "prinstall",
          "setrepourl",
          "start"
       ],
       "demoinstall": [
          "restorepckgs",
          "prbuild",
          "sninstall",
          "createsite",
          "sethost",
          "start"
       ],
       "restorelocal": [
          "stop",
          "restoredb",
          "prindex",
          "setrepourl",
          "createsite",
          "sethost",
          "start"
       ],
       "TestPlot": ["stop", "start"],
       "projectbackup": [
          "stop",
          "backupdb",
          "start"
       ],
       "fulldeploy": [
          "stop:Production",
          "restoredb:Production",
          "deploywebfolder:Production",
          "setconnection:Production",
          "prindex:Production",
          "setrepourl:Production",
          "createsite:Production",
          "sethost:Production",
          "start:Production"
       ]
    },
    "Tools": {
       "VisualStudio": "C:\\Program Files (x86)\\Microsoft Visual Studio\\2017\\Enterprise\\Common7\\IDE\\CommonExtensions\\Microsoft\\TeamFoundation\\Team Explorer\\tf.exe",
       "UnZipperFilePath": "C:\\Program Files\\7-Zip\\7z.exe",
       "ConfigTransformationTool": "..\\Tools\\CTT\\ctt.exe",
       "NuGetSourceUrl": "https://dist.nuget.org/win-x86-commandline/latest/nuget.exe",
       "NuGetFolderPath": "..\\Tools\\nuget",
       "NuGetFilePath": "..\\Tools\\nuget\\nuget.exe"
    },
    "Steps": [
       "Test",
       "Stop",
       "Start",
       "GetLatest",
       "RestorePckgs",
       "PrBuild",
       "SnInstall",
       "SnServices",
       "SnWebPages",
       "RemoveDemo",
       "AdminUsers",
       "PrInstall",
       "CreateSite",
       "SetHost",
       "DeployWebFolder",
       "PrIndex",
       "PrImport",
       "PrExport",
       "CreatePackage",
       "SetRepoUrl",
       "BackupDb",
       "AutoBackupDb",
       "RestoreDb",
       "DropDb",
       "SetConfigs",
       "GetSettings",
       "SetConnection",
       "PrToProdAsm"
    ]
 };
export default serverResponseTestJSON;
