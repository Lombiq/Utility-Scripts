<#
.Synopsis
   Downloads all files from a folder on an FTP server.
#>


# Session.FileTransferProgress event handler.
function FileTransferProgress
{
    param
    (
        [System.Object] $transferEvent
    )

    if ($null -ne $script:lastFileName -and $script:lastFileName -ne $transferEvent.FileName)
    {
        Write-Verbose "Next File: $($transferEvent.FileName)"
    }

    $currentFileName = $transferEvent.FileName
    $currentFileProgress = $transferEvent.FileProgress

    # If the progress changed compared to the previous state.
    if ($currentFileName -ne $script:lastFileName -or $currentFileProgress -ne $script:lastFileProgress)
    {
        # Print transfer progress.
        Write-Verbose ("$($transferEvent.FileName): $($transferEvent.FileProgress * 100)%, Overall: $($transferEvent.OverallProgress * 100)%")

        # Remember the name of the last file reported.
        $script:lastFileName = $transferEvent.FileName
        $script:lastFileProgress = $transferEvent.FileProgress
    }
}


function Get-FtpFile
{
    [CmdletBinding()]
    [Alias("gff")]
    Param
    (
        # The path of a folder that contains "WinSCPnet.dll" and "WinSCPnet.exe".
        [Parameter(
            Mandatory = $true,
            HelpMessage = "You need to provide the path to a folder that contains `"WinSCPnet.dll`" and `"WinSCPnet.exe`".")]
        [string] $WinSCPPath,

        [Parameter(Mandatory = $true)]
        [string] $FtpHostName,

        [Parameter(Mandatory = $true)]
        [string] $FtpUsername,

        [Parameter(Mandatory = $true)]
        [SecureString] $FtpSecurePassword,

        [Parameter(Mandatory = $true)]
        [string] $DownloadSourcePath,

        [Parameter(Mandatory = $true)]
        [string] $DownloadDestinationPath
    )

    Begin
    {
        [Reflection.Assembly]::LoadFrom("\\$WinSCPPath\WinSCPnet.dll") | Out-Null

        $script:lastFileName = ""
        $script:lastFileProgress = ""
    }
    Process
    {
        $sessionOptions = New-Object WinSCP.SessionOptions -Property @{
            Protocol = [WinSCP.Protocol]::Ftp
            FtpSecure = [WinSCP.FtpSecure]::Explicit
            HostName = $FtpHostName
            UserName = $FtpUsername
            SecurePassword = $FtpSecurePassword
        }

        $session = New-Object WinSCP.Session

        try
        {
            $session.add_FileTransferProgress({ FileTransferProgress($PSItem) })

            $session.Open($sessionOptions)

            if ($session.FileExists($DownloadSourcePath))
            {
                $session.GetFiles("$DownloadSourcePath/*", "$DownloadDestinationPath\*").Check()
            }
            else
            {
                throw ("The path `"$DownloadSourcePath`" is invalid!")
            }
        }
        finally
        {
            $session.Dispose()
        }
    }
}