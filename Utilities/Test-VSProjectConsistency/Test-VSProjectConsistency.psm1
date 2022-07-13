<#
.Synopsis
   Checks Visual Studio project files' contents against the file system looking for inconsistencies.

.DESCRIPTION
  Discovers Visual Studio project (.csproj) files in a specific folder to check their content against the file system looking for inconsistencies.
  The incostencies can be missing files/folders form the .csproj/folder structure.
  You can use the script without defining a path, it will use the current folder by default.

.EXAMPLE
   PS C:\Windows\system32>  Find-CsprojInConsistency -Path C:\repos\musqle\src\Orchard.Web\Modules\Softival.Musqle.Journal   

    *****
    THE FOLLOWING FILES ARE NOT ADDED TO Softival.Musqle.Journal.csproj!
    
    Views\Parts\DietJournalDay.cshtml
    
    *****
    
    
    *****
    THE FOLLOWING FILES ARE NOT PRESENT IN C:\repos\musqle\src\Orchard.Web\Modules\Softival.Musqle.Journal\!
    
    Views\JournalItemShapesTest.cshtml
    
    *****
    
    
    *****
    THE FOLLOWING FILES ARE DUPLICATED IN Softival.Musqle.Journal.csproj!
    
    Views\JournalItemShapes.cshtml
    
    *****
.EXAMPLE
	PS C:\repos\musqle\src\Orchard.Web\Modules\Softival.Musqle.Journal> Find-CsprojInConsistency

	*****
	THE FOLLOWING FILES ARE NOT ADDED TO Softival.Musqle.Journal.csproj!

	Views\Parts\DietJournalDay.cshtml

	*****


	*****
	THE FOLLOWING FILES ARE NOT PRESENT IN C:\repos\musqle\src\Orchard.Web\Modules\Softival.Musqle.Journal\ folder!

	Views\JournalItemShapesTest.cshtml

	*****


	*****
	THE FOLLOWING FILES ARE DUPLICATED IN Softival.Musqle.Journal.csproj!

	Views\JournalItemShapes.cshtml

	*****

#>
function Test-VSProjectConsistency
{
    [CmdletBinding()]
    Param
    (
        # The path to a folder or a Visual Studio project file to check. The default path is the current execution path.
        [string] 
        $Path = (Get-Item -Path ".\").FullName,

        # A list of file extensions to also check for in project files. The default file extensions are: ".cs", ".cshtml", ".info", ".config", ".less", ".png", ".jpg", ".jpeg", ".gif", ".ico", ".ts", ".css", ".min.css", ".css.map", ".js", ".min.js", ".js.map".
        [string[]]
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
            foreach ($csproj in Get-ChildItem -Path $Path -Recurse -File | Where-Object { [System.IO.Path]::GetExtension($PSItem.FullName).Equals(".csproj", [System.StringComparison]::InvariantCultureIgnoreCase) })
            {
                $projectFiles += $csproj.FullName
            }
        }
        # If the path points to a csproj, then check only that.
        elseif ([System.IO.Path]::GetExtension($Path).Equals(".csproj", [System.StringComparison]::InvariantCultureIgnoreCase))
        {
            $projectFiles += $Path
        }

        # Return with a message if there aren't any .csproj files to process.
        if($projectFiles.Length -eq 0)
        {
            Write-Output "No .csproj in the folder."
            return
        }

        # The default whitelist of the extensions to we're interested in.
        $fileExtensions = @(".cs", ".cshtml", ".info", ".config", ".less", ".png", ".jpg", ".jpeg", ".gif", ".ico", ".ts", ".css", ".min.css", ".css.map", ".js", ".min.js", ".js.map")
		$fileExtensionsForRegex = $fileExtensions -join "|"
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
        if ([System.IO.Path]::GetFileName($projectFile).ToLowerInvariant().Equals("Orchard.Web.csproj", [System.StringComparison]::InvariantCultureIgnoreCase))
        {
            $directoriesToSkip += @("core", "media", "modules", "themes")
        }
        # END ORCHARD-SPECIFIC DIRECTORIES

        # Checking .csprojs one by one.
        foreach ($projectFile in $projectFiles)
        {
            $projectFolder = $projectFile.Substring(0, $projectFile.LastIndexOfAny(@('/', '\')) + 1)

            $xml = [XML] (Get-Content $projectFile)

            # The files in the project file.
            $matchingFilesInProjectFile = @()
            # The files in the file system (folder).
            $matchingFilesInFolder = @()
			# The files in the project file but with wrong node name. The adding mode is wrong.
			$matchingFilesInProjectFileButWithWrongNodeName = @()
            foreach ($itemGroup in $xml.Project.ItemGroup)
            {
                foreach ($node in $itemGroup.ChildNodes)
                {
					# The accepted node names.
                    $acceptedNodeNames = @("Content", "Compile")
					# These node names are accepted also, but files added with these node names are added incorrectly.
					$acceptedButWrongNodeName = @("None")
                    if ($acceptedNodeNames.Contains($node.Name) -or $acceptedButWrongNodeName.Contains($node.Name))
                    {
                        $fullPath = $node.GetAttribute("Include")
						# Checking files only with the specified extensions.
                        if (!(FolderPathContainsAnyFolder ($projectFolder + $fullPath) $directoriesToSkip $projectFolder) -and ($fullPath.ToLowerInvariant() -match "($fileExtensionsForRegex)$"))
                        {
							# Decoding the encoded MSBuild Special Characters (https://msdn.microsoft.com/en-us/library/bb383819.aspx).
							$decodedFullPath = $fullPath -replace "%25", "%" -replace "%24", "$" -replace "%40", "@" -replace "%27", "'" -replace "%3B", ";" -replace "%3F", "?" -replace "%2A", "*"
                            $matchingFilesInProjectFile += $decodedFullPath

							# Filtering the wrong node names.
							if($acceptedButWrongNodeName.Contains($node.Name))
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
            }
            [Array]::Sort($matchingFilesInProjectFile)

			# Collecting all projectfolders inside the projectfolder, because we want to skip them.
			# If a file is inside a project folder then it's irrelevant for the current csproj.
			$projectFoldersInTheProjectFolder = @()
			foreach ($file in Get-ChildItem -Path $projectFolder -Recurse | Where-Object { !(FolderPathContainsAnyFolder $PSItem.FullName $directoriesToSkip $projectFolder) -and !$PSItem.FullName.Substring($projectFolder.Length).StartsWith(".") -and (FolderContainsCsproj $PSItem.FullName)})
            {
				$projectFoldersInTheProjectFolder += $file
            }
			            
            foreach ($file in Get-ChildItem -Path $projectFolder -Recurse -File | Where-Object {!(FolderPathContainsAnyFolder $PSItem.FullName $directoriesToSkip $projectFolder) -and !$PSItem.FullName.Substring($projectFolder.Length).StartsWith(".") })
            {
				if ($file.FullName.ToLowerInvariant() -match "($fileExtensionsForRegex)$")
                {
                    $matchingFilesInFolder += $file.FullName.Substring($projectFolder.Length)
                }
            }
            [Array]::Sort($matchingFilesInFolder)

            # Comparing the files included in the project file and the contents of the project folder.
            # Getting the files missing from the project file.
            $missingFilesFromProject = @()
			$filesAddedWithWrongNodeName = @()
            foreach ($file in $matchingFilesInFolder)
            {
				# If the file is inside a project folder then it's irrelevant for the current csproj.
				if(FileIsInsideAnyOfTheFolders ($projectFolder + $file) $projectFoldersInTheProjectFolder)
				{
					continue
				}

                if (!$matchingFilesInProjectFile.ToLower().Contains($file.ToLower()))
                {
                    $missingFilesFromProject += $file
                }
				# If the file is added to the .csproj, but with an incorrect node name.
				elseif($matchingFilesInProjectFileButWithWrongNodeName -and $matchingFilesInProjectFileButWithWrongNodeName.ToLower().Contains($file.ToLower()))
				{
					$filesAddedWithWrongNodeName += $file
				}
            }
			$csproj = [System.IO.Path]::GetFileName($projectFile)
            if ($missingFilesFromProject)
            {
                Write-Output ("`n*****`nTHE FOLLOWING FILES ARE NOT ADDED TO $csproj!`n")
                foreach ($file in $missingFilesFromProject)
                {
                    Write-Output $file
                }
                Write-Output ("`n*****`n")
            }
			if ($filesAddedWithWrongNodeName)
            {
                Write-Output ("`n*****`nTHE FOLLOWING FILES ARE ADDED WITH THE WRONG NODE NAME TO $csproj!`n")
                foreach ($file in $filesAddedWithWrongNodeName)
                {
                    Write-Output $file
                }
                Write-Output ("`n*****`n")
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
                if($helperListForDuplicatedFiles -and $helperListForDuplicatedFiles.ToLower().Contains($file.ToLower())) # This means that we have iterated through this file once before. 
                {
                    $duplicatesInProjectFile += $file
                }
                $helperListForDuplicatedFiles += $file
            }
            if ($missingFilesFromFolder)
            {
                Write-Output ("`n*****`nTHE FOLLOWING FILES ARE NOT PRESENT IN $projectFolder folder!`n")
                foreach ($file in $missingFilesFromFolder)
                {
                    Write-Output $file
                }
                Write-Output ("`n*****`n")
            }
            if ($duplicatesInProjectFile)
            {
                Write-Output ("`n*****`nTHE FOLLOWING FILES ARE DUPLICATED IN $csproj!`n")
                foreach ($file in $duplicatesInProjectFile)
                {
                    Write-Output $file
                }
                Write-Output ("`n*****`n")
            }

			# Detecting empty folders in the file system.
			$emptyFoldersInFileSystem = @()
            foreach ($file in Get-ChildItem -Path $projectFolder -Recurse | Where-Object { !(FolderPathContainsAnyFolder $PSItem.FullName $directoriesToSkip $projectFolder) -and !$PSItem.FullName.Substring($projectFolder.Length).StartsWith(".") })
            {
				# If the file is inside a project folder then it's irrelevant for the current csproj.
				if(FileIsInsideAnyOfTheFolders $file.FullName $projectFoldersInTheProjectFolder)
				{
					continue
				}

				if((Test-Path $file.FullName -PathType Container)  -and ((Get-ChildItem $file.FullName | Measure-Object).Count -eq 0))
				{
					$emptyFoldersInFileSystem += $file.FullName.Substring($projectFolder.Length)
				}
               
            }
			if ($emptyFoldersInFileSystem)
            {
                Write-Output ("`n*****`nTHE FOLLOWING FOLDERS ARE EMPTY IN THE $projectFolder FOLDER!`n")
                foreach ($file in $emptyFoldersInFileSystem)
                {
                    Write-Output $file
                }
                Write-Output ("`n*****`n")
            }

			if ($emptyFoldersInProjectfile)
            {
                Write-Output ("`n*****`nTHE FOLLOWING FOLDERS ARE EMPTY IN THE $csproj!`n")
                foreach ($file in $emptyFoldersInProjectfile)
                {
                    Write-Output $file
                }
                Write-Output ("`n*****`n")
            }

			# Checking min and map files without a corresponding parent file.
			$mapAndMinFilesWithoutParent = @()
			foreach($mapFile in $matchingFilesInProjectFile | Where-Object {$PSItem -match "\.map$"})
			{
				if(!$matchingFilesInProjectFile.Contains($mapFile.Substring(0, $mapFile.Length - 4)))
				{
					$mapAndMinFilesWithoutParent += $mapFile
				}
			}
			foreach($minFile in $matchingFilesInProjectFile | Where-Object {$PSItem -match "\.min\."})
			{
				$minFileWithoutMin = $minFile -replace "\.min\.", "."
				if(!($matchingFilesInProjectFile.Contains(($minFileWithoutMin)) -or $matchingFilesInProjectFile.Contains(($minFileWithoutMin -replace "\.map", ""))))
				{
					$mapAndMinFilesWithoutParent += $minFile
				}
			}
			if ($mapAndMinFilesWithoutParent)
            {
                Write-Output ("`n*****`nTHE FOLLOWING MAP AND MIN FILES HAVE A MISSING PARENT IN THE $csproj!`n")
                foreach ($file in $mapAndMinFilesWithoutParent)
                {
                    Write-Output $file
                }
                Write-Output ("`n*****`n")
            }
        }

        return
    }
}

function FolderContainsCsproj
{
	Param($path)

	if(!(Test-Path ($Path)) -or !(Test-Path($Path) -PathType Container))
	{
		return $false
	}
	
	foreach($file in Get-ChildItem $path)
	{
		if($file.Extension -eq ".csproj")
		{
			return $true
		}
	}
	
	return $false
}

function FileIsInsideAnyOfTheFolders
{
	Param($fileFullPath, $folders)
	
	foreach ($folder in $folders)
	{
		if($fileFullPath.Contains($folder.FullName))
		{
			return $true
		}
	}
	
	return $false
}

function FolderPathContainsAnyFolder
{
	# The projectfolder is necessary because we need the relative path to it.
	Param($fullFolderPath, $folders, $projectFolder)

	foreach($pathFragment in $fullFolderPath.Substring($projectFolder.Length).Split(@('/', '\')))
	{
		if($folders.Contains($pathFragment.ToLowerInvariant()))
		{
			return $true
		}
	}
	
	return $false
}