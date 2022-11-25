<#
.Synopsis
   Checks Visual Studio project files' contents against the file system looking for inconsistencies.

.DESCRIPTION
  Discovers Visual Studio project (.csproj) files in a specific folder to check their content against the file system
  looking for inconsistencies. The incostencies can be missing files/folders form the .csproj/folder structure. You can
  use the script without defining a path, it will use the current folder by default.

.EXAMPLE
   PS C:\Windows\system32>  Find-CsprojInConsistency -Path C:\repos\musqle\src\Orchard.Web\Modules\Softival.Musqle.Journal

    ********************************************************************
    THE FOLLOWING FILES ARE NOT ADDED TO Softival.Musqle.Journal.csproj!
    ********************************************************************
    - Views\Parts\DietJournalDay.cshtml
    ********************************************************************


    ********************************************************************************************************
    THE FOLLOWING FILES ARE NOT PRESENT IN C:\repos\musqle\src\Orchard.Web\Modules\Softival.Musqle.Journal\!
    ********************************************************************************************************
    - Views\JournalItemShapesTest.cshtml
    ********************************************************************************************************


    *********************************************************************
    THE FOLLOWING FILES ARE DUPLICATED IN Softival.Musqle.Journal.csproj!
    *********************************************************************
    - Views\JournalItemShapes.cshtml
    *********************************************************************
.EXAMPLE
    PS C:\repos\musqle\src\Orchard.Web\Modules\Softival.Musqle.Journal> Find-CsprojInConsistency

    ********************************************************************
    THE FOLLOWING FILES ARE NOT ADDED TO Softival.Musqle.Journal.csproj!
    ********************************************************************
    - Views\Parts\DietJournalDay.cshtml
    ********************************************************************


    ***************************************************************************************************************
    THE FOLLOWING FILES ARE NOT PRESENT IN C:\repos\musqle\src\Orchard.Web\Modules\Softival.Musqle.Journal\ folder!
    ***************************************************************************************************************
    - Views\JournalItemShapesTest.cshtml
    ***************************************************************************************************************


    *********************************************************************
    THE FOLLOWING FILES ARE DUPLICATED IN Softival.Musqle.Journal.csproj!
    *********************************************************************
    - Views\JournalItemShapes.cshtml
    *********************************************************************

#>
function Test-VSProjectConsistency
{
    [CmdletBinding()]
    Param
    (
        # The path to a folder or a Visual Studio project file to check. The default path is the current execution path.
        [string]
        $Path = (Get-Item -Path ".\").FullName,

        # A list of file extensions to also check for in project files. The default file extensions are: ".cs",
        # ".cshtml", ".info", ".config", ".less", ".png", ".jpg", ".jpeg", ".gif", ".ico", ".ts", ".css", ".min.css",
        # ".css.map", ".js", ".min.js", ".js.map".
        [string[]]
        $AdditionalFileExtensions
    )

    Process
    {
        # If the path is invalid, then return an error.
        if (!(Test-Path $Path))
        {
            Write-Error ("File or folder not found!")
            return
        }

        $isPathContainer = [bool] (Test-Path $Path -PathType Container)
        $isPathCsproj = Test-PathCsproj $Path
        # If the path is a file but not a csproj, then return an error.
        if (-not $isPathContainer -and -not $isPathCsproj)
        {
            Write-Error ("The specified parth is not a folder or a visual studio project file!")
            return
        }

        # The list of project files.
        $projectFiles = @()

        # If the path is a folder, then get all the .csprojs inside it.
        if ($isPathContainer)
        {
            $projectFiles += Get-ChildItem -Path $Path -Recurse -File -Include *.csproj
        }
        # If the path points to a csproj, then check only that.
        elseif ($isPathCsproj)
        {
            $projectFiles += $Path
        }

        # Return with a message if there aren't any .csproj files to process.
        if ($projectFiles.Length -eq 0)
        {
            Write-Output "No .csproj in the folder."
            return
        }

        # The default whitelist of the extensions to we're interested in.
        $fileExtensions = @(
            ".cs",
            ".cshtml",
            ".info",
            ".config",
            ".less",
            ".png",
            ".jpg",
            ".jpeg",
            ".gif",
            ".ico",
            ".ts",
            ".css",
            ".min.css",
            ".css.map",
            ".js",
            ".min.js",
            ".js.map")
        $fileExtensionsForRegex = "(" + ($fileExtensions -join "|") + ")$"
        # Adding additional whitelisted extensions to the whitelist.
        foreach ($extension in $AdditionalFileExtensions)
        {
            if (!$extension.StartsWith("."))
            {
                $extension = "." + $extension
            }

            $fileExtensions += $extension.ToLowerInvariant()
        }

        # Skip these directories during the collection of files, both from the csproj and the file system.
        $directoriesToSkip = @("bin", "obj", "tests", "node_modules", "lib")
        # ORCHARD-SPECIFIC DIRECTORIES
        if ([System.IO.Path]::GetFileName($projectFile) -match "^Orchard\.Web\.csproj$")
        {
            $directoriesToSkip += @("core", "media", "modules", "themes")
        }
        # END ORCHARD-SPECIFIC DIRECTORIES

        # Checking .csprojs one by one.
        foreach ($projectFile in $projectFiles)
        {
            $projectFolder = $projectFile.Substring(0, $projectFile.LastIndexOfAny(@('/', '\')) + 1)

            # It's declared inside the loop so we don't have to keep passing $projectFolder.
            function PathNotContainsAnyFolder($FullFolderPath, $Folders)
            {
                foreach ($pathFragment in $FullFolderPath.Substring($projectFolder.Length).Split(@('/', '\')))
                {
                    if ($Folders.Contains($pathFragment.ToLowerInvariant()))
                    {
                        return $false
                    }
                }

                return $true
            }

            $xml = [xml] (Get-Content $projectFile)

            # The files in the project file.
            $matchingFilesInProjectFile = @()
            # The files in the file system (folder).
            $matchingFilesInFolder = @()
            # The files in the project file but with wrong node name. The adding mode is wrong.
            $matchingFilesInProjectFileButWithWrongNodeName = @()
            foreach ($itemGroup in $xml.Project.ItemGroup | ForEach-Object { $PSItem.ChildNodes })
            {
                # The accepted node names.
                $acceptedNodeNames = @("Content", "Compile")
                # These node names are accepted also, but files added with these node names are added incorrectly.
                $acceptedButWrongNodeName = @("None")
                if ($acceptedNodeNames.Contains($node.Name) -or $acceptedButWrongNodeName.Contains($node.Name))
                {
                    $fullPath = $node.GetAttribute("Include")
                    # Checking files only with the specified extensions.
                    $notContainsAnyFolder = PathNotContainsAnyFolder -FullFolderPath ($projectFolder + $fullPath) -Folders $directoriesToSkip
                    if ($notContainsAnyFolder -and ($fullPath -imatch $fileExtensionsForRegex))
                    {
                        # Decoding the encoded MSBuild Special Characters (https://msdn.microsoft.com/en-us/library/bb383819.aspx).
                        $decodedFullPath = [System.Net.WebUtility]::UrlDecode($fullPath)
                        $matchingFilesInProjectFile += $decodedFullPath

                        # Filtering the wrong node names.
                        if ($acceptedButWrongNodeName.Contains($node.Name))
                        {
                            $matchingFilesInProjectFileButWithWrongNodeName += $decodedFullPath
                        }
                    }
                }

                # Detecting empty folders in the project file.
                $emptyFoldersInProjectfile = @()
                if ($node.Name -eq "Folder")
                {
                    $emptyFoldersInProjectfile += $node.GetAttribute("Include")
                }
            }
            [Array]::Sort($matchingFilesInProjectFile)

            # Collecting all projectfolders inside the projectfolder, because we want to skip them.
            # If a file is inside a project folder then it's irrelevant for the current csproj.
            $projectFoldersInTheProjectFolder = @()
            Get-ChildItem -Path $projectFolder -Recurse |
                Where-Object { (PathNotContainsAnyFolder -FullFolderPath $PSItem.FullName -Folders $directoriesToSkip) -and
                    !$PSItem.FullName.Substring($projectFolder.Length).StartsWith(".") -and
                    (FolderContainsCsproj $PSItem.FullName)
                } |
                ForEach-Object { $projectFoldersInTheProjectFolder += $PSItem }

            Get-ChildItem -Path $projectFolder -Recurse -File |
                Where-Object { (PathNotContainsAnyFolder -FullFolderPath $PSItem.FullName -Folders $directoriesToSkip) -and
                    (-not $PSItem.FullName.Substring($projectFolder.Length).StartsWith(".")) -and
                    $PSItem.FullName -imatch $fileExtensionsForRegex
                } |
                ForEach-Object { $matchingFilesInFolder += $PSItem.FullName.Substring($projectFolder.Length) }
            [Array]::Sort($matchingFilesInFolder)

            # Comparing the files included in the project file and the contents of the project folder.
            # Getting the files missing from the project file.
            $missingFilesFromProject = @()
            $filesAddedWithWrongNodeName = @()
            foreach ($file in $matchingFilesInFolder)
            {
                # If the file is inside a project folder then it's irrelevant for the current csproj.
                if (FileIsInsideAnyOfTheFolders ($projectFolder + $file) $projectFoldersInTheProjectFolder)
                {
                    continue
                }

                if (!$matchingFilesInProjectFile.ToLower().Contains($file.ToLower()))
                {
                    $missingFilesFromProject += $file
                }
                # If the file is added to the .csproj, but with an incorrect node name.
                elseif ($matchingFilesInProjectFileButWithWrongNodeName -and
                    $matchingFilesInProjectFileButWithWrongNodeName.ToLower().Contains($file.ToLower()))
                {
                    $filesAddedWithWrongNodeName += $file
                }
            }
            $csproj = [System.IO.Path]::GetFileName($projectFile)
            if ($missingFilesFromProject)
            {
                Write-VerboseListBox -Header "THE FOLLOWING FILES ARE NOT ADDED TO $csproj!" -Items $missingFilesFromProject
            }
            if ($filesAddedWithWrongNodeName)
            {
                Write-VerboseListBox -Header "THE FOLLOWING FILES ARE ADDED WITH THE WRONG NODE NAME TO $csproj!" -Items $filesAddedWithWrongNodeName
            }

            # Getting the files missing from the file system (folder) and the files that are duplicated in the project file.
            $missingFilesFromFolder = @()
            # The list of duplicated files in the project file.
            $duplicatesInProjectFile = @()
            $helperListForDuplicatedFiles = @()
            foreach ($file in $matchingFilesInProjectFile)
            {
                if (!$matchingFilesInFolder.ToLower().Contains($file.ToLower()))
                {
                    $missingFilesFromFolder += $file
                }

                # Checking the duplicates. The first condition is needed because ToLower() throws error if the list is empty.
                # This means that we have iterated through this file once before.
                if ($helperListForDuplicatedFiles -and $helperListForDuplicatedFiles.ToLower().Contains($file.ToLower()))
                {
                    $duplicatesInProjectFile += $file
                }
                $helperListForDuplicatedFiles += $file
            }
            if ($missingFilesFromFolder)
            {
                Write-VerboseListBox -Header "THE FOLLOWING FILES ARE NOT PRESENT IN $projectFolder FOLDER!" -Items $missingFilesFromFolder
            }
            if ($duplicatesInProjectFile)
            {
                Write-VerboseListBox -Header "THE FOLLOWING FILES ARE DUPLICATED IN $csproj!" -Items $duplicatesInProjectFile
            }

            # Detecting empty folders in the file system.
            $emptyFoldersInFileSystem = Get-ChildItem -Path $projectFolder -Recurse |
                Where-Object { PathNotContainsAnyFolder -FullFolderPath $PSItem.FullName -Folders $directoriesToSkip } |
                Where-Object { -not $PSItem.FullName.Substring($projectFolder.Length).StartsWith(".") } |
                # If the file is inside a project folder then it's irrelevant for the current csproj.
                Where-Object { -not (FileIsInsideAnyOfTheFolders $file.FullName $projectFoldersInTheProjectFolder) }
            Where-Object { Test-Path $file.FullName -PathType Container } |
                Where-Object { (Get-ChildItem $file.FullName | Measure-Object).Count -eq 0 } |
                ForEach-Object { $file.FullName.Substring($projectFolder.Length) }

            if ($emptyFoldersInFileSystem.Count)
            {
                Write-VerboseListBox -Header "THE FOLLOWING FOLDERS ARE EMPTY IN THE $projectFolder FOLDER!" -Items $emptyFoldersInFileSystem
            }

            if ($emptyFoldersInProjectfile)
            {
                Write-VerboseListBox -Header "THE FOLLOWING FOLDERS ARE EMPTY IN THE $csproj!" -Items $emptyFoldersInProjectfile
            }

            # Checking min and map files without a corresponding parent file.
            $mapAndMinFilesWithoutParent = @()
            foreach ($mapFile in $matchingFilesInProjectFile | Where-Object { $PSItem -match "\.map$" })
            {
                if (!$matchingFilesInProjectFile.Contains($mapFile.Substring(0, $mapFile.Length - 4)))
                {
                    $mapAndMinFilesWithoutParent += $mapFile
                }
            }
            foreach ($minFile in $matchingFilesInProjectFile | Where-Object { $PSItem -match "\.min\." })
            {
                $minFileWithoutMin = $minFile -replace "\.min\.", "."
                if (!($matchingFilesInProjectFile.Contains(($minFileWithoutMin)) -or
                        $matchingFilesInProjectFile.Contains(($minFileWithoutMin -replace "\.map", ""))))
                {
                    $mapAndMinFilesWithoutParent += $minFile
                }
            }
            if ($mapAndMinFilesWithoutParent)
            {
                Write-VerboseListBox -Header "THE FOLLOWING MAP AND MIN FILES HAVE A MISSING PARENT IN THE $csproj!" -Items $mapAndMinFilesWithoutParent
            }
        }

        return
    }
}

function FolderContainsCsproj($Path)
{
    return (Test-Path -Path $Path -PathType Container) -and (Get-ChildItem $Path\* -Include '*.csproj')
}

function FileIsInsideAnyOfTheFolders($FileFullPath, $Folders)
{
    return ($Folders | ForEach-Object { $FileFullPath.Contains($PSItem.FullName) }).Count -gt 0
}

function Write-VerboseListBox($Header, $Items)
{
    $line = $Header -replace '.', '*'
    $itemsString = ($Items | ForEach-Object { "- " + $PSItem }) -join "`n"
    Write-Verbose "$line`n$Header`n$line`n$itemsString`n$line"
}

function Test-PathCsproj($Path)
{
    [System.IO.Path]::GetExtension($Path) -match "^\.csproj$"
}