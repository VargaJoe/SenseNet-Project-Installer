[CmdletBinding(SupportsShouldProcess=$True)]
Param(
[Parameter(Mandatory=$true)]
[string]$RemoteServerName,
[Parameter(Mandatory=$false)]
[string]$PsFilePath,
[Parameter(Mandatory=$false)]
[string]$PsFileArgumentList,
[Parameter(Mandatory=$false)]
[string]$PsScript
)
#Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass 
#Set-PSSessionConfiguration microsoft.powershell -ShowSecurityDescriptorUI
#Set-PSSessionConfiguration microsoft.powershell -Force

#$Username = '_devsiteservices'
#$Password = 'QWE123asd%'
#$pass = ConvertTo-SecureString -AsPlainText $Password -Force
#$Cred = New-Object System.Management.Automation.PSCredential -ArgumentList $Username,$pass

 #-credential $Cred
if ($PsScript) {
	Invoke-Command -ComputerName "$RemoteServerName" -ScriptBlock { $PsScript }
}
elseif ($PsFilePath -and $PsFileArgumentList) {
	Invoke-Command -ComputerName "$RemoteServerName" -FilePath "$PsFilePath" -ArgumentList "$PsFileArgumentList"
} 
elseif ($PsFilePath) {
	Invoke-Command -ComputerName "$RemoteServerName" -FilePath "$PsFilePath" 
}
