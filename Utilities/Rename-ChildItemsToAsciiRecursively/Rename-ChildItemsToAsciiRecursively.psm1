function Rename-ChildItemsToAsciiRecursively
{
    Param
    (
        [Parameter(ValueFromPipelineByPropertyName = $true, Position = 0)]
        [string] $Path = (Get-Location).Path
    )

    Process
    {
        Get-ChildItem $Path -Directory -Recurse | ForEach-Object {
            $asciiName = [System.Text.Encoding]::ASCII.GetString([System.Text.Encoding]::ASCII.GetBytes($PSItem.Name)).Replace('?', '_')

            if ($PSItem.Name -eq $asciiName) { return }

            # If there's already a folder with the new name of the current one.
            if (Test-Path (Join-Path $PSItem.Parent.FullName $asciiName))
            {
                # Move the contents of the current folder to the other one with the new name.
                Get-ChildItem $PSItem.FullName -Recurse | Move-Item -Destination (Join-Path $PSItem.Parent.FullName $asciiName)

                # Then delete the current folder.
                Remove-Item $PSItem.FullName
            }
            else
            {
                Write-Verbose "Renaming `"$($_.FullName)`" to `"$asciiName`"."
                $PSItem | Rename-Item -NewName $asciiName

                New-Object PSObject -Property @{ Original = $PSItem.FullName; Renamed = $asciiName }
            }
        }

        Get-ChildItem $Path -File -Recurse | ForEach-Object {
            $asciiName = [System.Text.Encoding]::ASCII.GetString([System.Text.Encoding]::ASCII.GetBytes($PSItem.Name)).Replace('?', '_')

            if ($PSItem.Name -eq $asciiName) { return }

            Write-Verbose "Renaming `"$($_.FullName)`" to `"$asciiName`"."
            $PSItem | Rename-Item -NewName $asciiName

            New-Object PSObject -Property @{ Original = $PSItem.FullName; Renamed = $asciiName }
        }
    }
}
