<#
.Synopsis
   Imports a .bacpac file to a database on a local SQL Server instance.

.DESCRIPTION
   Imports a .bacpac file to a database on a local SQL Server instance.

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
    [CmdletBinding()]
    [Alias("ipbpss")]
    [OutputType([bool])]
    Param
    (
        [Parameter(HelpMessage = "The path to the `"SqlPackage`" executable that performs the import process. The default value references the executable installed with SQL Server 2014.")]
        [string] $SqlPackageExecutablePath,

        [Parameter(Mandatory = $true, HelpMessage = "The path to the .bacpac file to import.")]
        [string] $BacpacPath = $(throw "You need to specify the path to the .bacpac file to import."),

        [Parameter(HelpMessage = "The connection string that defines the server and database to import the .bacpfile to. If not defined, it will be build using the `"SqlServerName`" and `"DatabaseName`" variables.")]
        [string] $ConnectionString,

        [Parameter(HelpMessage = "The name of the SQL Server instance that will host the imported database. If not defined, it will be determined from the system registry.")]
        [string] $SqlServerName,

        [Parameter(HelpMessage = "THe name of the database that will be created for the imported .bacpac file. If not defined, it will be the name of the imported file.")]
        [string] $DatabaseName
    )

    Process
    {
        $sqlPackageExecutablePaths = @()
        if (![string]::IsNullOrEmpty($SqlPackageExecutablePath))
        {
            $sqlPackageExecutablePaths += $SqlPackageExecutablePath
        }

        for ($i = 13; $i -ge 11; $i--)
        { 
            $sqlPackageExecutablePaths += "C:\Program Files (x86)\Microsoft SQL Server\$($i)0\DAC\bin\SqlPackage.exe"
        }

        $SqlPackageExecutablePath = ""
        foreach ($path in $sqlPackageExecutablePaths)
        {
            if (Test-Path $path)
            {
                $SqlPackageExecutablePath = $path
                Write-Host ("`nSQL Package executable for importing the database found at `"$path`"!`n")
                break
            }
            else
            {
                Write-Warning ("SQL Package executable for importing the database is not found at `"$path`"!")
            }
        }

        if ([string]::IsNullOrEmpty($SqlPackageExecutablePath))
        {
            throw ("No SQL Package executable found for importing the database!")
        }



        $bacpacFile = Get-Item $BacpacPath

        if ($bacpacFile -eq $null -or !($bacpacFile -is [System.IO.FileInfo]) -or !($bacpacFile.Extension -eq ".bacpac"))
        {
            throw ("The .bacpac file is not found at `"$BacpacPath`"!")
        }

        [System.Reflection.Assembly]::LoadWithPartialName("Microsoft.SqlServer.Smo") | Out-Null

        if ([string]::IsNullOrEmpty($ConnectionString))
        {
            $DataSource = ""
            
            if ([string]::IsNullOrEmpty($SqlServerName))
            {
                $serverServices = (Get-WmiObject win32_Service -Computer $env:COMPUTERNAME | Where-Object { $PSItem.Name -match "MSSQL" -and $PSItem.PathName -match "sqlservr.exe" })
                $servicePath = ""

                if ($serverServices -eq $null)
                {
                    throw ("Could not find any SQL Server services!")
                }
                elseif ($serverServices.Count -eq $null)
                {
                    $servicePath = $serverServices.PathName
                }
                else
                {
                    $servicePath = $serverServices[0].PathName
                }

                $DataSource = ".\" + $servicePath.Substring($servicePath.LastIndexOf(" -s") + 3)

                if (!(ConfirmSqlServer($DataSource)))
                {
                    $DataSource = "localhost"

                    if (!(ConfirmSqlServer($DataSource)))
                    {
                        throw ("Could not find any SQL Server instances!")
                    }
                }
            }
            else
            {
                $DataSource = ".\$SqlServerName"

                if (!(ConfirmSqlServer($DataSource)))
                {
                    throw ("The specified name of the SQL Server is invalid!")
                }
            }

            if ([string]::IsNullOrEmpty($DatabaseName))
            {
                $DatabaseName = $bacpacFile.BaseName
            }

            $server = New-Object ("Microsoft.SqlServer.Management.Smo.Server") $DataSource

            $databaseExists = ($server.Databases | Where-Object { $PSItem.Name -eq $DatabaseName }) -ne $null

            if ($databaseExists)
            {
                $originalDatabaseName = $DatabaseName
                $DatabaseName += "-" + [System.Guid]::NewGuid()
            }

            $ConnectionString = "Data Source=$DataSource;Initial Catalog=$DatabaseName;Integrated Security=True;"
        }

        & "$SqlPackageExecutablePath" /Action:Import /SourceFile:"$BacpacPath" /TargetConnectionString:"$ConnectionString"

        if ($LASTEXITCODE -eq 0)
        {
            if ($databaseExists)
            {
                $server = New-Object ("Microsoft.SqlServer.Management.Smo.Server") $DataSource
                $server.KillAllProcesses($originalDatabaseName)
                $server.Databases[$originalDatabaseName].Drop()
                $server.Databases[$DatabaseName].Rename($originalDatabaseName)

                Write-Warning ("The original database with the name `"$originalDatabaseName`" has been deleted and the imported one has been renamed to use that name.")
            }
        }
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


function ConfirmSqlServer
{
    param
    (
        [string] $ServerName
    )
    process
    {
        return (New-Object ("Microsoft.SqlServer.Management.Smo.Server") $ServerName).InstanceName -ne $null
    }
}