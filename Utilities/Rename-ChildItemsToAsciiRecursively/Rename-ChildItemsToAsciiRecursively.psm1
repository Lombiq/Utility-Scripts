function Rename-ChildItemsToAsciiRecursively
{
    Param
    (
        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true, Position = 0)]
        [string] $Path
    )

    Process
    {
        foreach ($item in Get-ChildItem $Path)
        {
            if ($item.PSIsContainer)
            {
                Rename-ChildItemsToAsciiRecursively -Path $item.FullName
            }

            $asciiName = [System.Text.Encoding]::ASCII.GetString([System.Text.Encoding]::ASCII.GetBytes($item.Name)).Replace('?', '_')

            if ($item.Name -ne $asciiName)
            {
                Write-Verbose "Renaming `"$($item.FullName)`" to `"$asciiName`"."
                $item | Rename-Item -NewName $asciiName
            }
        }
    }
}