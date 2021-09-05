using System;
using System.Collections.Generic;
using System.Diagnostics;
using System.Management;
using System.Management.Automation;
using System.Runtime.InteropServices;

namespace Lombiq.UtilityScripts.Utilities.Cmdlets
{
    [Cmdlet(VerbsCommon.Get, "ProcessByArgument")]
    [OutputType(typeof(ProcessStartInfo))]
    public class GetProcessByArgumentCmdletCommand : Cmdlet
    {
        [Parameter(Mandatory = true, Position = 0)]
        public string Argument { get; set; }
        
        [Parameter(Mandatory = false, Position = 1)]
        public string ProcessName { get; set; }

        protected override void ProcessRecord()
        {
            var infos = RuntimeInformation.IsOSPlatform(OSPlatform.Linux)
                ? ProcessLinux()
                : ProcessWindows();

            foreach (var info in infos) WriteObject(info);
        }
        
        private IEnumerable<ProcessStartInfo> ProcessWindows()
        {
            var query = 
                $"SELECT CommandLine FROM Win32_Process " +
                $"WHERE (Name = '{ProcessName}.exe') and CommandLine like '%{Argument}%'";

            var list = new List<ProcessStartInfo>();
            using (var searcher = new ManagementObjectSearcher(query))
            {
                foreach (var result in searcher.Get())
                {
                    var processIdString = result["ProcessId"]?.ToString();
                    var processStartInfo = int.TryParse(processIdString, out var processId) 
                        ?  Process.GetProcessById(processId)?.StartInfo 
                        : null;
                    
                    if (processStartInfo == null) continue;
                    processStartInfo.Arguments = result["CommandLine"]?.ToString() ?? string.Empty;
                    
                    list.Add(processStartInfo);
                }
            }

            return list;
        }

        private IEnumerable<ProcessStartInfo> ProcessLinux() =>
            throw new NotSupportedException("Linux support is coming soon. See GitHub issue here: TODO");
    }
}