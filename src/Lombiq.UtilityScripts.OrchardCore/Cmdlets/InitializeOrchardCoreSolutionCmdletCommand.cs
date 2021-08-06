using System;
using System.Collections.Generic;
using System.IO;
using System.Management.Automation;
using System.Threading.Tasks;
using Lombiq.UtilityScripts.OrchardCore.Constants;
using IoPath = System.IO.Path;
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
    [OutputType(typeof(FileInfo))]
    public class InitializeOrchardCoreSolutionCmdletCommand : AsyncCmdletBase
    {
        private const string _cmdletName = VerbsData.Initialize + "-" + NounNames.OrchardCore;
        protected override string CmdletName => _cmdletName;
        
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


        protected override async Task ProcessRecordAsync()
        {
            if (string.IsNullOrWhiteSpace(Path)) Path = Environment.CurrentDirectory;

            var solutionFilePath = $"{Path}/{Name}.sln";

            var installArguments = new List<string> { "new", "-i", "OrchardCore.ProjectTemplates::1.0.0-*" };
            if (!string.IsNullOrWhiteSpace(NuGetSource)) installArguments.Add(NuGetSource);
            await DotnetAsync(installArguments.ToArray());
            
            await DotnetAsync("occms", "-o", $"{Path}/src/$Name.Web");
            await DotnetAsync("new", "sln", "-o", Path, "-n", Name);

            if (!string.IsNullOrWhiteSpace(ModuleName))
            {
                await DotnetAsync("new", "ocmodulecms", "-n", ModuleName, "-o", $"{Path}/src/Modules/{ModuleName}");
                await DotnetAsync("add", $"{Path}/src/{Name}.Web/{Name}.Web.csproj", "reference", $"{Path}/src/Modules/{ModuleName}/{ModuleName}.csproj");
                await DotnetAsync("sln", solutionFilePath, "add", $"{Path}/src/Modules/{ModuleName}/{ModuleName}.csproj");
            }

            if (!string.IsNullOrWhiteSpace(ThemeName))
            {
                await DotnetAsync("new", "octheme", "-n", ThemeName, "-o", $"{Path}/src/Themes/{ThemeName}");
                await DotnetAsync("add", $"{Path}/src/{Name}.Web/{Name}.Web.csproj", "reference", $"{Path}/src/Themes/{ThemeName}/{ThemeName}.csproj");
                await DotnetAsync("sln", solutionFilePath, "add", $"{Path}/src/Themes/{ThemeName}/{ThemeName}.csproj");
            }
            
            File.Copy(
                IoPath.Combine(PSScriptRoot, "gitignore.template"),
                IoPath.Combine(Path, ".gitignore"));
            
            WriteObject(new FileInfo(solutionFilePath));
        }
    }
}