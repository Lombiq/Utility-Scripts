using System;
using System.Diagnostics;
using System.IO;
using System.Linq;
using System.Management.Automation;
using System.Threading;
using System.Threading.Tasks;
using Lombiq.UtilityScripts.OrchardCore.Constants;
using static Lombiq.UtilityScripts.OrchardCore.Constants.ParameterSetNames;
using static Lombiq.UtilityScripts.OrchardCore.Helpers.FormerlyScriptHelper;

namespace Lombiq.UtilityScripts.OrchardCore.Cmdlets
{
    
    [Cmdlet(VerbsCommon.Reset, NounNames.OrchardCoreApp)]
    [Alias(VerbsCommon.Reset + "-" + NounNames.OrchardCore)]
    [OutputType(typeof(FileInfo))]
    public class ResetOrchardCoreAppCmdletCommand : AsyncCmdletBase
    {
        private const string _cmdletName = VerbsCommon.Reset + "-" + NounNames.OrchardCoreApp;

        protected override string CmdletName => _cmdletName;
        
        [Parameter(Mandatory = true, ValueFromPipelineByPropertyName = true, Position = 0)]
        public string WebProjectPath { get; set; }
        
        [Parameter]
        public string SetupSiteName { get; set; } = "Orchard Core";
        
        [Parameter]
        public string SetupTenantName { get; set; } = "Default";
        
        [Parameter]
        public string SetupRecipeName { get; set; } = "Blog";
        
        [Parameter]
        public string SetupUserName { get; set; } = "admin";
        
        [Parameter]
        public string SetupPassword { get; set; } = "Password1!";
        
        [Parameter]
        public string SetupEmail { get; set; } = "admin@localhost";
        
        public int Port { get; set; } = 5000;

        [Parameter(ParameterSetName = ServerDB, Mandatory = true)]
        [ValidateSet("SqlConnection")]
        public string SetupDatabaseProvider { get; set; } = "Sqlite";
        
        [Parameter(ParameterSetName = ServerDB)]
        public string SetupDatabaseTablePrefix { get; set; } = "";
        
        [Parameter(ParameterSetName = ServerDB)]
        public string SetupDatabaseServerName { get; set; } = "-";
        
        [Parameter(ParameterSetName = ServerDB)]
        public string SetupDatabaseName { get; set; } = "OrchardCore";
        
        [Parameter(ParameterSetName = ServerDB)]
        public string SetupDatabaseSqlUser { get; set; } = "sa";
        
        [Parameter(ParameterSetName = ServerDB)]
        public string SetupDatabaseSqlPassword { get; set; } = null;

        [Parameter(ParameterSetName = ServerDB)]
        public SwitchParameter Force { get; set; }

        [Parameter(ParameterSetName = ServerDB)]
        public SwitchParameter SuffixDatabaseNameWithFolderName { get; set; }

        [Parameter]
        public SwitchParameter Rebuild { get; set; }

        [Parameter]
        public SwitchParameter KeepAlive { get; set; }

        [Parameter]
        public SwitchParameter Pause { get; set; }

        private async Task ProcessRecordAsync()
        {
            string webProjectDllPath;
            string siteName;
            
            // Checking if the Web Project Path is valid and extracting the name of the Web Project.
            if (File.Exists(WebProjectPath))
            {
                if (!WebProjectPath.EndsWith(".DLL", StringComparison.OrdinalIgnoreCase))
                {
                    throw new InvalidOperationException(
                        $"The {nameof(WebProjectPath)} must be a dll file or a directory path.");
                }

                webProjectDllPath = WebProjectPath;
                var fileInfo = new FileInfo(WebProjectPath);
                siteName = fileInfo.Name.Substring(0, fileInfo.Name.LastIndexOf('.'));
                WebProjectPath = Path.GetDirectoryName(WebProjectPath);
            }
            else if (!Directory.Exists(WebProjectPath))
            {
                throw new InvalidOperationException(
                    $"The {nameof(WebProjectPath)} is not found or not accessible! ({WebProjectPath})");
            }
            else
            {
                webProjectDllPath = GetWebProjectDllPath(WebProjectPath);
                siteName = Path.GetFileName(WebProjectPath);
            }
            
            // Trying to find IIS Express and .NET host processes that run a Web Project with a matching name and
            // terminate them.
            var siteHostProcesses = Process.GetProcessesByName("iisexpress.exe")
                .Concat(Process.GetProcessesByName("dotnet.exe"))
                .Where(process => process.StartInfo?.Arguments?.Contains("$siteName") == true)
                .ToList();

            if (siteHostProcesses.Any())
            {
                foreach (var process in siteHostProcesses)
                {
                    var commandLine = $"{process.StartInfo.FileName} {process.StartInfo.Arguments}";
                    Info($"Terminating application host process running \"{commandLine}\".");
                    
                    process.Kill();
                }
                
                Thread.Sleep(1000);
            }
          
            //Delete App_Data if exists.
            var appData = new DirectoryInfo($"{WebProjectPath}\\App_Data");
            if (appData.Exists)
            {
                Info($"Deleting App_Data folder found in \"{appData.FullName}\".");
                appData.Delete(recursive: true);
            }

            // Rebuilding the application if the "Rebuild" switch is present or the Web Project DLL is not found.
            var buildRequired = false;
            if (Rebuild.IsPresent)
            {
                Info("Rebuild switch active!");
                buildRequired = true;
            }
            else if (string.IsNullOrEmpty(webProjectDllPath) || !File.Exists(webProjectDllPath))
            {
                Info("Web Project DLL not found, build is required!");
                buildRequired = true;
            }
            
            if (buildRequired)
            {
                await DotnetAsync("build", WebProjectPath, "--configuration", "Debug");
                
                // The `if ($LASTEXITCODE -ne 0)` is not needed because CliWrap does that on its own and it should
                // happen everywhere anyway, not just here.

                webProjectDllPath = GetWebProjectDllPath(WebProjectPath);

                if (string.IsNullOrEmpty(webProjectDllPath))
                {
                    throw new InvalidOperationException(
                        $"Project was successfully built at \"{WebProjectPath}\", but the compiled Web Project DLL was not found!");
                }
            }
            
            Info($"Compiled Web Project DLL found at \"{webProjectDllPath}\"!");
            
            // Validating and setting up database server connection.

            var SetupDatabaseConnectionString = "";
            if (ParameterSetName == ServerDB)
            {
                if (SuffixDatabaseNameWithFolderName.IsPresent)
                {
                    var solutionPath = Environment.CurrentDirectory;

                    while (!string.IsNullOrEmpty(solutionPath) && !Directory.GetFiles(solutionPath, "*.sln").Any())
                    {
                        solutionPath = Path.GetDirectoryName(solutionPath);
                    }

                    if (string.IsNullOrEmpty(solutionPath))
                    {
                        throw new DirectoryNotFoundException(
                            "No solution folder was found to create the database name suffix. Put this script into a " +
                            "folder where there or in a parent folder there is the app's .sln file.");
                    }

                    var solutionFolder = Path.GetFileName(solutionPath);
                    SetupDatabaseName = $"{SetupDatabaseName}_{solutionFolder}";
                }
                
                Info($"Using the following database name: \"{SetupDatabaseName}\".");
                
                if (New-SqlServerDatabase -SqlServerName SetupDatabaseServerName -DatabaseName SetupDatabaseName -Force:Force.IsPresent -ErrorAction Stop -UserName SetupDatabaseSqlUser -Password SetupDatabaseSqlPassword)
                {
                    "Database `"SetupDatabaseServerName\SetupDatabaseName`" created!"
                }
                else
                {
                    if ([string]::IsNullOrEmpty(SetupDatabaseTablePrefix))
                    {
                        throw ("Database `"SetupDatabaseServerName\SetupDatabaseName`" could not be created!")
                    }
                    else
                    {
                        "The specified database already exists! Attempting to run setup using the `"SetupDatabaseTablePrefix`" table prefix."
                    }
                }

                Security = if (-not SetupDatabaseSqlPassword) 
                { 
                    "Integrated Security=True"
                }
                else 
                {
                    "User Id=SetupDatabaseSqlUser;Password=SetupDatabaseSqlPassword"    
                }

                # MARS is necessary for Orchard.
                SetupDatabaseConnectionString = "Server=SetupDatabaseServerName;Database=SetupDatabaseName;Security;MultipleActiveResultSets=True;"
            }
            
            /*
        # Validating and setting up database server connection.

        $SetupDatabaseConnectionString = ""
        if ($PSCmdlet.ParameterSetName -eq "ServerDB")
        {
            if ($SuffixDatabaseNameWithFolderName.IsPresent)
            {
                $solutionPath = (Get-Location).Path

                while (-not [string]::IsNullOrEmpty($solutionPath) -and -not (Test-Path (Join-Path $solutionPath "*.sln")))
                {
                    $solutionPath = Split-Path $solutionPath -Parent;
                }

                if ([string]::IsNullOrEmpty($solutionPath))
                {
                    throw ("No solution folder was found to create the database name suffix. Put this script into a folder where there or in a parent folder there is the app's .sln file.")
                }

                $solutionFolder = Split-Path $solutionPath -Leaf
                
                $SetupDatabaseName = $SetupDatabaseName + "_" + $solutionFolder
            }

            "Using the following database name: `"$SetupDatabaseName`"."
            
            if (New-SqlServerDatabase -SqlServerName $SetupDatabaseServerName -DatabaseName $SetupDatabaseName -Force:$Force.IsPresent -ErrorAction Stop -UserName $SetupDatabaseSqlUser -Password $SetupDatabaseSqlPassword)
            {
                "Database `"$SetupDatabaseServerName\$SetupDatabaseName`" created!"
            }
            else
            {
                if ([string]::IsNullOrEmpty($SetupDatabaseTablePrefix))
                {
                    throw ("Database `"$SetupDatabaseServerName\$SetupDatabaseName`" could not be created!")
                }
                else
                {
                    "The specified database already exists! Attempting to run setup using the `"$SetupDatabaseTablePrefix`" table prefix."
                }
            }

            $Security = if (-not $SetupDatabaseSqlPassword) 
            { 
                "Integrated Security=True"
            }
            else 
            {
                "User Id=$SetupDatabaseSqlUser;Password=$SetupDatabaseSqlPassword"    
            }

            # MARS is necessary for Orchard.
            $SetupDatabaseConnectionString = "Server=$SetupDatabaseServerName;Database=$SetupDatabaseName;$Security;MultipleActiveResultSets=True;"
        }

        

        # Try to find the Launch Settings file to get the launch URL of the application.
        # If not found (or the URL is not found in the settings), and the $Port parameter is set to <=0 then using a random one on localhost instead.

        $launchSettingsFilePath = $("$WebProjectPath\Properties\launchSettings.json")       
        $environmentSetting = "Development"

        if ($Port -le 0)
        {
            $Port = Get-Random -Minimum 2000 -Maximum 64000
        }

        $applicationUrl = "http://localhost:$Port"

        if (Test-Path $launchSettingsFilePath -PathType Leaf)
        {
            $launchSettings = Get-Content $launchSettingsFilePath | ConvertFrom-Json

            $applicationUrlSetting = $launchSettings.profiles."$SiteName".applicationUrl
            
            if (-not [string]::IsNullOrEmpty($applicationUrlSetting))
            {
                $applicationUrlsFromSetting = $applicationUrlSetting -split ";"
                
                $applicationUrlFromSetting = $applicationUrlsFromSetting | Where-Object { $_.StartsWith("http://") }

                if (-not [string]::IsNullOrEmpty($applicationUrlFromSetting))
                {
                    $applicationUrl = $applicationUrlFromSetting.Trim()
                }
            }

            $environmentSetting = $launchSettings.profiles."$SiteName".environmentVariables.ASPNETCORE_ENVIRONMENT

            if ([string]::IsNullOrEmpty($environmentSetting))
            {
                $environmentSetting = "Development"
            }
        }

        
        
        # Launching the .NET application host process.

        $webProjectDllFile = Get-Item -Path $webProjectDllPath
        
        "Starting .NET application host at `"$applicationUrl`"!`n"
                
        $applicationProcess = Start-Process `
            -WorkingDirectory $WebProjectPath `
            dotnet `
            -ArgumentList "$($webProjectDllFile.FullName) --urls $applicationUrl --environment $environmentSetting --webroot wwwroot --AuthorizeOrchardApiRequests true" `
            -PassThru



        # Confirming that the host process has started the application successfully.

        Start-Sleep 2

        $applicationRunning = $false
        do
        {
            Start-Sleep 1

            if ($applicationProcess.HasExited)
            {
                throw "Application host process exited with exit code $($applicationProcess.ExitCode)!`nCheck if another application host process (IIS Express or dotnet) is running under a different user account using the same port and terminate it!"
            }

            $setupScreenResponse = Invoke-WebRequest -Uri $applicationUrl -UseBasicParsing -ErrorAction Stop

            if ($setupScreenResponse.StatusCode -ne 200)
            {
                throw "Application host process started, but the setup screen returned status code $($setupScreenResponse.StatusCode)!"
            }

            $applicationRunning = $true
        }
        until ($applicationRunning)
        
        
        
        # Running setup.

        "Application started, attempting to run setup!`n"

        $tenantSetupSettings = @{
            SiteName = $SetupSiteName
            DatabaseProvider = $SetupDatabaseProvider
            TablePrefix = $SetupDatabaseTablePrefix
            ConnectionString = $SetupDatabaseConnectionString
            RecipeName = $SetupRecipeName
            UserName = $SetupUserName
            Password = $SetupPassword
            Email = $SetupEmail
            Name = $SetupTenantName
        }

        $setupRequest = Invoke-WebRequest -Method Post -Uri "$applicationUrl/api/tenants/setup" -Body (ConvertTo-Json($tenantSetupSettings)) -ContentType "application/json" -UseBasicParsing

        if ($setupRequest.StatusCode -ne 200)
        {
            Stop-Process $applicationProcess

            throw "Setup failed with status code $($setupRequest.StatusCode)!"
        }

        "Setup successful!`n"

        
        
        # Terminating the .NET application host process if Keep Alive is not requested.

        if (-not $KeepAlive.IsPresent)
        {
            "Keep Alive not requested, shutting down application host process!"

            Stop-Process $applicationProcess
        }


        
        if ($Pause.IsPresent)
        {
            pause
        }

        exit 0
    }
             */
        }
        
        /// <summary>
        /// Looking for the Web Project DLL and selecting the latest ASP.NET Core variant if more than one found. 
        /// </summary>
        private string GetWebProjectDllPath(string WebProjectPath)
        {
            var siteName = Path.GetFileName(WebProjectPath);
            var netCoreAppDirectoryPath = Directory
                .GetDirectories(Path.Combine(WebProjectPath, "bin", "Debug"))
                .FirstOrDefault();
            
            if (netCoreAppDirectoryPath == null) return string.Empty;
            var webProjectDllPath = Path.Combine(netCoreAppDirectoryPath, siteName + ".dll");

            return File.Exists(webProjectDllPath)
                ? webProjectDllPath
                : string.Empty;
        }
    }
}