﻿<#
.Synopsis
   Replaces a string in a file.

.DESCRIPTION
   Replaces all occurrences of a given string with another one in a file.

.EXAMPLE
   Set-FileContent -FilePath "C:\file-to-moderate.txt" -Match "damn" -ReplaceWith "cute"
#>


function Set-FileContent
{
    [CmdletBinding()]
    [Alias("sfc")]
    Param
    (
        [Parameter(Mandatory = $true, HelpMEssage = "The path to the file in which the matching string should be replaced.")]
        [string] $FilePath,

        [Parameter(Mandatory = $true, HelpMEssage = "The PowerShell-escaped string to replace in the file specified.")]
        [string] $Match,

        [Parameter(Mandatory = $true, HelpMEssage = "The PowerShell-escaped replacement string.")]
        [string] $ReplaceWith
    )

    Process
    {
        if (!(Test-Path $FilePath -PathType Leaf))
        {
            throw ("Could not find the file specified at `"$FilePath`"!")
        }

        (Get-Content $FilePath) | Foreach-Object { $PSItem -replace $Match, $ReplaceWith } | Set-Content $FilePath

        Write-Host ("Successfully replaced all occurrences of `"$Match`" with `"$ReplaceWith`" in the file `"$FilePath`"!")
    }
}