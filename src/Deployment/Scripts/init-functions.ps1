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


