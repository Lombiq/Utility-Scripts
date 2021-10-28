<#
.Synopsis
    Copies all files from the specified folder to Azure Development Storage.

.DESCRIPTION
    Copies all files from the specified folder to Development Storage when running the Azure Storage Emulator.

.EXAMPLE
    Copy-ToAzureDevelopmentStorage -Path "D:\StorageBackup"
#>

Import-Module Az.Storage

function Copy-ToAzureDevelopmentStorage
{
    [CmdletBinding()]
    [Alias()]
    [OutputType([int])]
    Param
    (
        [Parameter(Mandatory = $true, HelpMessage = "The path to the folder to copy the content from to the Development Storage. The first level of subfolders will be handled as Storage Containers.")]
        [string] $Path
    )

    Process
    {
        if (!(Test-Path $Path))
        {
            throw ("The path specified is not valid!")
        }

        Start-AzureStorageEmulator | Out-Null

        $storageContext = New-AzStorageContext -Local

        $containers = Get-AzStorageContainer -Context $storageContext
        $pathLength = $Path.Length

        foreach ($folder in Get-ChildItem $Path | Where-Object { $PSItem.PSIsContainer })
        {
            if ($null -eq $containers -or $containers.Count -eq 0 -or !($containers | Select-Object -ExpandProperty "Name").Contains($folder.Name))
            {
                New-AzStorageContainer -Context $storageContext -Name $folder.Name -Permission Blob
            }

            foreach ($subFolder in Get-ChildItem $folder.FullName)
            {
                Get-AzStorageContainer -Context $storageContext -Name $folder.Name | Get-AzStorageBlob | Where-Object { $PSItem.Name.StartsWith($folder.Name + "\") } | Remove-AzStorageBlob
            }            

            foreach ($file in Get-ChildItem $folder.FullName -Recurse -File)
            {
                Set-AzStorageBlobContent -Context $storageContext -Container $folder.Name -File $file.FullName -Blob $file.FullName.Substring($folder.FullName.Length + 1) -Force | Out-Null
                Write-Host ("Importing `"$($file.FullName.Substring($pathLength))`".")
            }
        }
    }
}