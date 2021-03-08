<#
.Synopsis
   Creates a new database on the given SQL Server instance, after dropping it first if it already exists.
#>


[System.Reflection.Assembly]::LoadWithPartialName("Microsoft.SqlServer.Smo") | Out-Null

function New-SqlServerDatabase
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

        [switch] $Force,
        
        [string] $UserName = $null,

        [string] $Password = $null
    )

    Process
    {
        $server = New-SqlServerConnection $SqlServerName $UserName $Password

        if (Test-SqlServerDatabase -SqlServerName $SqlServerName -DatabaseName $DatabaseName -UserName $UserName -Password $Password)
        {
            if ($Force.IsPresent)
            {
                Write-Warning ("Dropping database `"$SqlServerName\$DatabaseName`"!")

                $server.KillAllProcesses($DatabaseName)
                $server.Databases[$DatabaseName].Drop()
            }
            else
            {
                Write-Warning ("A database with the name `"$DatabaseName`" already exists on the SQL Server at `"$SqlServerName`". Use the `"-Force`" switch to drop it and create a new database with that name.")

                return $false
            }
        }

        try
        {
            (New-Object -TypeName Microsoft.SqlServer.Management.Smo.Database -ArgumentList $server, $DatabaseName).Create()
        }
        catch
        {
            throw "Could not create `"$SqlServerName\$DatabaseName`"!`n$($_.Exception.Message)"
        }

        return $true
    }
}