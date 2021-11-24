<#
.DESCRIPTION
    Stops processes defined by the executable file name (without extension), optionally filtered by the path of the
    executable or a string found in their command line arguments.
.PARAMETER ProcessNames
    The list of process names without extension.
.PARAMETER Path
    The path or path segment to filter the processes with.
.PARAMETER CommandLine
    A string to filter on the command line arguments of the processes.
.EXAMPLE
    Stop-Processes -ProcessNames YouHadOneJob, CloseMe
.EXAMPLE
    Stop-Processes -ProcessNames YouHadOneJob, CloseMe -Path "C:\temp"
.EXAMPLE
    Stop-Processes -ProcessNames YouHadOneJob, CloseMe -Path "C:\temp" -CommandLine "weirdparameter"
#>

function Stop-Processes
{
    [CmdletBinding()]
    [Alias("sps")]
    param
    (
        [Parameter(Mandatory = $true, HelpMessage = "Please specifiy the list of executable names to stop.")]
        [string[]] $ProcessNames,

        [string] $Path,

        [string] $CommandLine
    )
    
    process
    {
        $ProcessNames = $ProcessNames | ForEach-Object { "$($_).exe" }

        $processes = Get-WmiObject Win32_Process | Where-Object { $ProcessNames -contains $_.Name }

        if (-not [string]::IsNullOrEmpty($Path))
        {
            $processes = $processes | Where-Object { $_.Path.Contains($Path) }
        }

        if (-not [string]::IsNullOrEmpty($CommandLine))
        {
            $processes = $processes | Where-Object { $_.CommandLine.Contains($CommandLine) }
        }

        $processes | Select-Object { $_.Terminate() } | Out-Null
    }
}
