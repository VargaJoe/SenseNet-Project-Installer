/**
 * Converter: http://json2ts.com/
 */

declare module Settings {

    export interface DataBase {
        DataSource: string;
        InitialCatalog: string;
    }

    export interface IIS {
        WebAppName: string;
        AppPoolName: string;
        Hosts: string[];
        DotNetVersion: string;
    }

    export interface Sources {
        PackagesPath: string;
        DatabasesPath: string;
    }

    export interface Platform {
        PackageFolderPath: string;
        PackageName: string;
        SourceFolderPath: string;
        SolutionFilePath: string;
        DbBackupFilePath: string;
        SnWebFolderFilePath: string;
        SnWebFolderPath: string;
    }

    export interface Project {
        SourceFolderPath: string;
        WebFolderPath: string;
        AsmFolderPath: string;
        WebConfigFilePath: string;
        SnAdminFilePath: string;
        ToolsFolderPath: string;
        RepoFsFolderPath: string;
        DeployFolderPath: string;
        SolutionFilePath: string;
    }

    export interface Production {
        WebFolderPath: string;
        AsmFolderPath: string;
        WebConfigFilePath: string;
        SnAdminFilePath: string;
        ToolsFolderPath: string;
    }

    export interface Tools {
        VisualStudio: string;
        UnZipperFilePath: string;
        ConfigTransformationTool: string;
        NuGetSourceUrl: string;
        NuGetFolderPath: string;
        NuGetFilePath: string;
    }

    export interface Plots {
        firstinstall: string[];
        fullinstall: string[];
        updateproject: string[];
        demoinstall: string[];
        deploy: string[];
        restoresite: string[];
    }

    export interface SettingObject {
        DataBase: DataBase;
        IIS: IIS;
        Sources: Sources;
        Platform: Platform;
        Project: Project;
        Production: Production;
        Tools: Tools;
        Plots: Plots;
        Steps: string[];
    }

}

