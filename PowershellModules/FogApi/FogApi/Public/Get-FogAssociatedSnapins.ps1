function Get-FogAssociatedSnapins {
<#
    .SYNOPSIS
    Returns list of all snapins associated with a hostid
    
    .DESCRIPTION
    Gives a full list of all snapins associated with a given host
#>
    
    [CmdletBinding()]
    param (
        $hostId=((Get-FogHost).id)
    )
    
    process {
        $AllAssocs = (Invoke-FogApi -Method GET -uriPath snapinassociation).snapinassociations;
        $snapins = New-Object System.Collections.Generic.List[object];
        # $allSnapins = Get-FogSnapins;
        $AllAssocs | Where-Object hostID -eq $hostID | ForEach-Object {
            $snapinID = $_.snapinID;
            $snapins.add((Invoke-FogApi -uriPath "snapin\$snapinID"))
        }
        return $snapins;
    }
    
}