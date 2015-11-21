<#
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
        # The path to a folder or a Visual Studio project file to check.
        [Parameter(Mandatory = $true, HelpMessage = "The path to a folder or a Visual Studio project file to check.")]
        [string] 
        $Path,

        # A comma-separated list of file extensions to also check for in project files. The default file extensions are: .cs, .cshtml, .web.config, .css, .less, .js, .png, .jp(e)g, .gif, .ico.
        [string]
        $AdditionalFileExtensions
    )

    Process
    {
        # If the path is invalid, then return an error.
        if (!(Test-Path ($Path)))
        {
            Write-Error ("File or folder not found!")
            return
        }

        # If the path is a file but not a csproj, then return an error.
        if (!(Test-Path ($Path) -PathType Container) -and ![System.IO.Path]::GetExtension($Path).Equals(".csproj", [System.StringComparison]::InvariantCultureIgnoreCase))
        {
            Write-Error ("The specified parth is not a folder or a visual studio project file!")
            return
        }

        # The list of project files.
        $projectFiles = @()

        # If the path is a folder, then get all the .csprojs inside it.
        if (Test-Path ($Path) -PathType Container)
        {
            foreach ($csproj in Get-ChildItem -Path $Path -Recurse -File | Where-Object { [System.IO.Path]::GetExtension($_.FullName).Equals(".csproj", [System.StringComparison]::InvariantCultureIgnoreCase) })
            {
                $projectFiles += $csproj.FullName
            }
        }
        # If the path is a csproj, then check only it.
        elseif ([System.IO.Path]::GetExtension($Path).Equals(".csproj", [System.StringComparison]::InvariantCultureIgnoreCase))
        {
            $projectFiles += $Path
        }

        # If no .csproj in the list, then return an information about it.
        if($projectFiles.Length -eq 0)
        {
            Write-Output "No .csproj in the folder."
            return
        }

        # The default whitelist of the extensions search for.
        $fileExtensions = @(".cs", ".cshtml", ".info", ".config", ".css", ".less", ".js", ".png", ".jpg", ".jpeg", ".gif", ".ico")
        # Adding parameter list to the default whitelist.
        foreach ($extension in $AdditionalFileExtensions.Split(","))
        {
            if (!($extension.StartsWith(".")) -and $extension.Length > 0)
            {
                $extension = "." + $extension
            }

            $fileExtensions += $extension.ToLowerInvariant()
        }

        # Checking .csprojs one by one.
        foreach ($projectFile in $projectFiles)
        {
            $projectFolder = $projectFile.Substring(0, $projectFile.LastIndexOfAny(@('/', '\')) + 1)

            $xml = [XML] (Get-Content $projectFile)

            # The files in the project file.
            $matchingProjectFiles = @()
            # The files in the file system (folder).
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
            # Getting the files missing from the project file.
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

            # Getting the files missing from the file system (folder). Also getting the files what are duplicated in the project file.
            $missingFilesFromFolder = @()
            # The list of duplicated files in the project file.
            $duplicatesInProjectFile = @()
            $helperListForDuplicatadFiles = @()
            foreach ($file in $matchingProjectFiles)
            {
                if (!$matchingFolderFiles.Contains($file))
                {
                    $missingFilesFromFolder += $file
                }
                
                # Checking the duplicates.
                if($helperListForDuplicatadFiles.Contains($file)) # This means that we have iterated through this file once before. 
                {
                    $duplicatesInProjectFile += $file
                }
                $helperListForDuplicatadFiles += $file
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
            if ($duplicatesInProjectFile)
            {
                $csproj = [System.IO.Path]::GetFileName($projectFile)
                Write-Output ("`n*****`nTHE FOLLOWING FILES ARE DUPLICATED IN $csproj!`n")
                foreach ($file in $duplicatesInProjectFile)
                {
                    Write-Output $file
                }
                Write-Output ("`n*****`n")
            }
        }

        return
    }
}