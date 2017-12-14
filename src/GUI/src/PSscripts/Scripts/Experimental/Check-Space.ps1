$disk = Get-WmiObject Win32_LogicalDisk -ComputerName localhost -Filter "DeviceID='C:'" |
Select-Object Size,FreeSpace
write-host $disk