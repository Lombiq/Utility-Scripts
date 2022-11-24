<#
.Synopsis
   Returns the process IDs for a given criteria.
.DESCRIPTION
   Returns the IDs of the active processes filtering on process name (automatically adds ".exe" on Windows Powershell)
   and optionally checks to contents of the command line invocation. The results can be passed to e.g. Stop-Process.
.EXAMPLE
   Get-ProcessId -Name node -CommandLine azurite
#>

function Get-ProcessId
{
    [CmdletBinding()]
    Param
    (
        [Parameter(Mandatory=$true)]
        [string] $Name,

        [string] $CommandLine
    )

    Process
    {
        if ([string]::IsNullOrEmpty($Name))
        {
            throw "The -Name switch must not be null or empty."
        }

        [array] $processes = Get-Process $Name -ErrorAction SilentlyContinue
        if ($null -eq $processes) { $processes = @() }

        if (-not $CommandLine) { return $processes | ForEach-Object { $PSItem.Id } }

        [hashtable[]] $processes = $(if ($host.Version.Major -ge 7)
        {
            $processes | ForEach-Object { @{ Id = $PSItem.Id; CommandLine = $PSItem.CommandLine } }
        }
        else
        {
            Get-CimInstance Win32_Process -Filter "name = '${Name}.exe'" |
                ForEach-Object { @{ Id = $PSItem.Handle; CommandLine = $PSItem.CommandLine } }
        })

        if (-not [string]::IsNullOrEmpty($CommandLine))
        {
            if (-not $CommandLine.Contains('*')) { $CommandLine = "*$CommandLine*" }

            $processes = $processes | Where-Object { $PSItem.CommandLine -like $CommandLine }
        }

        $processes | ForEach-Object { [int] $PSItem.Id }
    }
}
