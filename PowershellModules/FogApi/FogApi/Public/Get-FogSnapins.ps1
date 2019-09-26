function Get-FogSnapins {
<#
    .SYNOPSIS
    Returns list of all snapins on fogserver
    
    .DESCRIPTION
    Gives a full list of all snapins on the fog server
#>
    
    [CmdletBinding()]
    param ()
    
    
    process {
        return (Invoke-FogApi -Method GET -uriPath snapin).snapins;
    }
    
    
}