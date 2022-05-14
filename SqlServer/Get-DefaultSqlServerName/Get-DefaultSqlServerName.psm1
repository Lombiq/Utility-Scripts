<#
.Synopsis
   Gets the name of the default local SQL Server instance.
#>


[System.Reflection.Assembly]::LoadWithPartialName("Microsoft.SqlServer.Smo") | Out-Null

function Get-DefaultSqlServerName
{
    [CmdletBinding()]
    [Alias("gdssm")]
    [OutputType([string])]
    Param()

    Process
    {
        $serverServices = (Get-WmiObject win32_Service -Computer $env:COMPUTERNAME | Where-Object { $PSItem.Name -match "MSSQL" -and $PSItem.PathName -match "sqlservr.exe" })
        $servicePath = ""

        # No SQL Servers installed.
        if ($serverServices -eq $null)
        {
            throw ("Could not find any SQL Server services!")
        }
        # Only one SQL Server installed.
        elseif ($serverServices.Count -eq $null)
        {
            $servicePath = $serverServices.PathName
        }
        # More than one SQL Servers installed and one of them is named "MSSQLSERVER" (default name), so let's choose that.
        elseif (($serverServices | Where-Object { $PSItem.Name -eq "MSSQLSERVER" }) -ne $null)
        {
            $servicePath = ($serverServices | Where-Object { $PSItem.Name -eq "MSSQLSERVER" }).PathName
        }
        # More than one SQL Servers installed, choosing the first one.
        else
        {
            $servicePath = $serverServices[0].PathName
        }

        return $servicePath.Substring($servicePath.LastIndexOf(" -s") + 3)
    }
}