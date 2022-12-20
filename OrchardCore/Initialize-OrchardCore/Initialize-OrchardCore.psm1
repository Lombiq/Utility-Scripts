<#
.Synopsis
    Initializes an Orchard Core solution for a git repository. Deprecated, use Initialize-OrchardCoreSolution instead.
#>


function Initialize-OrchardCore
{
    [CmdletBinding()]
    [alias("Init-OrchardCore")]
    Param
    (
        [string] $Path = (Get-Location).Path,

        [Parameter(Mandatory = $true)]
        [string] $Name,

        [string] $ModuleName,
        [string] $ThemeName,
        [string] $NuGetSource
    )

    Process
    {
        Initialize-OrchardCoreSolution @{
            Name = $Name
            Path = $Path
            ModuleName = $ModuleName
            ThemeName = $ThemeName
            NuGetSource = $NuGetSource
        }
    }
}