<#
.Synopsis
   Starts the Microsoft Azure Storage Emulator.

.DESCRIPTION
   Starts the Microsoft Azure Storage Emulator.

.EXAMPLE
   Start-AzureStorageEmulator
#>


function Start-AzureStorageEmulator
{
    [CmdletBinding()]
    [Alias("saase")]
    [OutputType([bool])]
    Param ()

    Process
    {
        $path = "C:\Program Files (x86)\Microsoft SDKs\Azure\Storage Emulator\AzureStorageEmulator.exe"

        if (Get-Process | Where-Object { $PSItem.Path -eq $path })
        {
            Write-Warning ("The Azure Storage Emulator is already running.")
        }
        elseif (!(Test-Path $path))
        {
            throw ("The Azure Storage Emulator can not be found at `"$path`"!")
        }
        else
        {
            & $path start
        }

        return $true
    }
}