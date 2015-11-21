﻿<#
.Synopsis
   Discovers Visual Studio project (.csproj) files in a specific folder to check their content against the file system looking for inconsistencies.

.DESCRIPTION
  Long description

.EXAMPLE
   PS C:\repos\infrastructure-scripts\Utility\Find-CsprojInConsistency>  Find-CsprojInConsistency -Path C:\repos\musqle\src\Orchard.Web\Modules\Softival.Musqle.Journal\Softival.Musqle.Journal.csproj

    *****
    THE FOLLOWING FILES ARE NOT ADDED TO Softival.Musqle.Journal.csproj!

    Views\Parts\DietJournalDay.cshtml

    *****


    *****
    THE FOLLOWING FILES ARE NOT PRESENT IN C:\repos\musqle\src\Orchard.Web\Modules\Softival.Musqle.Journal\!

    Views\JournalItemShapesTest.cshtml

    *****

#>
function Find-CsprojInConsistency
{
    [CmdletBinding()]
    Param
    (
        [Parameter(Mandatory = $true, HelpMessage = "The path to a folder or a Visual Studio project file to check.")]
        [string] $Path = $(throw "You need to specify a full path or file name with full file path."),

        [Parameter(HelpMessage = "A comma-separated list of file extensions to also check for in project files. The default file extensions are: .cs, .cshtml, .web.config, .css, .less, .js, .png, .jp(e)g, .gif, .ico.")]
        [string] $AdditionalFileExtensions
    )

    Process
    {
        if (!(Test-Path ($Path)))
        {
            Write-Output ("`n*****`nERROR: FILE OR FOLDER NOT FOUND!`n*****`n")
            return
        }

        if (!(Test-Path ($Path) -PathType Container) -and ![System.IO.Path]::GetExtension($Path).Equals(".csproj", [System.StringComparison]::InvariantCultureIgnoreCase))
        {
            Write-Output ("`n*****`nERROR: THE SPECIFIED PATH IS NOT A FOLDER OR A VISUAL STUDIO PROJECT FILE!`n*****`n")
            return
        }

        $projectFiles = @()


        if (Test-Path ($Path) -PathType Container)
        {
            foreach ($csproj in Get-ChildItem -Path $Path -Recurse -File | Where-Object { [System.IO.Path]::GetExtension($_.FullName).Equals(".csproj", [System.StringComparison]::InvariantCultureIgnoreCase) })
            {
                $projectFiles += $csproj.FullName
            }
        }
        elseif ([System.IO.Path]::GetExtension($Path).Equals(".csproj", [System.StringComparison]::InvariantCultureIgnoreCase))
        {
            $projectFiles += $Path
        }

        $fileExtensions = @(".cs", ".cshtml", ".info", ".config", ".css", ".less", ".js", ".png", ".jpg", ".jpeg", ".gif", ".ico")
        foreach ($extension in $AdditionalFileExtensions.Split(","))
        {
            if (!($extension.StartsWith(".")) -and $extension.Length > 0)
            {
                $extension = "." + $extension
            }

            $fileExtensions += $extension.ToLowerInvariant()
        }

        foreach ($projectFile in $projectFiles)
        {
            $projectFolder = $projectFile.Substring(0, $projectFile.LastIndexOfAny(@('/', '\')) + 1)

            $xml = [XML] (Get-Content $projectFile)

            $matchingProjectFiles = @()
            $matchingFolderFiles = @()

            foreach ($itemGroup in $xml.Project.ItemGroup)
            {
                foreach ($node in $itemGroup.ChildNodes)
                {
                    $acceptedNodeNames = @("Content", "Compile")
                    if ($acceptedNodeNames.Contains($node.Name))
                    {
                        $fullPath = $node.GetAttribute("Include")

                        if ($fileExtensions.Contains([System.IO.Path]::GetExtension($fullPath).ToLowerInvariant()))
                        {
                            $matchingProjectFiles += $fullPath
                        }
                    }
                }
            }
            [Array]::Sort($matchingProjectFiles)

            $directoriesToSkip = @("bin", "obj", "tests", "node_modules")



            # ORCHARD-SPECIFIC

            if ([System.IO.Path]::GetFileName($projectFile).ToLowerInvariant().Equals("Orchard.Web.csproj", [System.StringComparison]::InvariantCultureIgnoreCase))
            {
                $directoriesToSkip += @("core", "media", "modules", "themes")
            }

            # END ORCHARD-SPECIFIC



            foreach ($file in Get-ChildItem -Path $projectFolder -Recurse -File | Where-Object { $_.FullName.Substring($projectFolder.Length).Split(@('/', '\'))[0][0] -eq "." -or !$directoriesToSkip.Contains($_.FullName.Substring($projectFolder.Length).Split(@('/', '\'))[0].ToLowerInvariant()) })
            {
                if ($fileExtensions.Contains($file.Extension))
                {
                    $matchingFolderFiles += $file.FullName.Substring($projectFolder.Length)
                }
            }
            [Array]::Sort($matchingFolderFiles)

            # Comparing the files included in the project file and the contents of the project folder.
            $missingFilesFromProject = @()
            foreach ($file in $matchingFolderFiles)
            {
                if (!$matchingProjectFiles.Contains($file))
                {
                    $missingFilesFromProject += $file
                }
            }
            if ($missingFilesFromProject)
            {
                $csproj = [System.IO.Path]::GetFileName($projectFile)
                Write-Output ("`n*****`nTHE FOLLOWING FILES ARE NOT ADDED TO $csproj!`n")
                foreach ($file in $missingFilesFromProject)
                {
                    Write-Output $file
                }
                Write-Output ("`n*****`n")
            }

            $missingFilesFromFolder = @()
            foreach ($file in $matchingProjectFiles)
            {
                if (!$matchingFolderFiles.Contains($file))
                {
                    $missingFilesFromFolder += $file
                }
            }
            if ($missingFilesFromFolder)
            {
                Write-Output ("`n*****`nTHE FOLLOWING FILES ARE NOT PRESENT IN $projectFolder!`n")
                foreach ($file in $missingFilesFromFolder)
                {
                    Write-Output $file
                }
                Write-Output ("`n*****`n")
            }
        }

        return
    }
}