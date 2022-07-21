function Rename-ChildItemsToAsciiRecursively
{
    Param
    (
        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true, Position = 0)]
        [string] $Path
    )

    Process
    {
        Get-ChildItem $Path -Recurse | % {
            $asciiName = [System.Text.Encoding]::ASCII.GetString([System.Text.Encoding]::ASCII.GetBytes($_.Name)).Replace('?', '_')

            if ($_.Name -eq $asciiName) { return }

            Write-Verbose "Renaming `"$($_.FullName)`" to `"$asciiName`"."
            $_ | Rename-Item -NewName $asciiName

            New-Object PSObject -Property @{ Original = $_.FullName; Renamed = $asciiName }
        }
    }
}