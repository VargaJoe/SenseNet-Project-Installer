@{
    Name='process'; Version='1.0.0'; RootModule='Plot.Process.psm1'
    Steps=@{
        run=@{
            Command='Invoke-PlotProcess'; Description='Run an explicit executable with bounded time and separate arguments.'; Outputs=@{FilePath=@{Description='Executable path on the runner, or executable name on PATH.'; Type='string'};ExitCode=@{Description='ExitCode (int).'; Type='int'};StandardOutput=@{Description='StandardOutput (string).'; Type='string'};StandardError=@{Description='StandardError (string).'; Type='string'};DurationMilliseconds=@{Description='DurationMilliseconds (int).'; Type='int'}}
            Parameters=@{
                FilePath=@{Description='Executable path on the runner, or executable name on PATH.'; Type='string';Required=$true}
                Arguments=@{Description='Separate executable arguments; no implicit shell evaluation.'; Type='array';Default=@();Secret=$true}
                WorkingDirectory=@{Description='WorkingDirectory (string).'; Type='string';Default=''}
                Environment=@{Description='Environment (object).'; Type='object';Default=@{};Secret=$true}
                TimeoutSeconds=@{Description='Maximum operation duration in seconds.'; Type='int';Default=60}
                SuccessExitCodes=@{Description='SuccessExitCodes (array).'; Type='array';Default=@(0)}
            }
        }
    }
}
