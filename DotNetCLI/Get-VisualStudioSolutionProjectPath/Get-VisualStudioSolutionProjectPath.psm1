function Get-VisualStudioSolutionProjectPath
{
    [CmdletBinding()]
    param
    (
        # The path to a solution or a folder containing a single solution file.
        [Parameter(Mandatory = $true)]
        [string]
        $Path,

        # Wildcard-enabled expression to filter project names.
        [string]
        $ProjectNameFilter,

        # When activated, the project paths returned will be relative paths.
        [Switch]
        $RelativePaths
    )

    process
    {
        $pathItem = Get-Item -Path $Path

        if ($pathItem -is [System.IO.DirectoryInfo])
        {
            $solution = Get-ChildItem -Path $Path | Where-Object { $PSItem.Name -like '*.sln' }

            if ($solution -isnot [System.IO.FileInfo])
            {
                if ($null -eq $solution)
                {
                    throw "There are no Visual Studio solution files in the `"$Path`" folder!"
                }
                elseif ($solution -is [System.Array])
                {
                    throw "The `"$Path`" folder contains multiple Visual Studio solutions!"
                }
                else
                {
                    throw "Unexpected result when trying to find a solution file in the `"$Path`" folder!"
                }
            }
        }
        elseif ($pathItem -is [System.IO.FileInfo])
        {
            if (-not $pathItem.Extension -eq '.sln')
            {
                throw "The file found at `"$Path`" is not a Visual Studio solution!"
            }

            $solution = $pathItem
        }
        else
        {
            throw "Unexpected result when trying to examine the `"$Path`" path!"
        }

        $projectPaths = dotnet sln "$($solution.FullName)" list | Where-Object { $PSItem -like '*.csproj' }
        $projects = $projectPaths | ForEach-Object { Get-Item "$($solution.DirectoryName)\$_" }

        if (-not [string]::IsNullOrEmpty($ProjectNameFilter))
        {
            $projects = $projects | Where-Object { $PSItem.BaseName -like "$ProjectNameFilter" }
        }

        if ($RelativePaths.IsPresent)
        {
            return $projects | ForEach-Object { $PSItem.FullName.SubString($solution.DirectoryName.Length + 1) }
        }
        else
        {
            return $projects | ForEach-Object { $PSItem.FullName }
        }
    }
}
