<#
.Synopsis
   Downloads FTP folder.
.DESCRIPTION
   Recursively downloads a folder from an FTP server.
.EXAMPLE
   Get-FtpDirectory "ftp://server.address/folder" "user" "secure password" "C:\Path\To\Folder"
#>

function Get-FtpDirectory
{
    [CmdletBinding()]
    Param
    (
        [Parameter(Mandatory=$true,
                   ValueFromPipelineByPropertyName=$true,
                   HelpMessage = "Specify a valid FTP server path to a folder.")]
        [string] $Url,

        [Parameter(Mandatory=$true,
                   ValueFromPipelineByPropertyName=$true,
                   HelpMessage = "Provide username.")]
        [string] $User,

        [Parameter(Mandatory=$true,
                   ValueFromPipelineByPropertyName=$true,
                   HelpMessage = "Provide password in SecureString format.")]
        [securestring] $Password,

        [Parameter(Mandatory=$true,
                   HelpMessage = "Specify path to local folder to download.")]
        [string] $LocalPath
    )

    Process
    {
        try
        {
            $credentials = New-Object System.Net.NetworkCredential($User, $Password)
            
            $listRequest = [Net.WebRequest]::Create($Url)
            $listRequest.Method = [System.Net.WebRequestMethods+Ftp]::ListDirectoryDetails
            $listRequest.EnableSsl = $true
            $listRequest.Credentials = $credentials
            
            $lines = New-Object System.Collections.ArrayList
            
            $listResponse = $listRequest.GetResponse()
            $listStream = $listResponse.GetResponseStream()
            $listReader = New-Object System.IO.StreamReader($listStream)
            
            while (!$listReader.EndOfStream)
            {
                $line = $listReader.ReadLine()
                $lines.Add($line) | Out-Null
            }
        }
        finally
        {
            $listReader.Dispose()
            $listStream.Dispose()
            $listResponse.Dispose()
        }
        
        foreach ($line in $lines)
        {
            $tokens = $line.Split(" ", 9, [StringSplitOptions]::RemoveEmptyEntries)
            $name = $tokens[3]
            $isDirectory = $tokens[2] -eq "<DIR>"
            
            $localFilePath = Join-Path $LocalPath $name
            $fileUrl = ($Url + "/" + $name)
            
            if ($isDirectory)
            {
                if (!(Test-Path $localFilePath -PathType container))
                {
                    Write-Host "Creating directory $localFilePath"
                    New-Item $localFilePath -Type directory | Out-Null
                }
                
                Get-FtpDirectory ($fileUrl + "/") $User $Password $localFilePath
            }
            else
            {
                try
                {
                    Write-Host "Downloading $fileUrl to $localFilePath"
                    
                    $downloadRequest = [Net.WebRequest]::Create($fileUrl)
                    $downloadRequest.Method = [System.Net.WebRequestMethods+Ftp]::DownloadFile
                    $downloadRequest.EnableSsl = $true
                    $downloadRequest.Credentials = $credentials
                    
                    $downloadResponse = $downloadRequest.GetResponse()
                    $sourceStream = $downloadResponse.GetResponseStream()
                    $targetStream = [System.IO.File]::Create($localFilePath)
                    $buffer = New-Object byte[] 10240
                    
                    while (($read = $sourceStream.Read($buffer, 0, $buffer.Length)) -gt 0)
                    {
                        $targetStream.Write($buffer, 0, $read)
                    }
                }
                finally
                {
                    $targetStream.Dispose()
                    $sourceStream.Dispose()
                    $downloadResponse.Dispose()
                }
            }
        }
    }
}
