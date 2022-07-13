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
        [Parameter(Mandatory = $true, HelpMessage = "Please specify the list of executable names to stop.")]
        [string[]] $ProcessNames,

        [string] $Path,

        [string] $CommandLine,

        [Parameter(HelpMessage = "The number of seconds to wait between the attempts to shut down the matching processes. Default value is 5.")]
        [int] $RetryInterval = 5,

        [Parameter(HelpMessage = "The number of attempts to shut down the matching processes. The default value is 3.")]
        [int] $RetryCount = 3
    )
    
    process
    {
        $ProcessNames = $ProcessNames | ForEach-Object { "$($_).exe" }

        if ($ProcessNames -contains "dotnet")
        {
            dotnet build-server shutdown
        }

        $finished = $false
        $retryCounter = 0

        do
        {
            if ($retryCounter -gt 0)
            {
                Start-Sleep -Seconds $RetryInterval
            }

            Get-Processes -ProcessNames $ProcessNames -Path $Path -CommandLine $CommandLine | Select-Object { $_.Terminate() } | Out-Null

            if ($null -eq (Get-Processes -ProcessNames $ProcessNames -Path $Path -CommandLine $CommandLine))
            {
                $finished = $true
            }
            else
            {
                $retryCounter++

                $finished = $retryCounter -gt $RetryCount
            }
        } until ($finished)
    }
}

function Get-Processes
{
    [CmdletBinding()]
    param
    (
        [string[]] $ProcessNames,

        [string] $Path,

        [string] $CommandLine
    )

    Process
    {
        $processes = Get-WmiObject Win32_Process | Where-Object { $ProcessNames -contains $_.Name }

        if (-not [string]::IsNullOrEmpty($Path))
        {
            $processes = $processes | Where-Object { $_.Path.Contains($Path) }
        }

        if (-not [string]::IsNullOrEmpty($CommandLine))
        {
            $processes = $processes | Where-Object { $_.CommandLine.Contains($CommandLine) }
        }

        return $processes
    }
}