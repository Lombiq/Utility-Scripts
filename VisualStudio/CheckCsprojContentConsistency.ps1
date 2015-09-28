param
(
    [Parameter(Mandatory = $true, HelpMessage = "The path to a folder or a Visual Studio project file to check.")]
    [string] $Path = $(throw "You need to specify a full path or file name with full file path."),

    [Parameter(HelpMessage = "A comma-separated list of file extensions to also check for in project files. The default file extensions are: .cs, .cshtml, .web.config, .css, .less, .js, .png, .jp(e)g, .gif, .ico.")]
    [string] $AdditionalFileExtensions
)

if (!(Test-Path ($Path)))
{
    Write-Host ("`n*****`nERROR: FILE OR FOLDER NOT FOUND!`n*****`n")
    exit 1
}

if (!(Test-Path ($Path) -PathType Container) -and [System.IO.Path]::GetExtension($Path).ToLowerInvariant() -ne ".csproj")
{
    Write-Host ("`n*****`nERROR: THE SPECIFIED PATH IS NOT A FOLDER OR A VISUAL STUDIO PROJECT FILE!`n*****`n")
    exit 1
}

$projectFiles = @()


if (Test-Path ($Path) -PathType Container)
{
    foreach ($csproj in Get-ChildItem -Path $Path -Recurse -File | ? { [System.IO.Path]::GetExtension($_.FullName).ToLowerInvariant() -eq ".csproj" })
    {
        $projectFiles += $csproj.FullName
    }
}
elseif ([System.IO.Path]::GetExtension($Path).ToLowerInvariant() -eq ".csproj")
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
                    $matchingProjectFiles += $fullPath.ToLowerInvariant()
                }
            }
        }
    }
    [Array]::Sort($matchingProjectFiles)

    $directoriesToSkip = @(".hg", ".git", "bin", "obj", "tests")



    # ORCHARD-SPECIFIC

    if ([System.IO.Path]::GetFileName($projectFile).ToLowerInvariant() -eq "orchard.web.csproj")
    {
        $directoriesToSkip += @("core", "media", "modules", "themes")
    }

    # END ORCHARD-SPECIFIC



    foreach ($file in Get-ChildItem -Path $projectFolder -Recurse -File | ? { !$directoriesToSkip.Contains($_.FullName.Substring($projectFolder.Length).Split(@('/', '\'))[0].ToLowerInvariant()) })
    {
        if ($fileExtensions.Contains($file.Extension))
        {
            $matchingFolderFiles += $file.FullName.Substring($projectFolder.Length).ToLowerInvariant()
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
        Write-Host ("`n*****`nNOTIFICATION: THE FOLLOWING FILES ARE NOT ADDED TO $csproj!`n")
        foreach ($file in $missingFilesFromProject)
        {
            Write-Host $file
        }
        Write-Host ("`n*****`n")
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
        Write-Host ("`n*****`nNOTIFICATION: THE FOLLOWING FILES ARE NOT PRESENT IN $projectFolder!`n")
        foreach ($file in $missingFilesFromFolder)
        {
            Write-Host $file
        }
        Write-Host ("`n*****`n")
    }
}

exit 1