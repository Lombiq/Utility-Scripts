<#
.Synopsis
   Checks whether the given database exists in a local SQL Server instance.
#>


[System.Reflection.Assembly]::LoadWithPartialName("Microsoft.SqlServer.Smo") | Out-Null

function Test-SqlServerDatabase
{
    [CmdletBinding()]
    [Alias("tssd")]
    [OutputType([bool])]
    Param
    (
        [Parameter(Mandatory = $true)]
        [string] $SqlServerName,

        [Parameter(Mandatory = $true)]
        [string] $DatabaseName
    )

    Process
    {
        if (!(Test-SqlServer $SqlServerName))
        {
            throw ("Could not find SQL Server at `"$SqlServerName`"!")
        }

        $server = New-Object ("Microsoft.SqlServer.Management.Smo.Server") $SqlServerName
        return ($server.Databases | Where-Object { $PSItem.Name -eq $DatabaseName }) -ne $null
    }
}