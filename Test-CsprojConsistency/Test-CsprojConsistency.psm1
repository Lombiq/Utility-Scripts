<#
.Synopsis
   Discovers Visual Studio project (.csproj) files in a specific folder to check their content against the file system looking for inconsistencies.

.DESCRIPTION
  Long description

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
function Test-CsprojConsistency
{
    [CmdletBinding()]
    Param
    (
        # The path to a folder or a Visual Studio project file to check. The default path is the current execution path.
        [string] 
        $Path = (Get-Item -Path ".\").FullName,

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
            foreach ($csproj in Get-ChildItem -Path $Path -Recurse -File | Where-Object { [System.IO.Path]::GetExtension($PSItem.FullName).Equals(".csproj", [System.StringComparison]::InvariantCultureIgnoreCase) })
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
            $matchingFilesInProjectFile = @()
            # The files in the file system (folder).
            $matchingFilesInFolder = @()

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
							# Decoding the encoded MSBuild Special Characters (https://msdn.microsoft.com/en-us/library/bb383819.aspx) 
                            $matchingFilesInProjectFile += $fullPath -replace "%25", "%" -replace "%24", "$" -replace "%40", "@" -replace "%27", "'" -replace "%3B", ";" -replace "%3F", "?" -replace "%2A", "*"
                        }
                    }
                }
            }
            [Array]::Sort($matchingFilesInProjectFile)

            $directoriesToSkip = @("bin", "obj", "tests", "node_modules", "lib")



            # ORCHARD-SPECIFIC

            if ([System.IO.Path]::GetFileName($projectFile).ToLowerInvariant().Equals("Orchard.Web.csproj", [System.StringComparison]::InvariantCultureIgnoreCase))
            {
                $directoriesToSkip += @("core", "media", "modules", "themes")
            }

            # END ORCHARD-SPECIFIC


            
            foreach ($file in Get-ChildItem -Path $projectFolder -Recurse -File | Where-Object { !$directoriesToSkip.Contains($PSItem.FullName.Substring($projectFolder.Length).Split(@('/', '\'))[0].ToLowerInvariant()) -and !$PSItem.FullName.Substring($projectFolder.Length).StartsWith(".") })
            {
                if ($fileExtensions.Contains($file.Extension.ToLowerInvariant()))
                {
                    $matchingFilesInFolder += $file.FullName.Substring($projectFolder.Length)
                }
            }
            [Array]::Sort($matchingFilesInFolder)

            # Comparing the files included in the project file and the contents of the project folder.
            # Getting the files missing from the project file.
            $missingFilesFromProject = @()
            foreach ($file in $matchingFilesInFolder)
            {
                if (!$matchingFilesInProjectFile.ToLower().Contains($file.ToLower()))
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
            foreach ($file in $matchingFilesInProjectFile)
            {
                if (!$matchingFilesInFolder.ToLower().Contains($file.ToLower()))
                {
                    $missingFilesFromFolder += $file
                }
                
                # Checking the duplicates. The first condition is needed because ToLower() throws error if the list is empty.
                if($helperListForDuplicatadFiles -and $helperListForDuplicatadFiles.ToLower().Contains($file.ToLower())) # This means that we have iterated through this file once before. 
                {
                    $duplicatesInProjectFile += $file
                }
                $helperListForDuplicatadFiles += $file
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
