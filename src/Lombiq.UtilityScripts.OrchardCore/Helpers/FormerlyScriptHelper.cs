using System.IO;
using CliWrap;
using Lombiq.UtilityScripts.OrchardCore.Cmdlets;

namespace Lombiq.UtilityScripts.OrchardCore.Helpers
{
    /// <summary>
    /// Helper to ease transition from the scripts.
    /// </summary>
    public static class FormerlyScriptHelper
    {
        private static string _psScriptRoot = null;

        public static string DotnetPath { get; set; } = "dotnet";

        /// <summary>
        /// Gets the string that behaves like the Powershell builtin <c>$PSScriptRoot</c>.
        /// </summary>
        public static string PSScriptRoot
        {
            get
            {
                if (_psScriptRoot == null)
                {
                    var assemblyLocation = typeof(InitializeOrchardCoreSolutionCmdletCommand).Assembly.Location;
                    _psScriptRoot = Path.GetDirectoryName(assemblyLocation);
                }

                return _psScriptRoot;
            }
        }

        public static CommandTask<CommandResult> DotnetAsync(params string[] arguments) =>
            Cli
                .Wrap(DotnetPath)
                .WithArguments(arguments)
                .ExecuteAsync();
    }
}