<#
.Synopsis
   Creates a new SQL Server connection object.
#>

[System.Reflection.Assembly]::LoadWithPartialName("Microsoft.SqlServer.ConnectionInfo")

function New-SqlServerConnection
{
    [CmdletBinding()]
    Param
    (
        [Parameter(Mandatory = $true)]
        [string] $ServerName,

        [string] $UserName = $null,

        [SecureString] $Password = $null
    )

    Process
    {
        if (-not $UserName -or -not $Password)
        {
            New-Object -TypeName Microsoft.SqlServer.Management.Common.ServerConnection -ArgumentList $ServerName
        }
        else
        {
            New-Object -TypeName Microsoft.SqlServer.Management.Common.ServerConnection -ArgumentList $ServerName, $UserName, $Password
        }
    }
}
