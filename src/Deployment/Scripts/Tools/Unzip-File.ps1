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
$UnZipperfilePath = Get-FullPath $GlobalSettings.Tools.UnZipperFilePath

$Output = if ($ShowOutput -eq $True) {"Out-Default"} else {"Out-Null"}

Try{
	if(Test-Path $filename)
	{
		if(-Not (Test-Path $destname))
		{
			mkdir $destname
		}
		
		&  $UnZipperfilePath x "$filename" -o"$destname" -y | & $Output
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
	Write-Verbose "[Error][$modulename : $functionname] => $ErrorMessage"
	exit 22
}
