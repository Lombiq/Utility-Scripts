using System;
using System.Management.Automation;
using System.Threading.Tasks;

namespace Lombiq.UtilityScripts.Common.Cmdlets
{
    public abstract class AsyncCmdletBase : PSCmdlet
    {
        protected abstract string CmdletName { get; }

        protected override void ProcessRecord()
        {
            try
            {
                ProcessRecordAsync().Wait();
            }
            catch (Exception exception)
            {
                Error(exception, ErrorCategory.NotSpecified);
            }
        }

        protected abstract Task ProcessRecordAsync();

        protected void Info(string message) => WriteInformation(new InformationRecord(message, CmdletName));
        protected void Error(Exception exception, ErrorCategory errorCategory) =>
            WriteError(new ErrorRecord(exception, exception.GetType().Name, errorCategory, CmdletName));
    }
}