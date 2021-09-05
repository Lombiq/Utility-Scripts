using System;
using System.Collections.Generic;
using System.Diagnostics;
using System.Management;
using System.Management.Automation;
using System.Runtime.InteropServices;
using Lombiq.UtilityScripts.Utilities.Models;

namespace Lombiq.UtilityScripts.Utilities.Cmdlets
{
    [Cmdlet(VerbsCommon.Get, "ProcessByArgument")]
    [OutputType(typeof(ExternalProcessWithArguments))]
    public class GetProcessByArgumentCmdletCommand : Cmdlet
    {
        [Parameter(Mandatory = true, Position = 0)]
        public string Argument { get; set; }
        
        [Parameter(Mandatory = false, Position = 1)]
        public string ProcessName { get; set; }

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
            var nameWhere = string.IsNullOrWhiteSpace(ProcessName) ? string.Empty : $"Name LIKE '{ProcessName}' AND";
            var query = 
                $"SELECT ProcessId, CommandLine FROM Win32_Process " +
                $"WHERE {nameWhere} CommandLine LIKE '%{Argument}%'";

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

        private IEnumerable<ExternalProcessWithArguments> ProcessLinux() =>
            throw new NotSupportedException("Linux support is coming soon. See GitHub issue here: TODO");
    }
}