<#
.Synopsis
   Adds a path to the PSModulePath environment variable.

.DESCRIPTION
   Only adds the path if hasn't been added yet. The path will also be added to the $PSModulePath variable so the modules will be available in the current console too.

.EXAMPLE
   .\AddPathToPSModulePath.ps1
   .\AddPathToPSModulePath.ps1 -Path "C:\MyPowerShellScripts"
#>

Param
(
    # The path to a folder that should be added to the list of paths containing PS modules. If not specified, the current path of this script will be added.
    [string]
    $Path = "$PSScriptRoot\"
)

$paths = [Environment]::GetEnvironmentVariable('PSModulePath', 'Machine').Split(';', [System.StringSplitOptions]::RemoveEmptyEntries)

if (!$paths.Contains($Path))
{
    [System.Environment]::SetEnvironmentVariable('PSModulePath', [string]::Join(';', $paths + $Path), 'Machine')
    Write-Verbose "The path `"$Path`" was successfully added to the PSModulePath environment variable."
}
else
{
    Write-Warning "The PSModulePath environment variable already contains the path `"$Path`"."
}