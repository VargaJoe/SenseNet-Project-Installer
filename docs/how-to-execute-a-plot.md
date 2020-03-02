# How to execute a "plot" 
As it was mentioned earlier, the solutions main goal is to do specified tasks syncronously. The scenario names "plot" the executable task is the "step". Since in most of the cases "plot" makes it possibel to automate tasks with multiple steps, saving us time, in basic scenarios (e.g. creating or updating the development enviroment) the "plot" plays the bigger role. These scenarios are declared in the settings file storing the steps of related plot. 'fullinstall' is a good example for that, installing sensenet from schratch configured for the specified project. This plot is made up from the following steps (may be different from project to project of course):
- stops the site (if it was installed before)
- downloads the nuget packages that are declared in the project
- creates the needed assembly files (e.g. it builds the solution)
- clears the database
- creates the new database and installs the [sn-services](https://github.com/SenseNet/sensenet) package
- installs [sn-webpages](https://github.com/SenseNet/sn-webpages)
- removes demo content
- adds predefined users to the repository
- installs custom, project related content
- sets the project-specific urls on the related site's of the repository
- populates lucene index
- creates the site in IIS
- adds the defined urls into the HOST file of the local machine
- starts the IIS site 

After this quick overview, see how it should be executed actually. If a project is well-configured and prepared and all the prerequisites for executing are fulfilled, the developer - who let's say you've just joined the project - has only need to get the code, open a powershell window and execute the following code:

```powershell
.\Run.ps1 fullinstall
```

The code above will execute the "fullinstall" scenario for configure the "Project" with the "local" settings, which means it creates the local development enviroment (in this case a sensenet site).
In this case the script will give you a minimal feedback, only those messages will shown that are returned from the helper tools. If you need further information the feedbacks considered important by the creators of the script can be reached with the following addition:

```powershell
.\Run.ps1 fullinstall -Verbose
```

And if you want to skip the feedback messages of the helper tools, then use:

```powershell
.\Run.ps1 fullinstall -ShowOutput false
```

The examples above are sufficient only if we execute predefined scenarios in local enviroment, but we can also define custom scenarios, non-local enviroments (e.g. test server) or handle multiple projects. In this cases you have know the parameters a bit more. The second example above could be look like this:

```powershell
.\Run.ps1 -Plot fullinstall:Project -Settings local -ShowOutput true -Verbose
```

Suppose that we want to update custom project content on a distributed test server in a project names 'Custom', that has a custom settings file which could be the following:

```powershell
.\Run.ps1 -Plot updatetestsite -Settings custom -ShowOutput true -Verbose
```