<#
.Synopsis
   Renames FTP folder.
.DESCRIPTION
   Renames a folder on an FTP server.
.EXAMPLE
   Rename-FtpDirectory "ftp://server.address/folder" "user" "secure password" "DirectoryToRename" "NewDirectoryName"
#>

function Rename-FtpDirectory
{
    [CmdletBinding()]
    Param
    (
        [Parameter(Mandatory=$true,
                   ValueFromPipelineByPropertyName=$true,
                   HelpMessage = "Specify a valid FTP server path to a folder that contains the directory which
                   needs to be renamed.")]
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
                   HelpMessage = "Specify folder to rename.")]
        [string] $SourceFolder,

        [Parameter(Mandatory=$true,
                   HelpMessage = "Specify new folder name.")]
        [string] $DestinationFolder
    )

    Process
    {
        $folderToRenamePath = $Url + "/" + $SourceFolder
        $ftpFolderPath = $Url + "/" + $DestinationFolder
        $destinationFolderRelPath = "../" + $DestinationFolder
        $credentials = New-Object System.Net.NetworkCredential($User, $Password)

        # Create new folder.
        try
        {
            $makeDirectory = [System.Net.WebRequest]::Create($ftpFolderPath)
            $makeDirectory.Credentials = $credentials
            $makeDirectory.Method = [System.Net.WebRequestMethods+FTP]::MakeDirectory
            $makeDirectory.EnableSsl = $true
            $makeDirectory.GetResponse()

            Write-Host "New folder created successfully:" $ftpFolderPath
        }
        catch [Net.WebException]
        {
            try
            {
                $checkDirectory = [System.Net.WebRequest]::Create($ftpFolderPath)
                $checkDirectory.Credentials = $credentials
                $checkDirectory.Method = [System.Net.WebRequestMethods+FTP]::PrintWorkingDirectory
                $checkDirectory.EnableSsl = $true
                $checkDirectory.GetResponse()

                Write-Host "New folder already exists:" $ftpFolderPath
            }
            catch [Net.WebException]
            {
                throw "Other error encountered during new folder creation."
            }
        }

        try
        {
            Write-Host "Listing files..."

            $listRequest = [System.Net.FtpWebRequest]::Create($folderToRenamePath)
            $listRequest.Credentials = $credentials
            $listRequest.Method = [System.Net.WebRequestMethods+Ftp]::ListDirectory
            $listRequest.EnableSsl = $true

            $files = New-Object System.Collections.ArrayList

            $listResponse = $listRequest.GetResponse()
            $listStream = $listResponse.GetResponseStream()
            $listReader = New-Object System.IO.StreamReader($listStream)

            while (!$listReader.EndOfStream)
            {
                $file = $listReader.ReadLine()
                $files.Add($file) | Out-Null
            }
        }
        finally
        {
            $listReader.Dispose()
            $listStream.Dispose()
            $listResponse.Dispose()
        }

        foreach ($file in $files)
        {
            try
            {
                Write-Host "Renaming $file..."
                Write-Host "Destination:" ($destinationFolderRelPath + "/" + $file)

                $renameRequest = [System.Net.FtpWebRequest]::Create($folderToRenamePath + "/" + $file)
                $renameRequest.Credentials = $credentials
                $renameRequest.Method = [System.Net.WebRequestMethods+Ftp]::Rename
                $renameRequest.EnableSsl = $true
                $renameRequest.RenameTo = $destinationFolderRelPath + "/" + $file
                $renameResponse = $renameRequest.GetResponse()
            }
            finally
            {
                $renameResponse.Dispose()
            }
        }

        # Remove empty previous folder.
        Write-Host "Deleting now empty previous folder."

        try
        {
            $deleteRequest = [Net.WebRequest]::Create($folderToRenamePath)
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
