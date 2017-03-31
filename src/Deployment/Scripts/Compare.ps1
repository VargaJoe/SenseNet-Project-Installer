[CmdletBinding(SupportsShouldProcess=$True)]
Param(
[Parameter(Mandatory=$true)]
[string]$dir1,
[Parameter(Mandatory=$true)]
[string]$dir2,
[Parameter(Mandatory=$false)]
[string[]]$fileTypes
)

# USE: ./compare "D:\dev2\Rornorge\RorWeb\Development\Source\WebSite\Root\Skins\rorweb\assets\" "d:\MUNKA\_RORWEB\Template(git)\rorweb-prototype\assets\" ".js",".css"
if($fileTypes.Count -eq 0)
{
	$fileTypes = ".js",".css"
}

function GetFiles($path, [string[]]$exclude) 
{ 
    foreach ($item in Get-ChildItem $path)
    {
        if ($exclude | Where {$item -like $_}) { continue }

        if (Test-Path $item.FullName -PathType Container) 
        {
            #$item
            GetFiles $item.FullName $exclude
        } 
        else 
        { 
			if($fileTypes -contains [IO.Path]::GetExtension($item.FullName))
			{
				$relativePath = $item.FullName -replace [regex]::escape($dir1), ""
				if (Test-Path $dir2$relativePath){
					if($(Get-Content $item.FullName)){				
						if (Compare-Object -ReferenceObject $(Get-Content $item.FullName) -DifferenceObject $(Get-Content $dir2$relativePath)) {
							# Különbség van
							write-host "DIFFERENT: "$item.FullName" and "$dir2$relativePath -foregroundcolor "yellow"
							$DIFFcount = $DIFFcount+1
						}
					}
				}
				else{
					# Nincs meg a fájl
					write-host "NOT FOUND: "$dir2$relativePath" is not found" -foregroundcolor "green"
					$NOTcount = $NOTcount+1
				}
				
			}	
        }
		
    }
	
}
write-host "----------------- COMPARE INFORMATION -------------------------------"
write-host ""
write-host $dir1" compare to "$dir2
write-host ""
write-host "----------------- START COMPARE -------------------------------"
GetFiles($dir1)
write-host "----------------- END COMPARE -------------------------------"


