<#
.Synopsis
   Adds a path to the PSModulePath environment variable.

.DESCRIPTION
   Only adds the path if hasn't been added yet. The path will also be added to the $PSModulePath variable so the modules will available in the current console too.

.EXAMPLE
   .\AddPathToPSModulePath.ps1
   .\AddPathToPSModulePath.ps1 -Path "C:\MyPowerShellScripts"
#>

Param
(
    # The path to a folder that should be added to the list of paths containing PS modules. If not specified, the current path of this script will be added.
    [string] 
    $Path = "$PSScriptRoot\",

    # Indicates whether the script has been automatically (not in interactive mode) or manually.
    [switch][bool]
    $NonInteractive
)

if($env:PSModulePath -split ';' -notcontains $Path)
{
    $env:PSModulePath += ";$Path"
    [System.Environment]::SetEnvironmentVariable("PSModulePath", $env:PSModulePath + ";$Path", "Machine")
    Write-Information "The path $Path was successfully added to the PSModulePath environment variable."
}
else
{
    Write-Warning "The PSModulePath path already contains $Path."
}

if(!$NonInteractive)
{
    pause
}