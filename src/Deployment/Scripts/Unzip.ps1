[CmdletBinding(SupportsShouldProcess=$True)]
Param(
[Parameter(Mandatory=$true)]
[string]$filename,
[Parameter(Mandatory=$true)]
[string]$destname,
[Parameter(Mandatory=$false)]
[string]$unzipper
)

if (!($unzipper)){
	$unzipper = $UnZipperfilePath
}

# ================================================
# ====== UNZIP FILE SCRIPT =======================
# ================================================
# .\unzip -filename "test.zip" -destname "unzip"

$modulename = $MyInvocation.MyCommand.Name 
$filename = [IO.Path]::GetFullPath($filename)
$destname = [IO.Path]::GetFullPath($destname)
$unzipper = [IO.Path]::GetFullPath($unzipper)

Write-Host ================================================ -foregroundcolor "green"
Write-Host UNZIP SENSENET PACKAGE ">>" $filename -foregroundcolor "green"
Write-Host TO DESTINATION ">>" $destname -foregroundcolor "green"
Write-Host ================================================ -foregroundcolor "green"

Try{
	if(Test-Path $filename)
	{
		if(-Not (Test-Path $destname))
		{
			mkdir $destname
		}
		
		#Expand-Archive $filename -DestinationPath $destname
		&  $unzipper x "$filename" -o"$destname" -y
		exit 0	
	}
	else
	{
		throw [System.IO.FileNotFoundException] "$filename not found."
	}
	
}	
Catch
{
	$ErrorMessage = $_.Exception.Message
	$functionname = $MyInvocation.MyCommand.Name
	Write-Host "[Error][$modulename : $functionname] => "$ErrorMessage
	exit 22
}
