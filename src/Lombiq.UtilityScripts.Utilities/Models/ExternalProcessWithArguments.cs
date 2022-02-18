using System.Diagnostics;

namespace Lombiq.UtilityScripts.Utilities.Models
{
    public class ExternalProcessWithArguments
    {
        public Process Process { get; set; }
        public string CommandLine { get; set; }
    }
}