function Rename-ChildItemsToAsciiRecursively
{
    Param
    (
        [Parameter(ValueFromPipelineByPropertyName = $true, Position = 0)]
        [string] $Path = (Get-Location).Path
    )

    Process
    {
        $pathLength = $Path.Length + 1

        Get-ChildItem $Path -Directory -Recurse | ForEach-Object {
            $asciiName = Get-AsciiName($PSItem.Name)

            if ($PSItem.Name -eq $asciiName) { return }

            # If there's already a folder with the new name of the current one.
            if (Test-Path (Join-Path $PSItem.Parent.FullName $asciiName))
            {
                Write-Verbose "Moving the contents of '$($PSItem.FullName)' to '$asciiName'."

                # Move the contents of the current folder to the other one with the new name.
                Get-ChildItem $PSItem.FullName -Recurse | Move-Item -Destination (Join-Path $PSItem.Parent.FullName $asciiName)

                # Then delete the current folder.
                Remove-Item $PSItem.FullName

                return
            }

            Write-Verbose "Renaming '$($PSItem.FullName)' to '$asciiName'."

            $PSItem | Rename-Item -NewName $asciiName

            New-Object PSObject -Property @{ Original = $PSItem.FullName.Substring($pathLength); Renamed = $asciiName }
        }

        Get-ChildItem $Path -File -Recurse | ForEach-Object {
            $asciiName = Get-AsciiName($PSItem.Name)

            if ($PSItem.Name -eq $asciiName) { return }

            Write-Verbose "Renaming '$($PSItem.FullName)' to '$asciiName'."

            $PSItem | Rename-Item -NewName $asciiName

            New-Object PSObject -Property @{ Original = $PSItem.FullName.Substring($pathLength); Renamed = $asciiName }
        }
    }
}

function Get-AsciiName([string] $name)
{
    return [System.Text.Encoding]::ASCII.GetString([System.Text.Encoding]::ASCII.GetBytes($name)).Replace('?', '_')
}
