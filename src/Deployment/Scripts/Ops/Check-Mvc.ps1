# Check MVC through existing folder for now
# $mvc2 = test-path "${Env:ProgramFiles(x86)}\Microsoft ASP.NET\ASP.NET MVC 2"
# $mvc3 = test-path "${Env:ProgramFiles(x86)}\Microsoft ASP.NET\ASP.NET MVC 3"
# $mvc4 = test-path "${Env:ProgramFiles(x86)}\Microsoft ASP.NET\ASP.NET MVC 4"

$exitcode = -1

if (test-path "${Env:ProgramFiles(x86)}\Microsoft ASP.NET\ASP.NET MVC*")
{
    Write-Output "MVC is available."
    $exitcode = 0
} else {
    Write-Output "MVC is not available."
    $exitcode = 1
}

exit $exitcode