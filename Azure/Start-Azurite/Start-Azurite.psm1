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
        $azuriteProcessExists = [bool]$(if ($host.Version.Major -ge 7)
        {
            (Get-Process node).CommandLine -match 'azurite'
        }
        else
        {
            (Get-CimInstance Win32_Process -Filter "name = 'node.exe'").CommandLine -match 'azurite'
        })

        $azuriteJobState = (Get-Job AzuriteNodeJS -ErrorAction SilentlyContinue).State

        if ((-not $azuriteProcessExists) -and
            ($azuriteJobState -ne [System.Management.Automation.JobState]::Running))
        {
            Start-Job -Name AzuriteNodeJS -ScriptBlock { azurite --silent }
        }
    }
}
