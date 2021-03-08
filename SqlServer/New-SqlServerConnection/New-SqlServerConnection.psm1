<#
.Synopsis
   Creates a new Sql Server connection object.
#>


[System.Reflection.Assembly]::LoadWithPartialName("Microsoft.SqlServer.Smo") | Out-Null

function New-SqlServerConnection
{
    [CmdletBinding()]
    [OutputType([bool])]
    Param
    (
        [Parameter(Mandatory = $true)]
        [string] $ServerName,

        [string] $UserName = $null,

        [string] $Password = $null
    )

    Process
    {
        if (-not $UserName -or -not $Password) 
        {
            New-Object ("Microsoft.SqlServer.Management.Common.ServerConnection") $ServerName
        }
        else
        {
            New-Object ("Microsoft.SqlServer.Management.Common.ServerConnection") $ServerName, $UserName, $Password
        }
    }
}