<#
.Synopsis
   Reks the script execution.

.DESCRIPTION
   Reks the script execution by throwing a fatal exception.

.EXAMPLE
   Get-Rekt
#>


function Get-Rekt
{
    [CmdletBinding()]
    [Alias("grek")]
    Param()
    
    Process
    {
        throw [System.OutOfMemoryException] "Get Rekt!"
    }
}