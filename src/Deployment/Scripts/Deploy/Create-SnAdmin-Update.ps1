[CmdletBinding(SupportsShouldProcess=$True)]
Param(
	[Parameter(Mandatory=$false)]
	[string]$Date = $(Get-Date -format MM/dd/yyyy),
	[Parameter(Mandatory=$false)]
	[string]$GitRepoFolder,
	[Parameter(Mandatory=$true)]
	[string]$PackageFolderPath,
	[Parameter(Mandatory=$false)]
	[string]$LocationFilter,
	[Parameter(Mandatory=$false)]
	[string]$Top	
)

Function Get-FullPathCustom {
	Param(
		[Parameter(Mandatory=$True)]
        [String]$Path,
		[Parameter(Mandatory=$False)]
        [String]$SubFolder
		)
	if (($Path -like "*:\*") -or ($Path -like "\\*")) {
		$FullPath = "$Path"
	} else {
		$CombinedPath = [IO.Path]::Combine($ScriptBaseFolderPath, "$Path")
		$FullPath = [IO.Path]::GetFullPath($CombinedPath)
	}	
	return $FullPath
} 

Function Write-ColoredOutput {
	Param(
		[Parameter(Mandatory=$True)]
        [String]$outputString,
		[Parameter(Mandatory=$False)]
        [String]$outputColor
		)
		
    # save the default color
    $defaultColor = $host.UI.RawUI.ForegroundColor

    # set custom color
    $host.UI.RawUI.ForegroundColor = $outputColor

    # output    
    Write-Output $outputString   

    # restore the default color
    $host.UI.RawUI.ForegroundColor = $defaultColor
}

###########################################################
################## Variable Declarations ##################
###########################################################
$CurrentDateTime = Get-Date -format [yyyy-MM-dd-HH-mm-ss]
  
$dateFilter = "--after=`$($Date)"
#$dateFilter = "--before=`$(10/14/2019)"
#$dateFilter = "--after=`$(10/09/2019)"
$topFilter = ""
if ($Top) {
	$topFilter = "-n $Top"
}

# array for future replace automation
#$importRoots = ["$devRootPath\Rornorge\RorWeb\Release\Deployment\Packages\RorWebRTE\import\", "$devRootPath\Rornorge\RorWeb\Release\Source\WebSite\Root\"]

# Get Project folder on local environment
#& "C:\Program Files (x86)\Microsoft Visual Studio\2017\Enterprise\Common7\IDE\CommonExtensions\Microsoft\TeamFoundation\Team Explorer\tf.exe" workfold "$/Rornorge/RorWeb/Release" | Out-String

$driveLitter = $WorkDir.Substring(0,2)
$devRootPath = $WorkDir #"d:\development\devbs"
$packageImportFolderRelativePath = "$PackageFolderPath\import"

# unhandled files should be copied to webfolder directory for further investigation
# $packageUnhandledFolderRelativePath = "$packageFolderRelativePath\webfolder"

Write-Output $CurrentDateTime 

###########################################################
################# Last Commit(s) Changes ##################
###########################################################

Write-Output "Check last $($Top) commits"

$changedFiles = @()
$filePaths = @()
$removedFilePaths = @()
$renamedFilePaths = @()

#git --no-pager whatchanged --after=`$(10/09/2019) --abbrev-commit --no-commit-id --name-status -r
#git --no-pager log --since=`$(10/09/2019) --abbrev-commit --no-commit-id --name-status -r --stat --pretty=format:""

try {
	$pinfo = New-Object System.Diagnostics.ProcessStartInfo
	$pinfo.FileName = "git"
	$pinfo.RedirectStandardError = $true
	$pinfo.RedirectStandardOutput = $true
	$pinfo.UseShellExecute = $false	
	#$pinfo.Arguments = "--no-pager whatchanged $dateFilter --abbrev-commit --no-commit-id --name-status -r"	
	$pinfo.Arguments = "--no-pager log $topFilter $dateFilter --abbrev-commit --no-commit-id --name-status -r --stat --pretty=format:`"`""	
	$pinfo.WorkingDirectory = $GitRepoFolder
	$p = New-Object System.Diagnostics.Process
	$p.StartInfo = $pinfo
	$p.Start() | Out-Null
	$p.WaitForExit()
	$stdout = $p.StandardOutput.ReadToEnd()
	$stderr = $p.StandardError.ReadToEnd()
	#Write-Host "stdout: $stdout"
	#Write-Host "stderr: $stderr"
	#Write-Host "exit code: " + $p.ExitCode
	if ($p.ExitCode -eq 0) {
		foreach ($line in $stdout.Split("`n")) {
			$line = $line.trim()
			if ($line) {
				#Write-Host "$line"
				$changedFiles += "$line"
			}
		}
	} else {
		write-host "Errors ($($p.ExitCode)): $($stderr)"
	}
}
catch {
	write-host "Exception2: $_"
}

# write-host $stdout

# order by and distinct
$changedFiles = $changedFiles | Sort-Object | Select-Object -Unique

# files count
Write-Output "ItemCount: $($changedFiles.Count)" 

####################
# ' ' = unmodified
# M = modified
# A = added
# D = deleted
# R = renamed
# C = copied
# U = updated but unmerged
####################

# delete or rename should be gather in a separate array for handle manually
foreach ($file in $changedFiles) {
	$fileName = $file.substring(1).trim()
	
	# filter to subfolder
	if (-not($fileName.StartsWith("$LocationFilter"))) {
		Write-ColoredOutput "(skip)`t$file" red
		continue
	} else {
		Write-Output "      `t$file" 	
	}

	# added or modified list
	if ($file[0] -eq "A" -or $file[0] -eq "M") {	
		$filePaths += $fileName
	} 
	# delete list
	elseif ($file[0] -eq "D") {	
		$removedFilePaths += $fileName
	}
	# rename list
	elseif ($file[0] -eq "R") {	
		$renamedFilePaths += $fileName
	}
}

 Write-Output " " 

 # order by and distinct
$filePaths = $filePaths | Sort-Object | Select-Object -Unique

Write-Output "Added or changed File Paths: $($filePaths.Count)"
Write-Output " " 
Write-Output "Deleted File Paths: $($removedFilePaths.Count)"
Write-Output " " 
Write-Output "Renamed File Paths: $($renamedFilePaths.Count)"
Write-Output " " 

###########################################################
################### Proces Files ##########################
###########################################################


Write-Output "Process Files" 
foreach	($filePath in $filePaths) {
	$filePath = $filePath.replace("/", "\")
	$realFilePath = "$($GitRepoFolder)\$($filePath)"	
	$realFilePath = Get-FullPathCustom $realFilePath

	if (Test-Path -Path "$realFilePath" -PathType Leaf) {
		$realFolderPath = (get-item "$realFilePath").Directory.FullName
		#Write-Output "$realFilePath" 
	
		# # filter to subfolder
		# if (-not($filePath.StartsWith("_docs"))) {
			# write-Output "skipped path $realFilePath" 
			# continue
		# }

		# file paths have to be doublechecked
		$relativeFilePath = $realFilePath.Replace("$GitRepoFolder","")
		$relativeFolderPath = $realFolderPath.Replace("$GitRepoFolder","")
		#Write-Output "repoFolderPath: $GitRepoFolder"
		#Write-Output "relativeFolderPath: $relativeFolderPath"
		
		#$devRootPath\Rornorge\RorWeb\Release\Source\WebSite\Root\	
		$packageFilePath = "$($packageImportFolderRelativePath)$($relativeFilePath)"
		$packageFolderPath = "$($packageImportFolderRelativePath)$($relativeFolderPath)"
		#$packageFilePath = [IO.Path]::GetFullPath($packageFilePath) 
		$packageFilePath = Get-FullPathCustom $packageFilePath
		
		# Create parent folder if does not exist
		if (-Not (Test-Path -Path "$packageFolderPath" -PathType Container)) {
			write-output "create dir $packageFolderPath" 
			New-Item -ItemType Directory -Path "$packageFolderPath" -Force			
		}
		
		# Copy file and remove read-only attribute before it would cause problem when package is installed
		Copy-Item -Path "$realFilePath" -Destination "$packageFilePath" -Force 
		& "c:\Windows\System32\attrib.exe" -r "$packageFilePath"
		Write-Output "copied to $packageFilePath" 
		
		# Copy Content file too if available, log if not
		# Technical Debt: if content si aspx file Content will be file.aspx.Content, but when Page it will be file.Content
		# Technical Debt: Page requires file.aspx, file.Content and file.PersonalizationSettings too
		# Technical Debt: if Content is the modified file, there will be no file.Content.Content, but attachment will be missing
		#$realFileContentPath = "$realFilePath.Content"		
		#$packageFileContentPath = "$packageFilePath.Content"
		#if (Test-Path -Path "$realFileContentPath" -PathType leaf) {
		#	$wordToFind = "<ContentType>File</ContentType>"
		#	$file = Get-Content $realFileContentPath
		#	$containsWord = $file | Where-Object { $_.Contains($wordToFind) }
		#	If(-not $containsWord)
		#	{
		#		$silent = Copy-Item -Path "$realFileContentPath" -Destination "$packageFileContentPath" -Force 
		#		write-Output "Content is $packageFileContentPath" | Tee-Object -FilePath $logFileCopies -Append
		#	} else {
		#		write-Output "skipped Content $packageFileContentPath" | Tee-Object -FilePath $logFileSkips -Append
		#	}
		#} else {
		#	write-Output "Content no $packageFileContentPath" | Tee-Object -FilePath $logFileMissings -Append
		#}		
			
	} else {
		write-Output "skipped folder $realFilePath" 
	}
}

Write-Output " " 
Write-Output "Removed Files" 
foreach	($removedFilePath in $removedFilePaths) {
	$realFilePath = $removedFilePath -replace "\$/Rornorge", "$devRootPath\Rornorge"
	$realFilePath = [IO.Path]::GetFullPath($realFilePath) 
	write-Output "removed file $realFilePath" 
}

Write-Output " " 
Write-Output "Renamed Files" 
foreach	($renamedFilePath in $renamedFilePaths) {
	$realFilePath = $renamedFilePath -replace "\$/Rornorge", "$devRootPath\Rornorge"
	$realFilePath = [IO.Path]::GetFullPath($realFilePath) 
	write-Output "renamed file $realFilePath" 
}
