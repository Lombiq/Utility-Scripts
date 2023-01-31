<#
.Synopsis
    Starts Azurite, the new Azure Storage Emulator.

.DESCRIPTION
    Starts the NodeJS version of Azurite, the new Azure Storage Emulator, as a PowerShell Job.

.EXAMPLE
    Start-Azurite
#>


function Start-Azurite
{
    [CmdletBinding()]
    [Alias('saazu')]
    Param ()

    Process
    {
        [bool] $azuriteProcessExists = Get-ProcessId -Name node -CommandLine azurite
        $azuriteJobState = (Get-Job AzuriteNodeJS -ErrorAction SilentlyContinue).State

        if ((-not $azuriteProcessExists) -and
            ($azuriteJobState -ne [System.Management.Automation.JobState]::Running))
        {
            Start-Job -Name AzuriteNodeJS -ScriptBlock { azurite --silent }
        }
    }
}
