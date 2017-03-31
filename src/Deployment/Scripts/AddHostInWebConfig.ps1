[CmdletBinding(SupportsShouldProcess=$True)]
Param(
[Parameter(Mandatory=$true)]
[string]$configfile,
[Parameter(Mandatory=$true)]
[string]$urlhostname
)

Write-Host ================================================ -foregroundcolor "green"
Write-Host MODIFY HOSTFILE -foregroundcolor "green"
Write-Host ================================================ -foregroundcolor "green"


# CALL: .\AddHostInWebConfig -configfile "Fullpath\Web.config" -urlhostname "powersite"

#$configfile = "D:\MUNKA\Powershell\Web.config"
#$urlhostname = "powersite"

$xml = [xml](get-content $configfile);
$element_urlList = $xml.configuration.sensenet.urlList
$element_sites = $xml.configuration.sensenet.urlList.sites
$element_site = $xml.configuration.sensenet.urlList.sites.site
$urlhostname = $urlhostname.ToLower()

if($element_urlList.Count -eq 0){
	#Write-Host "Create <urlList> element"
	$newElementUrlList=$xml.CreateElement("urlList")
	$newElementSites=$xml.CreateElement("sites")
	$newElementSite=$xml.CreateElement("site")
	$newElementUrls=$xml.CreateElement("urls")
	$newElementUrl=$xml.CreateElement("url")
	
	$newElementSite.SetAttribute('path','/Root/Sites/Default_Site')
	$newElementUrl.SetAttribute('host',$urlhostname)
	$newElementUrl.SetAttribute('auth','Forms')
	
	$newNode = $xml.configuration.sensenet.AppendChild($newElementUrlList)
	$newNode2 = $newNode.AppendChild($newElementSites)
	$newNode3 = $newNode2.AppendChild($newElementSite)
	$newNode4 = $newNode3.AppendChild($newElementUrls)
	$newNode4.AppendChild($newElementUrl)
	
	$xml.Save($configfile)
	Write-Host "The $urlhostname added in Web.config." -foregroundcolor "green"
}
else
{
	if($element_sites.Count -eq 0)
	{
		#Write-Host "Create <sites> element"
		$newElementSites=$xml.CreateElement("sites")
		$newElementSite=$xml.CreateElement("site")
		$newElementUrls=$xml.CreateElement("urls")
		$newElementUrl=$xml.CreateElement("url")
		
		$newElementSite.SetAttribute('path','/Root/Sites/Default_Site')
		$newElementUrl.SetAttribute('host',$urlhostname)
		$newElementUrl.SetAttribute('auth','Forms')
		
		$newNode = $xml.configuration.sensenet.urlList.AppendChild($newElementSites)
		$newNode2 = $newNode.AppendChild($newElementSite)
		$newNode3 = $newNode2.AppendChild($newElementUrls)
		$newNode3.AppendChild($newElementUrl)
		
		$xml.Save($configfile)
		Write-Host "The $urlhostname added in Web.config." -foregroundcolor "green"
	}
	else{
		if($element_site.Count -eq 0)
		{
			#Write-Host "Create <site> element"
			$newElementSite=$xml.CreateElement("site")
			$newElementUrls=$xml.CreateElement("urls")
			$newElementUrl=$xml.CreateElement("url")
			
			$newElementSite.SetAttribute('path','/Root/Sites/Default_Site')
			$newElementUrl.SetAttribute('host',$urlhostname)
			$newElementUrl.SetAttribute('auth','Forms')
			
			$newNode = $xml.configuration.sensenet.urlList.sites.AppendChild($newElementSite)
			$newNode2 = $newNode.AppendChild($newElementUrls)
			$newNode2.AppendChild($newElementUrl)
			
			$xml.Save($configfile)
			Write-Host "The $urlhostname added in Web.config." -foregroundcolor "green"
		}
		else{
			$existurl = $xml.configuration.sensenet.urlList.sites.site.urls.url | where {$_.host -eq $urlhostname}
			if($existurl.Count -eq 0)
			{
				#Write-Host "Create <site> element"
				$newElementSite=$xml.CreateElement("site")
				$newElementUrls=$xml.CreateElement("urls")
				$newElementUrl=$xml.CreateElement("url")
				
				$newElementSite.SetAttribute('path','/Root/Sites/Default_Site')
				$newElementUrl.SetAttribute('host',$urlhostname)
				$newElementUrl.SetAttribute('auth','Forms')
				
				$newNode = $xml.configuration.sensenet.urlList.sites.AppendChild($newElementSite)
				$newNode2 = $newNode.AppendChild($newElementUrls)
				$newNode2.AppendChild($newElementUrl)
				
				$xml.Save($configfile)
				Write-Host "The $urlhostname added in Web.config." -foregroundcolor "green"
			}
			else{
				Write-Host "The $urlhostname already exist in Web.config"
			}
		}
	}
	
}

	

