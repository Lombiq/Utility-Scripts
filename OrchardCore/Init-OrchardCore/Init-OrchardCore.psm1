<#
.Synopsis
   Initializes an Orchard Core solution for a git repository. Deprecated, use Init-OrchardCoreSolution instead.
#>


function Init-OrchardCore
{
    [CmdletBinding()]
    Param
    (
        [string] $Path = (Get-Location).Path,

        [Parameter(Mandatory=$true)]
        [string] $Name,

        [string] $ModuleName,
        [string] $ThemeName,
        [string] $NuGetSource
    )

    Process
    {
        Init-OrchardCoreSolution -Name $Name -Path $Path -ModuleName $ModuleName -ThemeName $ThemeName -NuGetSource $NuGetSource
    }
}