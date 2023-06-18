<#
.Synopsis
   Initializes an Orchard Core solution for a git repository.

.DESCRIPTION
   Initializes an Orchard Core solution using the latest released Orchard Core NuGet packages at the current location or under the given path, and adds a suitable .gitignore file. Optionally creates an initial module and/or theme, and optionally uses a given NuGet source.

.EXAMPLE
   Initialize-OrchardCoreSolution -Name "FancyWebsite" -Path "D:\Work\FancyWebsite" -ModuleName "FancyWebsite.Core" -ThemeName "FancyWebsite.Theme" -NuGetSource "https://nuget.cloudsmith.io/orchardcore/preview/v3/index.json"
#>


function Initialize-OrchardCoreSolution
{
    [CmdletBinding()]
    [alias('Init-OrchardCoreSolution')]
    Param
    (
        [string] $Path = (Get-Location).Path,

        [Parameter(Mandatory = $true)]
        [string] $Name,

        [string] $ModuleName,
        [string] $ThemeName,
        [string] $NuGetSource
    )

    Process
    {
        if ([string]::IsNullOrEmpty($NuGetSource))
        {
            dotnet new install OrchardCore.ProjectTemplates::1.6.0
        }
        else
        {
            dotnet new install OrchardCore.ProjectTemplates::1.6.0 --nuget-source $NuGetSource
        }

        dotnet new occms -o "$Path/src/$Name.Web"

        dotnet new sln -o "$Path" -n "$Name"
        dotnet sln "$Path/$Name.sln" add "$Path/src/$Name.Web/$Name.Web.csproj"

        if (![string]::IsNullOrEmpty($ModuleName))
        {
            dotnet new ocmodulecms -n "$ModuleName" -o "$Path/src/Modules/$ModuleName"
            dotnet add "$Path/src/$Name.Web/$Name.Web.csproj" reference "$Path/src/Modules/$ModuleName/$ModuleName.csproj"
            dotnet sln "$Path/$Name.sln" add "$Path/src/Modules/$ModuleName/$ModuleName.csproj"
        }

        if (![string]::IsNullOrEmpty($ThemeName))
        {
            dotnet new octheme -n "$ThemeName" -o "$Path/src/Themes/$ThemeName"
            dotnet add "$Path/src/$Name.Web/$Name.Web.csproj" reference "$Path/src/Themes/$ThemeName/$ThemeName.csproj"
            dotnet sln "$Path/$Name.sln" add "$Path/src/Themes/$ThemeName/$ThemeName.csproj"
        }

        Copy-Item "$PSScriptRoot\.gitignore.template" -Destination "$Path\.gitignore"
    }
}