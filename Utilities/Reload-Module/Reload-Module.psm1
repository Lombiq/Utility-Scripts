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
            $modules = Get-ChildItem -Path $Path -Recurse -File | Where-Object { [System.IO.Path]::GetExtension($PSItem.FullName).Equals(".psm1", [System.StringComparison]::InvariantCultureIgnoreCase) }

            if ($modules.Length -gt 0)
            {
                Write-Host ("`nRELOADING PS MODULES:`n*****")

                foreach ($module in $modules)
                {
                    Import-Module ([System.IO.Path]::GetDirectoryName($module.FullName)) -Force
                    Write-Host ("* " + $module.FullName)
                }

                Write-Host ("*****`n")
            }
        }
        else
        {
            Write-Error("$Path is not available!")
        }
    }
}