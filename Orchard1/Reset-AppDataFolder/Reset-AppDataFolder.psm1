﻿<#
.Synopsis
   Given a path to an App_Data folder, this script will remove everything recursively, except the "Localization" folder.

.DESCRIPTION
   Given a path to an App_Data folder, this script will remove everything recursively, except the "Localization" folder.

.EXAMPLE
   Reset-AppDataFolder "C:\Path-To-My-Project\Path-To-App_Data\App_Data"
#>


function Reset-AppDataFolder
{
    [CmdletBinding()]
    [Alias("rsad")]
    Param
    (
        [Parameter(Mandatory=$true, ValueFromPipelineByPropertyName=$true, Position=0)]
        [string] $Path = $(throw "You need to specify that path an App_Data folder."),

        [switch] $KeepLogFiles
    )

    Process
    {
        if (!(Test-Path $Path))
        {
            throw ("The path `"$Path`" is invalid!")
        }

        $folder = Get-Item $Path

        if (!($folder -is [System.IO.DirectoryInfo]))
        {
            throw ("The path `"$Path`" is not pointing to a directory!")
        }

        if ($folder.BaseName -ne "App_Data")
        {
            throw ("The path `"$Path`" is not pointing to an App_Data folder!")
        }

        $whiteList = @("Localization")

        if ($KeepLogFiles.IsPresent)
        {
            $whiteList += "Logs"

            if (Test-Path("$Path\Logs"))
            {
                # Removing empty files and files that are not log files in the "Logs" folder.
                Get-ChildItem -Path "$Path\Logs" | Where-Object { $PSItem.Extension -ne ".log" -or $PSItem.Length -eq 0 } | Remove-Item -Force
            }
        }

        Get-ChildItem -Path $Path | Where-Object { $whiteList -notcontains $PSItem.Name } | Remove-Item -Recurse -Force
    }
}