<#
.Synopsis
   Pings a specified URL.
.DESCRIPTION
   Pings a specified URL with retries if unsuccessful.
.EXAMPLE
   Test-Url "http://lombiq.com"
.EXAMPLE
   Test-Url "http://lombiq.com" -Timeout 32 -Interval 16 -RetryCount 8
#>

function Test-Url
{
    [CmdletBinding()]
    [Alias("turl")]
    [OutputType([bool])]
    Param
    (
        [Parameter(Mandatory=$true,
                   ValueFromPipelineByPropertyName=$true,
                   Position=0,
                   HelpMessage = "Please specify a full URL (including protocol) to ping.")]
        [string] $Url,

        [Parameter(HelpMessage = "Request timeout in seconds. The default value is 100.")]
        [int] $Timeout = 100,

        [Parameter(HelpMessage = "The number of seconds to wait between ping attempts. The default value is 15.")]
        [int] $Interval = 15,

        [Parameter(HelpMessage = "The number of attempts for pinging the specified URL. The default value is 3.")]
        [int] $RetryCount = 3
    )

    Process
    {
        Write-Host ("`n*****`nAttempting to ping `"$Url`": $Timeout second timeout, $Interval second interval, $RetryCount retries!`n*****`n")

        $success = $false
        $retryCounter = 0

        do
        {
            try
            {
                Invoke-WebRequest -UseBasicParsing -Uri $Url -TimeoutSec $Timeout

                $success = $true
            }
            catch
            {
                $retryCounter++

                Write-Host ("Attempt #$retryCounter to ping the URL `"$Url`" failed with the following error:`n$($_.Exception)`n")
                
                if ($retryCounter -gt $RetryCount)
                {
                    throw ("Failed to reach the URL `"$Url`"!")
                }

                Start-Sleep -Seconds $Interval
            }
        }
        while (!$success)

        return $true
    }
}
