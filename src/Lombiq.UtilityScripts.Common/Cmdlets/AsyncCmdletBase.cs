using System;
using System.Management.Automation;
using System.Threading.Tasks;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Logging;

namespace Lombiq.UtilityScripts.Common.Cmdlets
{
    public abstract class AsyncCmdletBase : PSCmdlet
    {
        protected abstract string CmdletName { get; }

        private ServiceProvider? _provider;
        private IServiceProvider? _scopeProvider;

        protected IServiceProvider ServiceProvider =>
            _scopeProvider ?? _provider ?? throw new InvalidOperationException($"{nameof(BeginProcessing)} was not called!"); 

        protected override void BeginProcessing()
        {
            var services = new ServiceCollection();
            services.AddLogging(options => options.AddConsole());
            services.AddSingleton<PSCmdlet>(this);
            services.AddSingleton(this);
            
            Configure(services);
            _provider = services.BuildServiceProvider();
        }

        protected override void ProcessRecord()
        {
            try
            {
                if (_scopeProvider != null)
                {
                    throw new InvalidOperationException("Overlapping scopes! This should not be possible.");
                }
                
                using var scope = ServiceProvider.CreateScope();
                _scopeProvider = scope.ServiceProvider;
                
                ProcessRecordAsync().Wait();

                _scopeProvider = null;
            }
            catch (Exception exception)
            {
                Error(exception, ErrorCategory.NotSpecified);
            }
        }

        protected override void EndProcessing() => _provider?.Dispose();

        protected virtual void Configure(IServiceCollection services) { }

        protected abstract Task ProcessRecordAsync();

        protected void Info(string message) => WriteInformation(new InformationRecord(message, CmdletName));
        protected void Error(Exception exception, ErrorCategory errorCategory) =>
            WriteError(new ErrorRecord(exception, exception.GetType().Name, errorCategory, CmdletName));
    }
}