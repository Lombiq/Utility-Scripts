<#
.Synopsis
   Adds the current path to the PSModulePath environment variable
.DESCRIPTION
   Only adds the current path if it doesn't exist yet. Also adds it to the $PSModulePath variable so the modules will available in the current console too.
.EXAMPLE
   .\AddCurrentPathToPSModulePath.ps1
#>
$newModulePath = "$PSScriptRoot\"
if($env:PSModulePath -split ';' -notcontains $newModulePath)
{
    $env:psmodulepath += ";$newModulePath"
    [System.Environment]::SetEnvironmentVariable("PSModulePath", $env:psmodulepath + ";$newModulePath", "Machine")
    Write-Information "The path $newModulePath was successfully added to the PSModulePath environment variable."
}
else
{
    Write-Warning "The PSModulePath path already contains $newModulePath."
}

pause