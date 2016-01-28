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
        [string] $SqlPackageExecutablePath = "C:\Program Files (x86)\Microsoft SQL Server\120\DAC\bin\SqlPackage.exe",

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
        if (!(Test-Path $SqlPackageExecutablePath))
        {
            throw ("The executable for importing the database is not found at `"$SqlPackageExecutablePath`"!")
        }

        $bacpacFile = Get-Item $BacpacPath

        if ($bacpacFile -eq $null -or !($bacpacFile -is [System.IO.FileInfo]) -or !($bacpacFile.Extension -eq ".bacpac"))
        {
            throw ("The .bacpac file is not found at `"$BacpacPath`"!")
        }

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

                $SqlServerName = $servicePath.Substring($servicePath.LastIndexOf("-s") + 2)
                $DataSource = ".\$SqlServerName"

                [System.Reflection.Assembly]::LoadWithPartialName("Microsoft.SqlServer.Smo") | Out-Null
                $server = New-Object ("Microsoft.SqlServer.Management.Smo.Server") ".\$SqlServerName"

                if ($server.InstanceName -eq $null)
                {
                    if ((New-Object ("Microsoft.SqlServer.Management.Smo.Server") "localhost").InstanceName -eq $null)
                    {
                        throw ("Could not find any SQL Server instances!")
                    }

                    $SqlServerName = "localhost"
                    $DataSource = $SqlServerName
                }
            }
            else
            {
                $DataSource = ".\$SqlServerName"
            }

            if ([string]::IsNullOrEmpty($DatabaseName))
            {
                $DatabaseName = $bacpacFile.BaseName
            }

            $ConnectionString = "Data Source=$DataSource;Initial Catalog=$DatabaseName;Integrated Security=True;"
        }

        & "$SqlPackageExecutablePath" /Action:Import /SourceFile:"$BacpacPath" /TargetConnectionString:"$ConnectionString"

        return $true
    }
}