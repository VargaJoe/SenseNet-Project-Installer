# Configuration Settings

Configuration in Plot Manager is handled through JSON settings files that define environment-specific parameters, plot definitions, and operational settings. The framework uses a layered configuration approach where project-specific settings override default configurations.

## Settings File Structure

### Default Configuration Files
- **`project-default.json`**: Contains base settings and common plot definitions
- **`project-local.json`**: Local development environment overrides
- **Environment-specific files**: Custom configurations for different deployment targets

### Configuration Merging
When executing plots, the framework merges configurations in this order:
1. Load default settings from `project-default.json`
2. Load environment-specific settings (e.g., `project-local.json`)
3. Project settings override default settings where conflicts exist
4. Environment variables with `PLOTMANAGER_` prefix override any setting

## Configuration Sections

### Plots Section
Defines automation scenarios as sequences of steps:

```json
{
  "Plots": {
    "fullinstall": [
      "stop", 
      "restorepckgs", 
      "prbuild", 
      "dropdb", 
      "snservices", 
      "createsite", 
      "start"
    ],
    "backup": [
      "stop",
      "backupdb", 
      "start"
    ]
  }
}
```

**Step Syntax**: Steps can include section targeting using colon notation:
- `"index"`: Execute step with default section
- `"index:TestSite"`: Execute step using "TestSite" configuration section

### Source Section
Defines resource locations and shared paths independent of specific environments:

```json
{
  "Source": {
    "PackagesPath": "..\\Packages",
    "DbBackupFilePath": "..\\Databases\\project-latest.bak",
    "DatabasesPath": "..\\Databases\\",
    "VsTemplatesRepo": "https://github.com/SenseNet/sn-vs-projecttemplates",
    "TemplatesBranch": "master",
    "SnWebFolderFilePath": "..\\Archives\\project-Web.zip"
  }
}
```

### Project Section
The default configuration section for most steps, typically containing local development settings:

```json
{
  "Project": {
    "DataSource": "MySenseNetContentRepositoryDatasource",
    "InitialCatalog": "sensenetdb",
    "WebAppName": "sensenetapp",
    "AppPoolName": "sensenetapp",
    "Hosts": ["sensenet.local"],
    "DotNetVersion": "v4.0",
    "WebFolderPath": "..\\WebApplication",
    "AsmFolderPath": "..\\WebApplication\\bin",
    "WebConfigFilePath": "..\\WebApplication\\web.config"
  }
}
```

## Common Configuration Properties

### Database Settings
- **`DataSource`**: SQL Server instance name or connection string
- **`InitialCatalog`**: Database name
- **`UserName`**: SQL Server authentication username (optional)
- **`UserPsw`**: SQL Server authentication password (optional)

### Application Settings  
- **`WebAppName`**: IIS site name
- **`AppPoolName`**: IIS application pool name
- **`DotNetVersion`**: .NET Framework version (e.g., "v4.0")
- **`Hosts`**: Array of hostnames for local development

### File System Paths
- **`WebFolderPath`**: Web application root directory
- **`AsmFolderPath`**: Binary assemblies directory (typically bin/)
- **`ToolsFolderPath`**: Utilities and tools directory
- **`SolutionFilePath`**: Visual Studio solution file path

### SenseNet-Specific Settings
- **`SnAdminFilePath`**: Path to snadmin.exe utility
- **`IndexerPath`**: Path to index populator executable
- **`RepoFsFolderPath`**: Repository content import directory
- **`DeployFolderPath`**: Deployment manifest directory

## Environment-Specific Sections

Create custom sections for different deployment targets:

```json
{
  "Production": {
    "DataSource": "prod-sql-server",
    "InitialCatalog": "ProductionDB",
    "WebAppName": "ProductionSite",
    "MachineName": "PROD-SERVER-01"
  },
  "Staging": {
    "DataSource": "staging-sql-server", 
    "InitialCatalog": "StagingDB",
    "WebAppName": "StagingSite"
  }
}
```

## Tools Section
Defines paths to external utilities used by various steps:

```json
{
  "Tools": {
    "VisualStudio": "C:\\Program Files\\Microsoft Visual Studio\\2019\\Professional\\Common7\\IDE\\CommonExtensions\\Microsoft\\TeamFoundation\\Team Explorer\\tf.exe",
    "UnZipperFilePath": "C:\\Program Files\\7-Zip\\7z.exe",
    "NuGetFilePath": "..\\Tools\\nuget\\nuget.exe"
  }
}
```

## Environment Variable Overrides

Any configuration setting can be overridden using environment variables with the `PLOTMANAGER_` prefix:

```powershell
# Override database settings
$env:PLOTMANAGER_DataSource = "new-sql-server"
$env:PLOTMANAGER_InitialCatalog = "NewDatabase"

# Override application settings  
$env:PLOTMANAGER_WebAppName = "TestApplication"
```

## Best Practices

### Security
- Store sensitive data like passwords in environment variables rather than configuration files
- Use SQL Server integrated authentication when possible
- Protect configuration files with appropriate file system permissions

### Organization
- Keep environment-specific settings separate from shared configurations
- Use descriptive section names without special characters or spaces
- Document custom configuration properties and their purpose

### Maintenance
- Regularly validate configuration paths and ensure tools are accessible
- Test configurations across all target environments
- Version control configuration files but exclude sensitive data