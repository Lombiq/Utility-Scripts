using System;
using System.Collections.Generic;
using System.Diagnostics;
using System.Management;
using System.Management.Automation;
using System.Runtime.InteropServices;

namespace Lombiq.UtilityScripts.Utilities.Cmdlets
{
    [Cmdlet(VerbsCommon.Get, "ProcessByArgument")]
    [OutputType(typeof(Process))]
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
        
        private IEnumerable<Process> ProcessWindows()
        {
            var nameWhere = string.IsNullOrWhiteSpace(ProcessName) ? string.Empty : $"(Name = '{ProcessName}.exe') and";
            var query = 
                $"SELECT ProcessId, Name, CommandLine FROM Win32_Process " +
                $"WHERE {nameWhere} CommandLine like '%{Argument}%'";

            var list = new List<Process>();
            using (var searcher = new ManagementObjectSearcher(query))
            {
                foreach (var result in searcher.Get())
                {
                    var processIdString = result["ProcessId"]?.ToString();
                    var process = int.TryParse(processIdString, out var processId) 
                        ? Process.GetProcessById(processId) 
                        : null;
                    
                    if (process == null) continue;
                    
                    list.Add(process);
                }
            }

            return list;
        }

        private IEnumerable<Process> ProcessLinux() =>
            throw new NotSupportedException("Linux support is coming soon. See GitHub issue here: TODO");
    }
}