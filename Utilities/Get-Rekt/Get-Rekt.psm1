<#
.Synopsis
    Throws an exception.

.DESCRIPTION
    Wrecks the script execution by throwing a fatal exception.

.EXAMPLE
    Get-Rekt
#>


function Get-Rekt
{
    [CmdletBinding()]
    [Alias('grek')]
    param()

    process
    {
        throw [System.OutOfMemoryException] 'Get Rekt!'
    }
}