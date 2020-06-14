<#
.Synopsis
   Tests the connection to a local SQL Server instance.
#>


[System.Reflection.Assembly]::LoadWithPartialName("Microsoft.SqlServer.Smo") | Out-Null

function Test-SqlServer
{
    [CmdletBinding()]
    [Alias("tss")]
    [OutputType([bool])]
    Param
    (
        [Parameter(Mandatory = $true)]
        [string] $ServerName
    )

    Process
    {
        return (New-Object ("Microsoft.SqlServer.Management.Smo.Server") $ServerName).InstanceName -ne $null
    }
}