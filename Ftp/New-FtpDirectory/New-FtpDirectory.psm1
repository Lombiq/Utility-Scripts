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
        $credentials = New-Object System.Net.NetworkCredential($User, $Password)

        $srcEntries = Get-ChildItem $LocalFolderPath -Recurse
        $srcFolders = $srcEntries | Where-Object { $_.PSIsContainer }
        $srcFiles = $srcEntries | Where-Object { !$_.PSIsContainer }
    
        # Create folder.
        try
        {
            $makeDirectory = [System.Net.WebRequest]::Create($Url)
            $makeDirectory.Credentials =  $credentials
            $makeDirectory.Method = [System.Net.WebRequestMethods+FTP]::MakeDirectory
            $makeDirectory.EnableSsl = "true"
            $makeDirectory.GetResponse()
    
            Write-Host "Folder created successfully:" $Url
        }
        catch [Net.WebException]
        {
            try
            {
                $checkDirectory = [System.Net.WebRequest]::Create($Url)
                $checkDirectory.Credentials = $credentials
                $checkDirectory.Method = [System.Net.WebRequestMethods+FTP]::PrintWorkingDirectory
                $checkDirectory.EnableSsl = "true"
                $checkDirectory.GetResponse()
    
                Write-Host "Folder already exists:" $Url
            }
            catch [Net.WebException]
            {
                throw "Other error encountered during folder creation."
            }    
        }
    
        # Create subdirectories.
        foreach ($folder in $srcFolders)
        {
            $srcFolderPath = $LocalFolderPath -replace "\\", "\\" -replace "\:", "\:"
            $destinationFolder = $folder.Fullname -replace $srcFolderPath, $Url
            $destinationFolder = $destinationFolder -replace "\\", "/"
         
            try
            {
                $makeDirectory = [System.Net.WebRequest]::Create($destinationFolder)
                $makeDirectory.Credentials = $credentials
                $makeDirectory.Method = [System.Net.WebRequestMethods+FTP]::MakeDirectory
                $makeDirectory.EnableSsl = "true"
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
                    $checkDirectory.EnableSsl = "true"
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
        $webclient = New-Object System.Net.WebClient
        $webclient.Credentials = $credentials
        
        try
        {
            foreach ($file in $srcFiles)
            {
                $srcFullPath = $file.fullname
                $srcFilePath = $LocalFolderPath -replace "\\", "\\" -replace "\:", "\:"
                $destinationFile = $srcFullPath -replace $srcFilePath, $Url
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
                        try
                        {
                            Write-Host "Error caught, trying initializing new webclient object."
                            $errorCount++
                            Write-Host "ERROR COUNT:" $errorCount
                        }
                        finally
                        {
                            $webclient.Dispose()
                            Start-Sleep -s 5
                            
                            $webclient = New-Object System.Net.WebClient 
                            $webclient.Credentials = $credentials 
                        }                        
                    }
                } while ($errorCount -ne 10)
                
                if ($errorCount -eq 10) 
                {
                    throw "Maximum error count exceeded."
                }
            }
        }
        finally
        {
            $webclient.Dispose()
        }
    }
}
