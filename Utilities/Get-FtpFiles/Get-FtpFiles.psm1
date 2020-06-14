<#
.Synopsis
   Downloads all files from a folder on an FTP server.
#>


# Session.FileTransferProgress event handler.
function FileTransferProgress
{
    param
    (
        [WinSCP.FileTransferProgressEventArgs] $event
    )

    if ($script:lastFileName -ne $null -and $script:lastFileName -ne $event.FileName)
    {
        Write-Host
    }

    $currentFileName = $event.FileName
    $currentFileProgress = $event.FileProgress

    # If the progress changed compared to the previous state.
    if ($currentFileName -ne $script:lastFileName -or $currentFileProgress -ne $script:lastFileProgress)
    {
        # Print transfer progress.
        Write-Host ("$($event.FileName): $($event.FileProgress * 100)%, Overall: $($event.OverallProgress * 100)%")
 
        # Remember the name of the last file reported.
        $script:lastFileName = $event.FileName
        $script:lastFileProgress = $event.FileProgress        
    }
}


function Get-FtpFiles
{
    [CmdletBinding()]
    [Alias("gff")]
    Param
    (
        # The path of a folder that contains "WinSCPnet.dll" and "WinSCPnet.exe".
        [Parameter(Mandatory=$true)]
        [string] $WinSCPPath = $(throw "You need to provide the path to a folder that contains `"WinSCPnet.dll`" and `"WinSCPnet.exe`"."),

        [Parameter(Mandatory=$true)]
        [string] $FtpHostName,

        [Parameter(Mandatory=$true)]
        [string] $FtpUsername,

        [Parameter(Mandatory=$true)]
        [string] $FtpPassword,

        [Parameter(Mandatory=$true)]
        [string] $DownloadSourcePath,

        [Parameter(Mandatory=$true)]
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
            FtpSecure = [WinSCP.FtpSecure]::Implicit
            HostName = $FtpHostName
            UserName = $FtpUsername
            Password = $FtpPassword
        }

        $session = New-Object WinSCP.Session

        try
        {
            $session.add_FileTransferProgress({ FileTransferProgress($_) })

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