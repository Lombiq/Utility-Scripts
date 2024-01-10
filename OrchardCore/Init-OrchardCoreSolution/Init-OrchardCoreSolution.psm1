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
        $warningMessage =
            'Warning: "Init-OrchardCoreSolution" is the old and deprecated name of this module. ' +
            'Use "Initialize-OrchardCoreSolution" instead.'
        
        Write-Warning $warningMessage

        Initialize-OrchardCoreSolution -Path $Path -Name $Name -ModuleName $ModuleName -ThemeName $ThemeName -NuGetSource $NuGetSource
    }
}