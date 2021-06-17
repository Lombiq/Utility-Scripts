<#
.Synopsis
   Uploads FTP folder.
.DESCRIPTION
   Recursively uploads a folder to an FTP server.
.EXAMPLE
   New-FtpDirectory "ftp://server.address/folder" "user" "secure password" "C:\Path\To\Folder"
#>

function New-FtpDirectory
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
                   HelpMessage = "Specify path to local folder to upload.")]
        [string] $LocalFolderPath
    )
    
    Process
    {
        $ftpFolderPath = $Url + "/App_Data_new"
        $credentials = New-Object System.Net.NetworkCredential($User, $Password)

        $srcEntries = Get-ChildItem $LocalFolderPath -Recurse
        $srcFolders = $srcEntries | Where-Object { $_.PSIsContainer }
        $srcFiles = $srcEntries | Where-Object { !$_.PSIsContainer }
    
        # Create App_Data_new folder.
        try
        {
            $makeDirectory = [System.Net.WebRequest]::Create($ftpFolderPath)
            $makeDirectory.Credentials =  $credentials
            $makeDirectory.Method = [System.Net.WebRequestMethods+FTP]::MakeDirectory
            $makeDirectory.GetResponse()
    
            Write-Host "App_Data_new folder created successfully:" $ftpFolderPath
        }
        catch [Net.WebException]
        {
            try
            {
                $checkDirectory = [System.Net.WebRequest]::Create($ftpFolderPath)
                $checkDirectory.Credentials = $credentials
                $checkDirectory.Method = [System.Net.WebRequestMethods+FTP]::PrintWorkingDirectory
                $checkDirectory.GetResponse()
    
                Write-Host "App_Data_new folder already exists:" $ftpFolderPath
            }
            catch [Net.WebException]
            {
                throw "Other error encountered during App_Data_new folder creation."
            }    
        }
    
        # Create subdirectories.
        foreach ($folder in $srcFolders)
        {
            $srcFolderPath = $LocalFolderPath -replace "\\", "\\" -replace "\:", "\:"
            $destinationFolder = $folder.Fullname -replace $srcFolderPath, $ftpFolderPath
            $destinationFolder = $destinationFolder -replace "\\", "/"
         
            try
            {
                $makeDirectory = [System.Net.WebRequest]::Create($destinationFolder)
                $makeDirectory.Credentials = $credentials
                $makeDirectory.Method = [System.Net.WebRequestMethods+FTP]::MakeDirectory
                $makeDirectory.GetResponse()
    
                Write-Host "Folder created successfully."
                Write-Host "Destination folder:" $destinationFolder
            }
            catch [Net.WebException]
            {
                try
                {
                    $checkDirectory = [System.Net.WebRequest]::Create($destinationFolder)
                    $checkDirectory.Credentials = $credentials
                    $checkDirectory.Method = [System.Net.WebRequestMethods+FTP]::PrintWorkingDirectory
                    $checkDirectory.GetResponse()
                    
                    Write-Host "Folder already exists."
                    Write-Host "Destination folder:" $destinationFolder
                }
                catch [Net.WebException]
                {
                    throw "Other error encountered during subfolders creation."
                }
            }
        }
         
        # Upload files.
        Write-Host "Beginning FILE UPLOAD phase."
    
        $webclient = New-Object System.Net.WebClient
        $webclient.Credentials = $credentials
    
        foreach ($file in $srcFiles)
        {
            $srcFullPath = $file.fullname
            $srcFilePath = $LocalFolderPath -replace "\\", "\\" -replace "\:", "\:"
            $destinationFile = $srcFullPath -replace $srcFilePath, $ftpFolderPath
            $destinationFile = $destinationFile -replace "\\", "/"
         
            $uri = New-Object System.Uri($destinationFile) 
           
            Write-Host "Uploading file:" $srcFullPath
            Write-Host "File uri:" $uri
            $errorCount = 0
    
            do
            {
                try
                {
                    $webclient.UploadFile($uri, $srcFullPath)
                    Write-Host "Upload successful."
    
                    break
                }
                catch
                {
                    Write-Host "Error caught, trying initializing new webclient object."
                    $errorCount++
                    Write-Host "ERROR COUNT:" $errorCount
    
                    $webclient.Dispose()
                    Start-Sleep -s 5
    
                    $webclient = New-Object System.Net.WebClient 
                    $webclient.Credentials = $credentials 
                }
            } while ($errorCount -ne 10)
    
            if ($errorCount -eq 10) 
            {
                throw "Maximum error count exceeded."
            }
        }
    
        $webclient.Dispose()
    }
}
