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

        # Create App_Data folder.
        try
        {
            $makeDirectory = [System.Net.WebRequest]::Create($ftpFolderPath)
            $makeDirectory.Credentials = $credentials
            $makeDirectory.Method = [System.Net.WebRequestMethods+FTP]::MakeDirectory
            $makeDirectory.GetResponse()

            Write-Host "App_Data folder created successfully:" $ftpFolderPath
        }
        catch [Net.WebException]
        {
            try
            {
                $checkDirectory = [System.Net.WebRequest]::Create($ftpFolderPath)
                $checkDirectory.Credentials = $credentials
                $checkDirectory.Method = [System.Net.WebRequestMethods+FTP]::PrintWorkingDirectory
                $checkDirectory.GetResponse()

                Write-Host "App_Data folder already exists:" $ftpFolderPath
            }
            catch [Net.WebException]
            {
                throw "Other error encountered during App_Data folder creation."
            }    
        }

        Write-Host "Listing files..."

        $listRequest = [System.Net.FtpWebRequest]::Create($folderToRenamePath)
        $listRequest.Credentials = $credentials
        $listRequest.Method = [System.Net.WebRequestMethods+Ftp]::ListDirectory

        $files = New-Object System.Collections.ArrayList

        $listResponse = $listRequest.GetResponse()
        $listStream = $listResponse.GetResponseStream()
        $listReader = New-Object System.IO.StreamReader($listStream)

        while (!$listReader.EndOfStream)
        {
            $file = $listReader.ReadLine()
            $files.Add($file) | Out-Null
        }

        $listReader.Dispose()
        $listStream.Dispose()
        $listResponse.Dispose()

        foreach ($file in $files)
        {
            Write-Host "Renaming $file..."
            Write-Host "Destination:" ($destinationFolderRelPath + "/" + $file)

            $renameRequest = [System.Net.FtpWebRequest]::Create($folderToRenamePath + "/" + $file)
            $renameRequest.Credentials = $credentials
            $renameRequest.Method = [System.Net.WebRequestMethods+Ftp]::Rename
            $renameRequest.RenameTo = $destinationFolderRelPath + "/" + $file
            $renameRequest.GetResponse().Dispose()
        }

        # Remove empty App_Data_new folder.
        Write-Host "Deleting now empty App_Data_new folder."

        $deleteRequest = [Net.WebRequest]::Create($folderToRenamePath)
        $deleteRequest.Credentials = $credentials
        $deleteRequest.Method = [System.Net.WebRequestMethods+Ftp]::RemoveDirectory
        $deleteResponse = $deleteRequest.GetResponse() | Out-Null

        if ($deleteResponse)
        {
            Write-Host "Delete response disposed."
            $deleteResponse.Dispose()
        }
    }
}
