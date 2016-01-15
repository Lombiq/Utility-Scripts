<#
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
    [OutputType([bool])]
    Param
    (
        [Parameter(Mandatory=$true,
                   ValueFromPipelineByPropertyName=$true,
                   Position=0)]
        $Path = $(throw "You need to specify that path an App_Data folder.")
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

        foreach ($item in Get-ChildItem -Path $Path | Where-Object { $PSItem.Name -ne "Localization" })
        {
            Remove-Item $item.FullName -Recurse -Force
        }

        return true
    }
}