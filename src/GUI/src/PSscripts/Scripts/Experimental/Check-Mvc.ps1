$mvc2 = test-path "${Env:ProgramFiles(x86)}\Microsoft ASP.NET\ASP.NET MVC 2"
$mvc3 = test-path "${Env:ProgramFiles(x86)}\Microsoft ASP.NET\ASP.NET MVC 3"
$mvc4 = test-path "${Env:ProgramFiles(x86)}\Microsoft ASP.NET\ASP.NET MVC 4"
write-host $mvc2
write-host $mvc3
write-host $mvc4