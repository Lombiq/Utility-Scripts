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
    [Alias("saazu")]
    Param ()

    Process
    {
        $azuriteProcess = Get-WmiObject Win32_Process -Filter "name = 'node.exe'" | Select-Object CommandLine | Select-String "azurite"
        $azuriteJob = Get-Job AzuriteNodeJS -ErrorAction SilentlyContinue

        if ($null -eq $azuriteProcess -or $null -eq $azuriteJob -or $azuriteJob.State -ne [System.Management.Automation.JobState]::Running)
        {
            Start-Job -Name AzuriteNodeJS -ScriptBlock { azurite --silent }
        }
    }
}
