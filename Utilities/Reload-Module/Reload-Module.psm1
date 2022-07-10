<#
.Synopsis
    Reloads PowerShell modules from a folder.

.DESCRIPTION
    Finds PowerShell modules in the specified folder structure and reloads them.

.EXAMPLE
    Reload-Module
.EXAMPLE
    Reload-Module "C:\Path\To\PSModules"
#>

function Reload-Module
{
    [System.Diagnostics.CodeAnalysis.SuppressMessageAttribute(
        'PSUseApprovedVerbs',
        '',
        Justification = 'Use distinctive name to confusion with existing cmdlets such as Import-Module.')]
    [CmdletBinding()]
    [Alias("rlm")]
    Param
    (
        # The path to a folder where PowerShell modules should be reloaded.
        [Parameter(ValueFromPipelineByPropertyName = $true,
                   Position = 0)]
        $Path = $PSScriptRoot
    )
    Process
    {
        if (Test-Path($Path) -PathType Container)
        {
            $modules = Get-ChildItem -Path $Path -Recurse -File |
                Where-Object { [System.IO.Path]::GetExtension($PSItem.FullName) -match '^\.psm1$' }

            if ($modules.Length -gt 0)
            {
                $loadedModules = @()

                foreach ($module in $modules)
                {
                    Import-Module ([System.IO.Path]::GetDirectoryName($module.FullName)) -Force
                    $loadedModules += ,"* $($module.FullName)"
                }

                $header = "Reloading PowerShell modules:";
                $line = $header -replace '.', '*'
                Write-Verbose "`n$header`n$line`n$($loadedModules -join "`n")`n$line`n"
            }
        }
        else
        {
            Write-Error "$Path is not available!"
        }
    }
}