<#
.Synopsis
   Imports a .bacpac file to a database on a local SQL Server instance.

.DESCRIPTION
   Imports a .bacpac file to a database on the default local SQL Server instance. Install the attached Import-BacpacToSqlServer.reg Registry file to add an "Import to SQL Server with PowerShell" right click context menu shortcut for .bacpac files.

.EXAMPLE
   Import-BacpacToSqlServer -BacpacPath "C:\database.bacpac"

.EXAMPLE
   Import-BacpacToSqlServer -BacpacPath "C:\database.bacpac" -DatabaseName "BetterName"

.EXAMPLE
   Import-BacpacToSqlServer -BacpacPath "C:\database.bacpac" -SqlServerName "LocalSqlServer" -DatabaseName "BetterName"

.EXAMPLE
   Import-BacpacToSqlServer -BacpacPath "C:\database.bacpac" -ConnectionString "Data Source=.\SQLEXPRESS;Initial Catalog=NiceDatabase;Integrated Security=True;"
#>


function Import-BacpacToSqlServer
{
    [CmdletBinding(DefaultParameterSetName = "ByServerAndDatabaseName")]
    [Alias("ipbpss")]
    [OutputType([bool])]
    Param
    (
        [Parameter(HelpMessage = "The path to the `"SqlPackage`" executable that performs the import process. When not defined, it will try to find the executable installed with the latest SQL Server.")]
        [Parameter(ParameterSetName = "ByConnectionString")]
        [Parameter(ParameterSetName = "ByServerAndDatabaseName")]
        [string] $SqlPackageExecutablePath = "",

        [Parameter(Mandatory = $true, HelpMessage = "The path to the .bacpac file to import.")]
        [Parameter(ParameterSetName = "ByConnectionString")]
        [Parameter(ParameterSetName = "ByServerAndDatabaseName")]
        [string] $BacpacPath = $(throw "You need to specify the path to the .bacpac file to import."),

        [Parameter(HelpMessage = "The connection string that defines the server and database to import the .bacpfile to. If not defined, it will be built using the `"SqlServerName`" and `"DatabaseName`" variables.")]
        [Parameter(Mandatory = $true, ParameterSetName = "ByConnectionString")]
        [string] $ConnectionString = "",

        [Parameter(HelpMessage = "The name of the SQL Server instance that will host the imported database. If not defined, it will be determined from the system registry.")]
        [Parameter(ParameterSetName = "ByServerAndDatabaseName")]
        [string] $SqlServerName = "",

        [Parameter(HelpMessage = "The name of the database that will be created for the imported .bacpac file. If not defined, it will be the name of the imported file.")]
        [Parameter(ParameterSetName = "ByServerAndDatabaseName")]
        [string] $DatabaseName = ""
    )

    Process
    {
        # Setting up SQL Package executable path.
        $sqlPackageExecutablePath = ""
        if (![string]::IsNullOrEmpty($SqlPackageExecutablePath) -and (Test-Path $SqlPackageExecutablePath))
        {
            $sqlPackageExecutablePath = $SqlPackageExecutablePath
        }
        else
        {
            if (![string]::IsNullOrEmpty($SqlPackageExecutablePath))
            {
                Write-Warning ("SQL Package executable for importing the database is not found at `"$path`"! Trying to locate default SQL Package executables...")    
            }

            $defaultSqlPackageExecutablePath = ""
            for ($i = 20; $i -ge 12; $i--)
            {
                $defaultSqlPackageExecutablePath = "C:\Program Files\Microsoft SQL Server\$($i)0\DAC\bin\SqlPackage.exe"
                if (Test-Path $defaultSqlPackageExecutablePath)
                {
                    $sqlPackageExecutablePath = $defaultSqlPackageExecutablePath
                    Write-Host ("`nSQL Package executable for importing the database found at `"$sqlPackageExecutablePath`"!`n")
                    break
                }

                $defaultSqlPackageExecutablePath = "C:\Program Files (x86)\Microsoft SQL Server\$($i)0\DAC\bin\SqlPackage.exe"
                if (Test-Path $defaultSqlPackageExecutablePath)
                {
                    $sqlPackageExecutablePath = $defaultSqlPackageExecutablePath
                    Write-Host ("`nSQL Package executable for importing the database found at `"$sqlPackageExecutablePath`"!`n")
                    break
                }
            }
        }

        if ([string]::IsNullOrEmpty($sqlPackageExecutablePath))
        {
            throw ("No SQL Package executable found for importing the database!")
        }



        # Checking the validity of the bacpac file.
        $bacpacFile = Get-Item $BacpacPath
        if ($bacpacFile -eq $null -or !($bacpacFile -is [System.IO.FileInfo]) -or !($bacpacFile.Extension -eq ".bacpac"))
        {
            throw ("The .bacpac file is not found at `"$BacpacPath`"!")
        }



        # Given that the parameter set uses the ConnectionString, we're deconstructing it to check its validity.
        if ($PSCmdlet.ParameterSetName -eq "ByConnectionString")
        {
            $connectionStringSegments = $ConnectionString.Split(';', [System.StringSplitOptions]::RemoveEmptyEntries)

            $serverSegment = $connectionStringSegments | Where-Object { $PSItem.StartsWith("Data Source=") }
            if (!([string]::IsNullOrEmpty($serverSegment)))
            {
                $SqlServerName = $serverSegment.Split('=', [System.StringSplitOptions]::RemoveEmptyEntries)[1]
            }

            $databaseSegment = $connectionStringSegments | Where-Object { $PSItem.StartsWith("Initial Catalog=") }
            if (!([string]::IsNullOrEmpty($databaseSegment)))
            {
                $DatabaseName = $databaseSegment.Split('=', [System.StringSplitOptions]::RemoveEmptyEntries)[1]
            }
        }


        
        # Checking the validity of the SqlServerName variable.
        [System.Reflection.Assembly]::LoadWithPartialName("Microsoft.SqlServer.Smo") | Out-Null
        $DataSource = ""
        $invalidSqlServer = $false

        # SqlServerName is not defined, so let's try to find one.
        if ([string]::IsNullOrEmpty($SqlServerName))
        {
            $DataSource = ".\$(Get-DefaultSqlServerName)"
        }
        else
        {
            $DataSource = ".\$SqlServerName"
        }

        if (!(Test-SqlServer $DataSource))
        {
            Write-Warning ("Could not find SQL Server at `"$DataSource`"!")
            $DataSource = "localhost"

            if (!(Test-SqlServer $DataSource))
            {
                throw ("Could not find any SQL Server instances!")
            }
        }



        # Checking DatabaseName validity and handling if there's already a database with this name on the target server.
        if ([string]::IsNullOrEmpty($DatabaseName))
        {
            $DatabaseName = $bacpacFile.BaseName
        }

        $databaseExists = Test-SqlServerDatabase -SqlServerName $DataSource -DatabaseName $DatabaseName
        if ($databaseExists)
        {
            $originalDatabaseName = $DatabaseName
            $DatabaseName += "-" + [System.Guid]::NewGuid()
        }



        # And now we get to actually importing the database after constructing a connection string with validated details.
        $ConnectionString = "Data Source=$DataSource;Initial Catalog=$DatabaseName;Integrated Security=True;"
        & "$sqlPackageExecutablePath" /Action:Import /SourceFile:"$BacpacPath" /TargetConnectionString:"$ConnectionString"



        # Importing the database was successful.
        if ($LASTEXITCODE -eq 0)
        {
            # If there was a database with an identical name on the target server, we'll swap it with the one we've just imported.
            if ($databaseExists)
            {
                $server = New-Object ("Microsoft.SqlServer.Management.Smo.Server") $DataSource
                $server.KillAllProcesses($originalDatabaseName)
                $server.Databases[$originalDatabaseName].Drop()
                $server.Databases[$DatabaseName].Rename($originalDatabaseName)

                Write-Warning ("The original database with the name `"$originalDatabaseName`" has been deleted and the imported one has been renamed to use that name.")
            }
        }
        # Importing the database failed.
        else
        {
            if ($databaseExists)
            {
                Write-Warning ("The database `"$originalDatabaseName`" remains intact and depending on the error in the import process, a new database may have been created with the name `"$DatabaseName`"!")
            }

            throw ("Importing the database failed!")
        }
    }
}