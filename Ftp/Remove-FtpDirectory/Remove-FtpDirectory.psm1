<#
.Synopsis
   Removes FTP folder.
.DESCRIPTION
   Recursively removes a folder on an FTP server.
.EXAMPLE
   Remove-FtpDirectory "ftp://server.address/folder" "user" "secure password"
#>

function Remove-FtpDirectory
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
        [securestring] $Password
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

            $fileUrl = ($Url + "/" + $name)

            if ($isDirectory)
            {
                Remove-FtpDirectory ($fileUrl + "/") $User $Password
            }
            else
            {
                try
                {
                    Write-Host "Deleting file $name"
                    $deleteRequest = [Net.WebRequest]::Create($fileUrl)
                    $deleteRequest.Credentials = $credentials
                    $deleteRequest.Method = [System.Net.WebRequestMethods+Ftp]::DeleteFile
                    $deleteRequest.EnableSsl = $true
                    $deleteResponse = $deleteRequest.GetResponse() | Out-Null
                }
                finally
                {
                    if ($deleteResponse)
                    {
                        Write-Host "Delete response disposed."
                        $deleteResponse.Dispose()
                    }
                }
            }
        }

        try
        {
            Write-Host "Deleting folder."

            $deleteRequest = [Net.WebRequest]::Create($Url)
            $deleteRequest.Credentials = $credentials
            $deleteRequest.Method = [System.Net.WebRequestMethods+Ftp]::RemoveDirectory
            $deleteRequest.EnableSsl = $true
            $deleteResponse = $deleteRequest.GetResponse() | Out-Null
        }
        finally
        {
            if ($deleteResponse)
            {
                Write-Host "Delete response disposed."
                $deleteResponse.Dispose()
            }
        }
    }
}
