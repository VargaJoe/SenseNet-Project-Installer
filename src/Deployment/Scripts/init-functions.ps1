# Global Functions
Function Set-SettingsPath {
	Param(
            [Parameter(Mandatory=$False)]
            [String]$SettingName = "local"
         )
	$ProjectSettingsPath = Get-FullPath ".\Settings\project-$SettingName.json"
	return $ProjectSettingsPath
}

Function Load-Settings {
	Param(
            [Parameter(Mandatory=$False)]
            [String]$SettingsPath
         )
	
	$JsonConfig = (Get-Content $SettingsPath) -join "`n" | ConvertFrom-Json 
	return $JsonConfig
}


Function Get-FullPath {
	Param(
		[Parameter(Mandatory=$True)]
        [String]$Path,
		[Parameter(Mandatory=$False)]
        [String]$SubFolder
		)
	if ($Path -like "*:\*") {
		$FullPath = "$Path"
	} else {
		$CombinedPath = [IO.Path]::Combine($ScriptBaseFolderPath, "$Path")
		$FullPath = [IO.Path]::GetFullPath($CombinedPath)
	}	
	return $FullPath
}

Function Run-Modules {
	Param(
		[Parameter(Mandatory=$True)]
        [String]$Mode
		)
	$ProcessSteps = $defaultsettings.modes."$Mode".Length
	$Step = 0
	if (!($defaultsettings.modes."$Mode" -eq $Null)) {
		Write-Host Running Mode Name: $Mode
		foreach ($ModuleName in $defaultsettings.modes."$Mode") {
			$Step += 1
			$Synopsis = Get-Help Module-"$ModuleName" |  foreach { $_.Synopsis  }
			Write-Host Mode: $Mode
			Write-Host Module: $ModuleName
			Write-Host Synopsis: $Synopsis
			Write-Host Progress: (($Step/($ProcessSteps))*100)
			write-progress -id 1 -activity "$Mode" -status "$Synopsis" -percentComplete (($Step/($ProcessSteps))*100);
			# Run-Module $Modul
			Invoke-Expression Module-"$ModuleName" 
		}	
		Write-Host
		Write-Host --------------------------------------------------
		Write-Host -------------------- FINISH ----------------------
		Write-Host --------------------------------------------------
	} else {
		Write-Host Running Module Name: $Mode
		Invoke-Expression Module-"$Mode" 
	}
}

Function Is-Administrator {
	$Result = $False
	If (-NOT ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole(`
		[Security.Principal.WindowsBuiltInRole] "Administrator"))
	{
		$Result = $False
	} else {
		$Result = $True
	}
	return $Result
}

Function Go-Verbose {
     [CmdletBinding()]Param()
     Write-Verbose "Alright, you prefer talkative functions. First of all, I appreciate your wish to learn more about the common parameter -Verbose. Secondly, blah blah.."
     Write-Host "This is self-explanatory, anyway."
}

function Set-ConnectionString {
	Param(
            [Parameter(Mandatory=$True)]
            [String]$ConfigPath,
			[Parameter(Mandatory=$True)]
            [String]$ConnectionString
         )
	
	Write-Host Config path: $ConfigPath
	Set-ItemProperty $ConfigPath -name IsReadOnly -value $false
	$doc = [xml](get-content $ConfigPath)
	$root = $doc.get_DocumentElement();
	$root.connectionStrings.add.ConnectionString = $ConnectionString
	$doc.Save($ConfigPath)
}

function Set-AppSetting {
	Param(
            [Parameter(Mandatory=$True)]
            [String]$ConfigPath,
			[Parameter(Mandatory=$True)]
            [String]$Key,
			[Parameter(Mandatory=$True)]
            [String]$Value
         )
	
	Write-Host Config path: $ConfigPath
	Set-ItemProperty $ConfigPath -name IsReadOnly -value $false
	$doc = [xml](get-content $ConfigPath)
	#$root = $doc.get_DocumentElement();
	# $obj = $root.configuration.appSettings.add | where {$_.Key -eq $Key}
	$obj = $doc.configuration.appSettings.add | where {$_.Key -eq $Key}
	if ($obj) {
		$obj.value = $Value
	} else {
		$newAppSetting = $doc.CreateElement("add")
		$doc.configuration.appSettings.AppendChild($newAppSetting)
		$newAppSetting.SetAttribute("key",$Key);
		$newAppSetting.SetAttribute("value",$Value);	
	}
	$doc.Save($ConfigPath)
}

# Help Set-ConnectionString

# $connectionString = 'Persist Security Info=False;Initial Catalog=masik;Data Source=.\SQL2016;Integrated Security=true'
# $importConfig = 'C:\Development\LeisureJoe\InstallTest\Deployment\Scripts\Import.exe.config'
# Set-ConnectionString -ConfigPath $importConfig -ConnectionString $connectionString

function Set-PathTooLongHandling {
	Param(
            [Parameter(Mandatory=$True)]
            [String]$ConfigPath
         )

	#  <AppContextSwitchOverrides value="Switch.System.IO.UseLegacyPathHandling=false;Switch.System.IO.BlockLongPaths=false" />		 
	
	Write-Host Config path: $ConfigPath
	Set-ItemProperty $ConfigPath -name IsReadOnly -value $false
	$doc = [xml](get-content $ConfigPath)
	if (!($doc.configuration.runtime.AppContextSwitchOverrides)){
		$override = $doc.CreateElement("AppContextSwitchOverrides")
		$override.SetAttribute("value","Switch.System.IO.UseLegacyPathHandling=false;Switch.System.IO.BlockLongPaths=false");
		$doc.configuration.runtime.AppendChild($override)		
	}
	$doc.Save($ConfigPath)
}

# function Set-UrlList {
	# Param(
            # [Parameter(Mandatory=$True)]
            # [String]$ConfigPath,
			# [Parameter(Mandatory=$True)]
            # [String]$Host
         # )
	# # <urlList>
      # # <sites>
        # # <site path="/Root/Sites/Default_Site">
          # # <urls>
            # # <url host="localhost" auth="Forms" />
          # # </urls>
        # # </site>
      # # </sites>
    # # </urlList>
		 
	# Write-Host Config path: $ConfigPath
	# $doc = [xml](get-content $ConfigPath)
	# if (!($doc.configuration.sensenet.urlList)){
		# $override = $doc.CreateElement("urlList")
		# $override = $doc.CreateElement("sites")
		# $override.SetAttribute("value","Switch.System.IO.UseLegacyPathHandling=false;Switch.System.IO.BlockLongPaths=false");
		# $doc.configuration.runtime.AppendChild($override)		
	# }
	# $doc.Save($ConfigPath)
# }

Function Register-PSRepositoryFix {
    [CmdletBinding()]
    Param (
        [Parameter(Mandatory=$true)]
        [String]
        $Name,

        [Parameter(Mandatory=$true)]
        [Uri]
        $SourceLocation,

        [ValidateSet('Trusted', 'Untrusted')]
        $InstallationPolicy = 'Trusted'
    )

    $ErrorActionPreference = 'Stop'

    Try {
        Write-Verbose 'Trying to register via ​Register-PSRepository'
        ​Register-PSRepository -Name $Name -SourceLocation $SourceLocation -InstallationPolicy $InstallationPolicy
        Write-Verbose 'Registered via Register-PSRepository'
    } Catch {
        Write-Verbose 'Register-PSRepository failed, registering via workaround'

        # Adding PSRepository directly to file
        Register-PSRepository -name $Name -SourceLocation $env:TEMP -InstallationPolicy $InstallationPolicy
        $PSRepositoriesXmlPath = "$env:LOCALAPPDATA\Microsoft\Windows\PowerShell\PowerShellGet\PSRepositories.xml"
        $repos = Import-Clixml -Path $PSRepositoriesXmlPath
        $repos[$Name].SourceLocation = $SourceLocation.AbsoluteUri
        $repos[$Name].PublishLocation = (New-Object -TypeName Uri -ArgumentList $SourceLocation, 'package/').AbsoluteUri
        $repos[$Name].ScriptSourceLocation = ''
        $repos[$Name].ScriptPublishLocation = ''
        $repos | Export-Clixml -Path $PSRepositoriesXmlPath

        # Reloading PSRepository list
        Set-PSRepository -Name PSGallery -InstallationPolicy Untrusted
        Write-Verbose 'Registered via workaround'
    }
}

# Creates a new directory using the specified path.
function New-Directory([string]$dir) {
    New-Item $dir -ItemType Directory -ErrorAction SilentlyContinue | Out-Null

}


# The intent of this script is to locate and return the path to the MSBuild directory that
# we should use for bulid operations. The preference order for MSBuild to use is as 
# follows
#
#   1. MSBuild from an active VS command prompt
#   2. MSBuild from a machine wide VS install
#   3. MSBuild from the xcopy toolset 
#
# This function will return two values: the kind of MSBuild chosen and the MSBuild directory.
function Get-MSBuildKindAndDir([switch]$xcopy = $false) {
    if ($xcopy) { 
        Write-Output "xcopy"
        Write-Output (Get-MSBuildDirXCopy)
        return
    }
    # MSBuild from an active VS command prompt.  
    if (${env:VSINSTALLDIR} -ne $null) {
        # This line deliberately avoids using -ErrorAction.  Inside a VS command prompt
        # an MSBuild command should always be available.
        $command = (Get-Command msbuild -ErrorAction SilentlyContinue)
        if ($command -ne $null) {
            $p = Split-Path -parent $command.Path
            Write-Output "vscmd"
            Write-Output $p
            return
        }
    }
    # Look for a valid VS installation
    try {
        $p = Get-VisualStudioDir
        $p = Join-Path $p "MSBuild\15.0\Bin"
        Write-Output "vsinstall"
        Write-Output $p
        return
    }
    catch { 
        # Failures are expected here when no VS installation is present on the machine.
    }
    Write-Output "xcopy"
    Write-Output (Get-MSBuildDirXCopy)
    return
}

# Locate the xcopy version of MSBuild.
function Get-MSBuildDirXCopy() {
    $version = "0.1.2"
    $name = "RoslynTools.MSBuild"
    $p = Get-BasicTool $name $version
    $p = Join-Path $p "tools\msbuild"
    return $p
}

# Get the MSBuild directory.
function Get-MSBuildDir([switch]$xcopy = $false) {
    $both = Get-MSBuildKindAndDir -xcopy:$xcopy
    return $both[1]
}

# Get the directory of the first Visual Studio which meets our minimal requirements.
function Get-VisualStudioDir() {
    $vswhere = Join-Path (Get-BasicTool "vswhere" "1.0.50") "tools\vswhere.exe"
    $output = & $vswhere -requires Microsoft.Component.MSBuild -format json | Out-String
    if (-not $?) {
        throw "Could not locate a valid Visual Studio"
    }
    $j = ConvertFrom-Json $output
    $p = $j[0].installationPath
    return $p
}

# Ensure that MSBuild is installed and return the path to the executable to use.
function Get-MSBuild([switch]$xcopy = $false) {
    $both = Get-MSBuildKindAndDir -xcopy:$xcopy
    $msbuildDir = $both[1]
    switch ($both[0]) {
        "xcopy" { break; }
        "vscmd" { break; }
        "vsinstall" { break; }
        default {
            throw "Unknown MSBuild installation type $($both[0])"
        }
    }
    $p = Join-Path $msbuildDir "msbuild.exe"
    return $p
}

