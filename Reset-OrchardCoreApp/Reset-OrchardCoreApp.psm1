function Reset-OrchardCoreApp
{
    [CmdletBinding()]
    Param
    (
        [Parameter(Mandatory=$true,
                   ValueFromPipelineByPropertyName=$true,
                   Position=0)]
        [string] $WebProjectPath,

        [switch] $Rebuild,

        [switch] $KeepAlive,

        [string] $SetupSiteName = "Orchard Core",
        [string] $SetupDatabaseProvider = "Sqlite",
        [string] $SetupRecipeName = "Blog",
        [string] $SetupUserName = "admin",
        [string] $SetupPassword = "Password1!",
        [string] $SetupEmail = "admin@localhost"
    )

    Process
    {
        # Checking if the Web Project Path is valid and extracting the name of the Web Project.

        if (-not (Test-Path -Path $WebProjectPath -PathType Container))
        {
            throw "The specified Web Project Path is not found or not accessible!`n$WebProjectPath"
        }

        $siteName = Split-Path $WebProjectPath -Leaf

        
        
        # Trying to find IIS Express and .NET host processes that run a Web Project with a matching name and terminate them.

        foreach ($siteHostProcess in Get-WmiObject Win32_Process -Filter "(Name = 'iisexpress.exe' or Name = 'dotnet.exe') and CommandLine like '%$siteName%'")
        {
            "Terminating application host process running `"$($siteHostProcess.CommandLine)`"!`n"

            $siteHostProcess.Terminate() | Out-Null
        }



        # Delete App_Data if exists.

        $appDataPath = $("$WebProjectPath\App_Data")

        if (Test-Path $appDataPath -PathType Container)
        {
            "Deleting App_Data folder found in `"$WebProjectPath`"!`n"

            Remove-Item $appDataPath -Force -Recurse
        }        
        


        # Rebuilding the application if the "Rebuild" switch is present or the Web Project DLL is not found.

        $webProjectDllPath = GetWebProjectDllPath($WebProjectPath)

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

        

        # Try to find the Launch Settings file to get the launch URL of the application.
        # If not found (or the URL is not found in the settings), then using a random port number on localhost instead.

        $launchSettingsFilePath = $("$WebProjectPath\Properties\launchSettings.json")
        $applicationUrl = "http://localhost:$(Get-Random -Minimum 2000 -Maximum 64000)"

        if (Test-Path $launchSettingsFilePath -PathType Leaf)
        {
            $launchSettings = Get-Content $launchSettingsFilePath | ConvertFrom-Json

            $applicationUrlSetting = $launchSettings.profiles."$SiteName".applicationUrl
            
            if (-not [string]::IsNullOrEmpty($applicationUrlSetting))
            {
                $applicationUrlsFromSetting = $applicationUrlSetting -split ";"
                
                $applicationUrlFromSetting = $applicationUrlsFromSetting | Where-Object { $_.StartsWith("https://") }

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
                
        $applicationProcess = Start-Process -WorkingDirectory $WebProjectPath dotnet -ArgumentList "$($webProjectDllFile.FullName) --urls $applicationUrl --environment $environmentSetting" -PassThru
        $applicationWindowsProcess = Get-WmiObject Win32_Process -Filter "ProcessId = '$($applicationProcess.Id)'"



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

            $setupScreenResponse = Invoke-WebRequest -Uri $applicationUrl -ErrorAction Stop

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
            RecipeName = $SetupRecipeName
            UserName = $SetupUserName
            Password = $SetupPassword
            Email = $SetupEmail
            Name = "Default"
        }

        $setupRequest = Invoke-WebRequest -Method Post -Uri "$applicationUrl/api/tenants/setup" -Body (ConvertTo-Json($tenantSetupSettings)) -ContentType "application/json"

        if ($setupRequest.StatusCode -ne 200)
        {
            Stop-Process $applicationProcess

            throw "Setup failed with status code $($setupScreenResponse.StatusCode)!"
        }

        "Setup successful!`n"

        
        
        # Terminating the .NET application host process if Keep Alive is not requested.

        if (-not $KeepAlive.IsPresent)
        {
            "Keep Alive not requested, shutting down application host process!"

            Stop-Process $applicationProcess
        }


        
        pause

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