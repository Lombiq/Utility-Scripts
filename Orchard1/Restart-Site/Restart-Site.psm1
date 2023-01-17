<#
.Synopsis
    Restarts an Orchard 1.x app in IIS.

.DESCRIPTION
    For an Orchard 1.x app. Deletes the bin, obj App_Data folders and restarts the site in IIS.

.EXAMPLE
    Restart-Site -Path C:\pathToOrchardSource -SiteName siteNameInIIS

#>
function Restart-Site
{
    [CmdletBinding()]
    Param
    (
        # The path to a folder or a Visual Studio project file to check. The default path is the current execution path.
        [string]
        $Path,

        # The name of the IIS site.
        [string]
        $SiteName
    )

    Process
    {
        # If the path is invalid, then return an error.
        if (!(Test-Path ($Path)))
        {
            Write-Error ('File or folder not found!')
            return
        }

        # Stopping IIS site and app pool.
        Stop-IISSite $SiteName -Confirm:$false
        Stop-WebAppPool $SiteName

        # Deleting bin and obj folders.
        # Add relative file paths here what you want to keep.
        $whiteList = @('\src\Orchard.Azure\Orchard.Azure.CloudService\Orchard.Azure.WebContent\Bin\Startup\SetIdleTimeout.cmd')
        # Also add the bin/obj folder's path of the paths in the whiteList here. This is needed for performance reasons,
        # the script will run faster this way.
        $whiteListFolders = @('\src\Orchard.Azure\Orchard.Azure.CloudService\Orchard.Azure.WebContent\Bin')

        Get-ChildItem -Path ($Path + '\src\') -Recurse |
            Where-Object { $PSItem.PSIsContainer -and ( $PSItem.Name -eq 'bin' -or $PSItem.Name -eq 'obj') } |
            ForEach-Object {
                if ($whiteListFolders.Contains($PSItem.FullName.Substring($Path.Length)))
                {
                    Get-ChildItem -Path $PSItem.FullName -Recurse -File |
                        ForEach-Object {
                            if (!$whiteList.Contains($PSItem.FullName.Substring($Path.Length)))
                            {
                                Remove-Item $PSItem.FullName -Force
                            }
                        }
                    }
                    else
                    {
                        Remove-Item $PSItem.FullName -Recurse -Force
                    }
                }

        # Deleting App_Data
        $appDataPath = $Path + '\src\Orchard.Web\App_Data\'
        if (Test-Path ($appDataPath))
        {
            Remove-Item -Path ($appDataPath) -Recurse -Force
        }

        # Starting IIS site and app pool.
        Start-IISSite $SiteName
        Start-WebAppPool $SiteName

        return
    }
}