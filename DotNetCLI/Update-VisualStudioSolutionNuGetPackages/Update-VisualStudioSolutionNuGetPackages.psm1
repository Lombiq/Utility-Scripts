function Update-VisualStudioSolutionNuGetPackages
{
    [Diagnostics.CodeAnalysis.SuppressMessage("PSUseSingularNouns", "", Justification = "Not applicable here.")]
    [CmdletBinding()]
    param
    (
        # The path to a solution or a folder containing a single solution file.
        [Parameter(Mandatory = $true)]
        [string]
        $Path,

        # Wildcard-enabled expression to filter project names.
        [string]
        $ProjectNameFilter,

        # Wildcard-enabled expression to filter package names.
        [string]
        $PackageNameFilter
    )

    process
    {
        foreach ($projectPath in Get-VisualStudioSolutionProjectPaths -Path $Path -ProjectNameFilter $ProjectNameFilter)
        {
            foreach ($package in Get-VisualStudioProjectNugetPackages -Path $projectPath -PackageNameFilter $PackageNameFilter)
            {
                dotnet add $projectPath package $package.Name
            }
        }
    }
}