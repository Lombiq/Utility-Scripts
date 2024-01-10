<#
.Synopsis
    Initializes an Orchard Core solution for a git repository. Deprecated, use Initialize-OrchardCoreSolution instead.
#>

function Init-OrchardCoreSolution
{
    [Diagnostics.CodeAnalysis.SuppressMessage('PSUseApprovedVerbs', '', Justification = 'Necessary for backwards compatibility.')]
    [CmdletBinding()]
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
        Write-Warning 'Warning: "Init-OrchardCoreSolution" is the deprecated name of this module. Use "Initialize-OrchardCoreSolution" instead.'
        Initialize-OrchardCoreSolution -Path $Path -Name $Name -ModuleName $ModuleName -ThemeName $ThemeName -NuGetSource $NuGetSource
    }
}