function Rename-ChildItemsToAsciiRecursively
{
    Param
    (
        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true, Position = 0)]
        [string] $Path
    )

    Process
    {
        Get-ChildItem $Path -Recurse | ForEach-Object {
            $asciiName = [System.Text.Encoding]::ASCII.GetString([System.Text.Encoding]::ASCII.GetBytes($PSItem.Name)).Replace('?', '_')

            if ($PSItem.Name -eq $asciiName) { return }

            Write-Verbose "Renaming `"$($_.FullName)`" to `"$asciiName`"."
            $PSItem | Rename-Item -NewName $asciiName

            New-Object PSObject -Property @{ Original = $PSItem.FullName; Renamed = $asciiName }
        }
    }
}