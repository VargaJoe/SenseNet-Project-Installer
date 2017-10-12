[CmdletBinding(SupportsShouldProcess=$True)]
Param(
[Parameter(Mandatory=$true)]
[string]$filename,
[Parameter(Mandatory=$true)]
[string]$destname
)


# ================================================
# ====== UNZIP FILE SCRIPT =======================
# ================================================
# .\unzip -filename "test.zip" -destname "unzip"
$modulename = $MyInvocation.MyCommand.Name
$UnZipperfilePath = Get-FullPath $DefaultSettings.Tools.UnZipperFilePath


Try{
	if(Test-Path $filename)
	{
		if(-Not (Test-Path $destname))
		{
			mkdir $destname
		}
		
		&  $UnZipperfilePath x "$filename" -o"$destname" -y
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
