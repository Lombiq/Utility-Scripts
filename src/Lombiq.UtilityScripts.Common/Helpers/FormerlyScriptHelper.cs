using System;
using System.IO;
using CliWrap;
using Lombiq.UtilityScripts.Common.Cmdlets;

namespace Lombiq.UtilityScripts.Common.Helpers
{
    /// <summary>
    /// Helper to ease transition from the scripts.
    /// </summary>
    public static class FormerlyScriptHelper
    {
        private static string? _psScriptRoot = null;

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
                    var assemblyLocation = typeof(AsyncCmdletBase).Assembly.Location;
                    _psScriptRoot = Path.GetDirectoryName(assemblyLocation) ?? Environment.CurrentDirectory;
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