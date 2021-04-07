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
        [string] $DatabaseName,

        [string] $UserName = $null,

        [string] $Password = $null
    )

    Process
    {
        if (!(Test-SqlServer $SqlServerName $UserName $Password))
        {
            throw ("Could not find SQL Server at `"$SqlServerName`"!")
        }

        $server = New-SqlServerConnection $SqlServerName $UserName $Password
        $server.Connect()
        
        # This works even for remote servers when $server.Databases returns empty.
        $databases = New-Object "System.Collections.Generic.HashSet[string]"
        $reader = $server.ExecuteReader("SELECT name FROM sys.databases")
        while ($reader.Read()) { $databases.Add($reader.GetString(0).ToUpperInvariant()) }
        
        $reader.Close()
        $server.Disconnect()

        return $databases.Contains($DatabaseName.ToUpperInvariant())
    }
}