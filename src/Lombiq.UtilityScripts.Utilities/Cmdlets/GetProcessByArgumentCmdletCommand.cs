using System;
using System.Collections.Generic;
using System.Diagnostics;
using System.IO;
using System.Management;
using System.Management.Automation;
using System.Runtime.InteropServices;
using Lombiq.UtilityScripts.Utilities.Models;

namespace Lombiq.UtilityScripts.Utilities.Cmdlets
{
    /// <summary>
    /// Returns a collection of <see cref="Process"/> &amp; command line argument pairs where it matches the search text
    /// in the <see cref="Argument"/> parameter (case-insensitive).
    /// </summary>
    [Cmdlet(VerbsCommon.Get, "ProcessByArgument")]
    [OutputType(typeof(ExternalProcessWithArguments))]
    public class GetProcessByArgumentCmdletCommand : Cmdlet
    {
        [Parameter(
            Mandatory = true,
            Position = 0,
            HelpMessage = "The text to be searched (case-insensitive) in the process command line arguments.")]
        public string Argument { get; set; }

        protected override void ProcessRecord()
        {
            try
            {
                var infos = RuntimeInformation.IsOSPlatform(OSPlatform.Linux)
                    ? ProcessLinux()
                    : ProcessWindows();

                foreach (var info in infos) WriteObject(info);
            }
            catch (Exception ex)
            {
                Console.WriteLine(ex);
            }
        }

        private IEnumerable<ExternalProcessWithArguments> ProcessWindows()
        {
            var query = 
                $"SELECT ProcessId, CommandLine FROM Win32_Process " +
                $"WHERE CommandLine LIKE '%{Argument}%'";

            var list = new List<ExternalProcessWithArguments>();
            using (var searcher = new ManagementObjectSearcher(query))
            {
                foreach (var result in searcher.Get())
                {
                    var processIdString = result["ProcessId"]?.ToString();
                    var process = int.TryParse(processIdString, out var processId) 
                        ? Process.GetProcessById(processId) 
                        : null;
                    
                    if (process == null) continue;
                    
                    list.Add(new ExternalProcessWithArguments
                    {
                        Process = process,
                        CommandLine = result["CommandLine"]?.ToString() ?? string.Empty
                    });
                }
            }

            return list;
        }

        private IEnumerable<ExternalProcessWithArguments> ProcessLinux()
        {
            var argument = Argument.ToUpperInvariant();
            var list = new List<ExternalProcessWithArguments>();

            foreach (var process in Process.GetProcesses())
            {
                if (!File.Exists($"/proc/{process.Id}/cmdline")) continue;
                var commandLine = File.ReadAllText($"/proc/{process.Id}/cmdline") ?? string.Empty;

                if (commandLine.ToUpperInvariant().Contains(argument))
                {
                    list.Add(new ExternalProcessWithArguments
                    {
                        Process = process,
                        CommandLine = commandLine,
                    });
                }
            }

            return list;
        }
    }
}