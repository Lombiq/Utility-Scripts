<#
.SYNOPSIS
    Returns the NuGet packages referenced by the provided C# project file.
.DESCRIPTION
    This cmdlet uses "dotnet list project.csproj package" to get the name, requested version and resolved version of the
    NuGet packages in the provided C# project. It returns a PSObject array with properties Name, Requested and Resolved.
    If -PackageNameFilter is used, the results names are checked with the -like operator.
.NOTES
    All properties are [string] and the versions may contain pre-release suffixes making them incompatible with the
    [Version] type unless you split off the part after the dash.
.EXAMPLE
    Get-VisualStudioProjectNuGetPackage -Path project.csproj -PackageNameFilter Microsoft*
    Name                                       Requested Resolved
    ----                                       --------- --------
    Microsoft.CodeAnalysis.CSharp.CodeStyle    4.2.0     4.2.0
    Microsoft.CodeAnalysis.NetAnalyzers        6.0.0     6.0.0
    Microsoft.VisualStudio.Threading.Analyzers 17.2.32   17.2.32
#>

function Get-VisualStudioProjectNuGetPackage
{
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $true, HelpMessage = "The absolute path to a Visual Studio project file.")]
        [string]
        $Path,

        [Parameter(HelpMessage = "Wildcard-enabled expression to filter package names.")]
        [string]
        $PackageNameFilter
    )

    process
    {
        $pathItem = Get-Item -Path $Path -Include *.csproj

        if ($pathItem -isnot [System.IO.FileInfo])
        {
            throw "The path `"$Path`" does not point to a Visual Studio project file!"
        }

        # In the future (once https://github.com/NuGet/Home/issues/7752 is resolved) we may be able to request this
        # output in JSON or similar format. If so, this code should be replaced to use that and e.g. ConvertFrom-Json.
        $packageList = dotnet list $pathItem.FullName package |
            ForEach-Object { $PSItem.Trim() } |
            Where-Object { $PSItem.StartsWith(">") } |
            ForEach-Object {
                ($Name, $Requested, $Resolved) = $PSItem.TrimStart(">").Split(" ", [System.StringSplitOptions]::RemoveEmptyEntries)

                New-Object PSObject -Property @{ Name = $Name; Requested = $Requested; Resolved = $Resolved }
            }

        if (-not [string]::IsNullOrEmpty($PackageNameFilter))
        {
            $packageList = $packageList | Where-Object { $PSItem.Name -like "$PackageNameFilter" }
        }

        $packageList
    }
}
