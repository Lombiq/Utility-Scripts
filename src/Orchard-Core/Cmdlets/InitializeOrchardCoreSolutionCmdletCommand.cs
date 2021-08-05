using System;
using System.Collections.Generic;
using System.Management.Automation;
using CliWrap;
using Lombiq.UtilityScripts.OrchardCore.Constants;
using static Lombiq.UtilityScripts.OrchardCore.Helpers.FormerlyScriptHelper;

namespace Lombiq.UtilityScripts.OrchardCore.Cmdlets
{
    // TODO: How to turn this into help docs? Maybe this? https://docs.microsoft.com/en-us/powershell/scripting/dev-cross-plat/create-help-using-platyps?view=powershell-7.1 
    
    /// <summary>
    /// Initializes an Orchard Core solution for a git repository.
    /// </summary>
    /// <remarks>
    /// <para>
    /// Initializes an Orchard Core solution using the latest released Orchard Core NuGet packages at the current
    /// location or under the given path, and adds a suitable .gitignore file. Optionally creates an initial module
    /// and/or theme, and optionally uses a given NuGet source.
    /// </para>
    /// </remarks>
    /// <example>
    /// <para>
    /// Init-OrchardCoreSolution
    ///     -Name "FancyWebsite"
    ///     -Path "D:\Work\FancyWebsite"
    ///     -ModuleName "FancyWebsite.Core"
    ///     -ThemeName "FancyWebsite.Theme"
    ///     -NuGetSource "https://nuget.cloudsmith.io/orchardcore/preview/v3/index.json"
    /// </para>
    /// </example>
    [Cmdlet(VerbsData.Initialize, NounNames.OrchardCoreSolution)]
    [Alias(VerbsData.Initialize + "-" + NounNames.OrchardCore)]
    [OutputType(typeof(FavoriteStuff))]
    public class InitializeOrchardCoreSolutionCmdletCommand : PSCmdlet
    {
        [Parameter(Position = 0)]
        public string Path { get; set; }

        [Parameter(Mandatory = true, Position = 1)]
        public string Name { get; set; }

        [Parameter(Position = 2)]
        public string ModuleName { get; set; }

        [Parameter(Position = 3)]
        public string ThemeName { get; set; }

        [Parameter(Position = 4)]
        public string NuGetSource { get; set; }

        private string _dotnetPath = null;

        protected override void ProcessRecord()
        {
            if (string.IsNullOrWhiteSpace(Path)) Path = Environment.CurrentDirectory;

            _dotnetPath = "dotnet";

            var installArguments = new List<string> { "new", "-i", "OrchardCore.ProjectTemplates::1.0.0-*" };
            if (!string.IsNullOrWhiteSpace(NuGetSource)) installArguments.Add(NuGetSource);
            Dotnet(installArguments.ToArray());
            
            Dotnet("occms", "-o", $"{Path}/src/$Name.Web");
            Dotnet("new", "sln", "-o", Path, "-n", Name);

            if (!string.IsNullOrWhiteSpace(ModuleName))
            {
                Dotnet("new", "ocmodulecms", "-n", ModuleName, "-o", $"{Path}/src/Modules/{ModuleName}");
                Dotnet("add", $"{Path}/src/{Name}.Web/{Name}.Web.csproj", "reference", $"{Path}/src/Modules/{ModuleName}/{ModuleName}.csproj");
                Dotnet("sln", $"{Path}/{Name}.sln", "add", $"{Path}/src/Modules/{ModuleName}/{ModuleName}.csproj");
            }

            if (!string.IsNullOrWhiteSpace(ThemeName))
            {
                Dotnet("new", "octheme", "-n", ThemeName, "-o", $"{Path}/src/Themes/{ThemeName}");
                Dotnet("add", $"{Path}/src/{Name}.Web/{Name}.Web.csproj", "reference", $"{Path}/src/Themes/{ThemeName}/{ThemeName}.csproj");
                Dotnet("sln", $"{Path}/{Name}.sln", "add", $"{Path}/src/Themes/{ThemeName}/{ThemeName}.csproj");
            }
            
            System.IO.File.Copy(
                System.IO.Path.Combine(PSScriptRoot, "gitignore.template"),
                System.IO.Path.Combine(Path, ".gitignore"));
        }

        private void Dotnet(params string[] arguments) =>
            Cli
                .Wrap(_dotnetPath)
                .WithArguments(arguments);
    }
}