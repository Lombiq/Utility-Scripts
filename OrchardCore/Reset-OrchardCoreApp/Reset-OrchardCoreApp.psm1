<#
.Synopsis
   Resets and sets up an Orchard Core application.

.DESCRIPTION
   Resets an Orchard Core application to its blank state even if it's running, then runs its setup with the given parameters. Note that for the setup to work you'll need to configure the app to accept unauthenticated API requests for the duration of the setup; you can do this with Setup Extensions: https://github.com/Lombiq/Setup-Extensions#logged-in-user-authentication-for-api-requests.

.EXAMPLE
   Reset-OrchardCoreApp -WebProjectPath "." -SetupSiteName "FancyWebsite" -SetupRecipeName "FancyWebsite.DevelopmentSetup"
#>


function Reset-OrchardCoreApp
{
    [CmdletBinding(DefaultParameterSetName = "FileDB")]
    Param
    (
        [Parameter(Mandatory, ValueFromPipelineByPropertyName, Position = 0)]
        [string] $WebProjectPath,        
        
        [string] $SetupSiteName = "Orchard Core",
        [string] $SetupTenantName = "Default",
        [string] $SetupRecipeName = "Blog",
        [string] $SetupUserName = "admin",
        [string] $SetupPassword = "Password1!",
        [string] $SetupEmail = "admin@localhost",


        [int] $Port = 5000,

        
        [Parameter(ParameterSetName = "ServerDB", Mandatory)]
        [string] [ValidateSet("SqlConnection")] $SetupDatabaseProvider = "Sqlite",

        [Parameter(ParameterSetName = "ServerDB")]
        [string] $SetupDatabaseTablePrefix = "",
        
        [Parameter(ParameterSetName = "ServerDB")]
        [string] $SetupDatabaseServerName = ".",
        
        [Parameter(ParameterSetName = "ServerDB")]
        [string] $SetupDatabaseName = "OrchardCore",
        
        [Parameter(ParameterSetName = "ServerDB")]
        [string] $SetupDatabaseSqlUser = "sa",
        
        [Parameter(ParameterSetName = "ServerDB")]
        [string] $SetupDatabaseSqlPassword = $null,

        [Parameter(ParameterSetName = "ServerDB")]
        [switch] $Force,
        
        [Parameter(ParameterSetName = "ServerDB")]
        [switch] $SuffixDatabaseNameWithFolderName,

        
        [switch] $Rebuild,
        [switch] $KeepAlive,
        [switch] $Pause
    )

    Process
    {
        # Checking if the Web Project Path is valid and extracting the name of the Web Project.

        if (Test-Path -Path $WebProjectPath -PathType Leaf)
        {
            $webProjectDllPath = $WebProjectPath;
            $siteName = (Get-Item $WebProjectPath).BaseName
            $WebProjectPath = (Get-Item $WebProjectPath).DirectoryName
        }
        elseif (-not (Test-Path -Path $WebProjectPath -PathType Container))
        {
            throw "The specified Web Project Path is not found or not accessible!`n$WebProjectPath"
        }
        else
        {
            $webProjectDllPath = GetWebProjectDllPath($WebProjectPath)
            $siteName = Split-Path $WebProjectPath -Leaf
        }

        
        
        # Trying to find IIS Express and .NET host processes that run a Web Project with a matching name and terminate them.
        Import-Module "$env:LOMBIQ_UTILITY_SCRIPTS_PATH\src\Lombiq.UtilityScripts.Utilities\bin\Debug\netstandard2.0\Lombiq.UtilityScripts.Utilities.dll"
        Get-ProcessByArgument $siteName | Stop-Process



        # Delete App_Data if exists.

        $appDataPath = $("$WebProjectPath\App_Data")

        if (Test-Path $appDataPath -PathType Container)
        {
            "Deleting App_Data folder found in `"$WebProjectPath`"!`n"

            Remove-Item $appDataPath -Force -Recurse
        }        
        


        # Rebuilding the application if the "Rebuild" switch is present or the Web Project DLL is not found.

        $buildRequired = $false;
        if ($Rebuild.IsPresent)
        {
            "Rebuild switch active!`n"

            $buildRequired = $true
        }
        elseif ([string]::IsNullOrEmpty($webProjectDllPath) -or -not (Test-Path $webProjectDllPath -PathType Leaf))
        {
            "Web Project DLL not found, build is required!`n"

            $buildRequired = $true
        }

        if ($buildRequired)
        {
            dotnet build "$WebProjectPath" --configuration Debug

            if ($LASTEXITCODE -ne 0)
            {
                pause

                exit $LASTEXITCODE
            }
            else
            {
                $webProjectDllPath = GetWebProjectDllPath($WebProjectPath)

                if ([string]::IsNullOrEmpty($webProjectDllPath))
                {
                    throw "Project was successfully built at `"$WebProjectPath`", but the compiled Web Project DLL was not found!"
                }
            }
        }

        "Compiled Web Project DLL found at `"$webProjectDllPath`"!`n"



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
}



# Looking for the Web Project DLL and selecting the latest ASP.NET Core variant if more than one found.

function GetWebProjectDllPath([string] $WebProjectPath)
{
    $siteName = Split-Path $WebProjectPath -Leaf
    $webProjectDllPathPattern = "$WebProjectPath\bin\Debug\netcoreapp*\$SiteName.dll"

    # To avoid Resolve-Path from throwing exception if no path matches the pattern.
    if (Test-Path $webProjectDllPathPattern)
    {
        # For some reason it only works with the Relative switch, which affects the output without changing the input.
        $webProjectDllPaths = Resolve-Path -Path $webProjectDllPathPattern -Relative

        if ($webProjectDllPaths.GetType() -eq [string])
        {
            $webProjectDllPath = $webProjectDllPaths
        }
        elseif ($webProjectDllPaths.GetType() -eq [object[]])
        {
            $webProjectDllPath = ($webProjectDllPaths | Sort-Object -Descending)[0]
        }

        # Removing the ".\" prepended by the Relative switch of the Resolve-Path command.
        return $webProjectDllPath.Substring(2)
    }

    return "";
}
