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
        [string] $ServerName,

        [string] $UserName = $null,

        [SecureString] $Password = $null
    )

    Process
    {
        $Connection = New-SqlServerConnection $ServerName $UserName $Password

        return $null -ne (New-Object ("Microsoft.SqlServer.Management.Smo.Server") $Connection).InstanceName
    }
}