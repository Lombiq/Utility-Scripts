<#
.Synopsis
    Reloads PowerShell modules in a specified folder.

.DESCRIPTION
    Finds PowerShell modules in a folder structure and reloads them.

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
            foreach ($module in Get-ChildItem -Path $Path -Recurse -File | Where-Object { [System.IO.Path]::GetExtension($PSItem.FullName).Equals(".psm1", [System.StringComparison]::InvariantCultureIgnoreCase) })
            {
                Remove-Module ([System.IO.Path]::GetFileNameWithoutExtension($module.FullName))
                Import-Module ([System.IO.Path]::GetDirectoryName($module.FullName))
            }
        }
        else
        {
            Write-Error("$Path is not available!")   
        }
    }
}