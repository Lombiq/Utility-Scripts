function Get-VisualStudioProjectNuGetPackage
{
    [CmdletBinding()]
    param
    (
        # The absolute path to a Visual Studio project file.
        [Parameter(Mandatory = $true)]
        [string]
        $Path,

        # Wildcard-enabled expression to filter package names.
        [string]
        $PackageNameFilter
    )

    process
    {
        $pathItem = Get-Item -Path $Path

        if ($pathItem -isnot [System.IO.FileInfo] -or $pathItem.Extension -ne ".csproj")
        {
            throw "The path `"$Path`" does not point to a Visual Studio project file!"
        }

        $packageTextList = dotnet list $pathItem.FullName package

        $packageList = $packageTextList | ForEach-Object { $_.Trim() } | Where-Object { $_.StartsWith(">") } | ForEach-Object `
        {
            $packageTextLineSegments = $_.Trim().TrimStart(">").TrimStart().Split(" ", [System.StringSplitOptions]::RemoveEmptyEntries)

            New-Object PSObject -Property `
            @{
                Name             = $packageTextLineSegments[0]
                RequestedVersion = $packageTextLineSegments[1]
                ResolvedVersion  = $packageTextLineSegments[2]
            }
        }

        if (-not [string]::IsNullOrEmpty($PackageNameFilter))
        {
            $packageList = $packageList | Where-Object { $_.Name -like "$PackageNameFilter" }
        }

        $packageList
    }
}
