# Plot Manager - Automation Framework

> **A comprehensive PowerShell-based automation framework for operational task management and deployment orchestration.**

## Overview

Plot Manager is a sophisticated automation framework that orchestrates complex operational tasks through a flexible plot/step architecture. Originally developed for SenseNet CMS deployments, it has evolved into a general-purpose automation platform capable of managing diverse operational workflows including containerized deployments, cloud automation, and enterprise application lifecycle management.

## Core Concepts

**Plot Manager** uses a simple but powerful paradigm:
- **Plots**: Predefined scenarios that execute a sequence of steps
- **Steps**: Individual PowerShell functions that perform specific tasks  
- **Settings**: JSON-based configuration supporting multiple environments
- **Modules**: Auto-loaded PowerShell modules that extend functionality

This architecture enables complex automation workflows to be composed from reusable components, making it easy to create, maintain, and extend operational processes.

## Key Capabilities

### Infrastructure & Deployment
- **IIS Management**: Complete website and application pool lifecycle
- **Database Operations**: SQL Server database creation, backup, restore with authentication support
- **Container Orchestration**: Docker container management and networking
- **Cloud Deployment**: Azure Web App deployment automation
- **SSL/TLS Management**: Certificate creation and configuration

### Development & Build Support  
- **Solution Building**: Visual Studio solution compilation and artifact creation
- **Package Management**: NuGet package restoration and dependency resolution
- **Source Control**: TFS/Git integration for code retrieval
- **.NET Core & Framework**: Support for both modern .NET Core and traditional .NET Framework

### SenseNet CMS Automation
- **Content Management**: Import/export of content and configurations
- **Search Indexing**: Lucene index population and management  
- **Site Provisioning**: Complete SenseNet site setup and configuration
- **Package Deployment**: SnAdmin package installation and management

### Environment Management
- **Configuration**: JSON-based settings with environment variable override
- **Host Management**: Local host file configuration for development
- **Network Operations**: Port management and firewall configuration
- **Multi-Environment**: Support for local, staging, and production deployments

## Prerequisites

### Core Requirements
1. **PowerShell 5.1+**: The automation engine requires PowerShell with script execution enabled
   ```powershell
   Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
   ```

2. **Administrator Privileges**: Many operations require elevated permissions for system configuration

3. **SqlServer PowerShell Module**: Required for database operations
   ```powershell
   Install-Module -Name SqlServer -Force -AllowClobber
   ```

### Optional Components (Based on Usage)
- **Visual Studio**: Required for solution building and TFS integration
- **Microsoft SQL Server**: For database-related operations
- **IIS**: For web application deployment
- **Docker**: For containerized deployment scenarios  
- **7-Zip**: For archive extraction operations
- **Azure CLI**: For Azure deployment automation

### Environment Configuration
The framework requires proper configuration through JSON settings files that define:
- Database connection strings and authentication
- File system paths for applications and tools
- Environment-specific deployment targets
- Network and security configurations

## Quick Start

### Basic Usage
Execute a predefined plot with default settings:
```powershell
.\Run.ps1 fullinstall
```

### Advanced Usage
Specify custom settings and sections:
```powershell
.\Run.ps1 -Plot fullinstall -Settings production -Verbose
```

### Available Commands
List available plots:
```powershell
.\Run.ps1 -Help plots
```

List available steps:  
```powershell
.\Run.ps1 -Help steps
```

Execute individual steps:
```powershell
.\Run.ps1 -Step createdb:production
```

## Architecture

### Core Components
- **`Run.ps1`**: Main entry point and orchestration engine
- **`AutoExt/`**: Auto-loaded PowerShell modules containing step definitions
- **`Settings/`**: JSON configuration files for different environments
- **`Deploy/`, `Dev/`, `Ops/`**: Specialized script collections
- **`Tools/`**: External utilities and dependencies

### Execution Flow
1. **Initialization**: Load configuration and modules from `AutoExt/` directory
2. **Configuration Merge**: Combine default and environment-specific settings
3. **Plot Resolution**: Resolve plot name to sequence of steps
4. **Step Execution**: Execute each step with appropriate error handling
5. **Result Reporting**: Return execution status and optional JSON results

### Extension Model
Add custom functionality by creating PowerShell modules in the `AutoExt/` directory:
```powershell
Function Step-CustomOperation {
    [CmdletBinding(SupportsShouldProcess=$True)]
    Param([Parameter(Mandatory=$false)][string]$Section="Project")
    
    try {
        # Your custom logic here
        $script:Result = 0
    }
    catch {
        $script:Result = 1
    }
}
```

## Example Plots

### SenseNet CMS Deployment
Complete SenseNet installation from scratch:
```powershell
.\Run.ps1 fullinstall
```
**Steps**: Get templates → Restore packages → Build → Deploy → Create database → Install services → Configure → Start

### Container Deployment  
Containerized application deployment:
```powershell
.\Run.ps1 netcoredockertest
```
**Steps**: Container setup → Database creation → Build images → Deploy containers → Network configuration

### Production Deployment
Deploy to production environment:
```powershell
.\Run.ps1 fulldeploy -Settings production
```
**Steps**: Stop services → Build → Deploy → Database update → Restart services

### Backup Operations
Database backup with site management:
```powershell
.\Run.ps1 backup
```
**Steps**: Stop site → Backup database → Restart site

## Configuration

### Settings Files
- **`project-default.json`**: Base configuration and common plots
- **`project-local.json`**: Local development overrides  
- **`project-production.json`**: Production environment settings
- **Custom settings**: Create environment-specific configurations as needed

### Environment Variables
Override any setting using environment variables with `PLOTMANAGER_` prefix:
```powershell
$env:PLOTMANAGER_DataSource = "production-sql-server"
$env:PLOTMANAGER_InitialCatalog = "ProductionDB"
```

### JSON Structure
```json
{
  "Plots": {
    "myplot": ["step1", "step2:section", "step3"]
  },
  "Project": {
    "DataSource": "localhost",
    "InitialCatalog": "mydb",
    "WebAppName": "myapp"
  },
  "CustomSection": {
    "DataSource": "remote-server"
  }
}
```

## Documentation

### User Guides
- [How to Execute Plots](/docs/how-to-execute-a-plot.md) - Comprehensive guide to running automation scenarios
- [Step Execution](/docs/how-to-execute-steps.md) - Running individual automation steps
- [Configuration Guide](/docs/settings.md) - Setting up environments and configurations
- [Custom Steps](/docs/custom-steps.md) - Creating custom automation steps
- [Build Server Integration](/docs/build-server-basic-steps.md) - CI/CD integration patterns

### API Reference
- Step functions follow the naming convention `Step-{Name}`
- All steps accept optional `Section` parameter for configuration targeting
- Return codes: 0 (success), 1 (failure)
- JSON results available through `$Global:JsonResult` variable

## Contributing

### Adding New Steps
1. Create PowerShell function in `AutoExt/` directory
2. Follow naming convention: `Step-{YourStepName}`
3. Include proper error handling and result codes
4. Add synopsis for help system
5. Test with multiple environment configurations

### Code Standards
- Use `[CmdletBinding(SupportsShouldProcess=$True)]` for all steps
- Implement try/catch with proper `$script:Result` setting
- Use `Write-Verbose` for detailed logging
- Follow existing parameter patterns for consistency

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Support

For issues, questions, or contributions, please refer to the project's issue tracking system or contact the development team.

---

**Note**: This framework has evolved from SenseNet-specific tooling into a general-purpose operational automation platform. While SenseNet CMS deployment remains a core use case, the framework now supports diverse automation scenarios across different platforms and technologies.
