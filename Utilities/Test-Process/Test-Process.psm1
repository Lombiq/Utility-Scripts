<#
.Synopsis
   Checks if the process exists.
.DESCRIPTION
   Checks if the process exists by filtering on process name (automatically adds ".exe" on Windows Powershell) and
   optionally matches against the command line invocation. Returns True if at least one result is found.
.EXAMPLE
   Test-Process -Name node -CommandLine azurite
#>

function Test-Process
{
    [CmdletBinding()]
    [OutputType([bool])]
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

        if (-not $CommandLine) { return (Get-Process $Name).Count -gt 0 }

        [array] $processes = $(if ($host.Version.Major -ge 7)
        {
            Get-Process $Name
        }
        else
        {
            Get-CimInstance Win32_Process -Filter "name = '${Name}.exe'"
        })

        if (-not [string]::IsNullOrEmpty($CommandLine))
        {
            # We do it this way, because $processes has the explicit [array] type so the result is kept as array as
            # well. Otherwise on Windows PowerShell the result would be converted to [string] if there is only one.
            $processes = $processes | ? { $_.CommandLine -match $CommandLine }
        }

        $processes.Count -gt 0
    }
}
