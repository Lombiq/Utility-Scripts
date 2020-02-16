<#
.Synopsis
   Initializes an Orchard Core project.

.DESCRIPTION
   Initializes an Orchard Core project using the latest Orchard Core NuGet packages. Optionally creates an initial module and/or theme.

.EXAMPLE
   Init-OrchardCore -Name "FancyWebsite" -Path "D:\Work\FancyWebsite" -ModuleName "FancyWebsite.Core" -ThemeName "FancyWebsite.Theme"
#>


function Init-OrchardCore
{
    [CmdletBinding()]
    Param
    (
        [Parameter(Mandatory=$true)]
        [string] $Path,
		
        [Parameter(Mandatory=$true)]
        [string] $Name,

        [string] $ModuleName,
        [string] $ThemeName
    )

    Process
    {
        dotnet new -i OrchardCore.ProjectTemplates::1.0.0-rc1-* --nuget-source https://www.myget.org/F/orchardcore-preview/api/v3/index.json
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

        Copy-Item "$PSScriptRoot\gitignore.template" -Destination "$Path\.gitignore"
    }
}