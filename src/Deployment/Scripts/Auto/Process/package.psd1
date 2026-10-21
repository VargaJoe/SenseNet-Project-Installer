@{
    Name='process'; Version='1.0.0'; RootModule='Plot.Process.psm1'
    Steps=@{
        run=@{
            Command='Invoke-PlotProcess'
            Parameters=@{
                FilePath=@{Type='string';Required=$true}
                Arguments=@{Type='array';Default=@();Secret=$true}
                WorkingDirectory=@{Type='string';Default=''}
                Environment=@{Type='object';Default=@{};Secret=$true}
                TimeoutSeconds=@{Type='int';Default=60}
                SuccessExitCodes=@{Type='array';Default=@(0)}
            }
        }
    }
}
