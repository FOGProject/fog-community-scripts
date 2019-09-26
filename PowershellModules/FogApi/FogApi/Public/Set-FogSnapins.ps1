function Set-FogSnapins {
<#
.SYNOPSIS
Sets a list of snapins to a host, appends to existing ones

.DESCRIPTION
Goes through a provided list variable and adds each matching snapin to the provided
hostid

.EXAMPLE
Set-FogSnapins -hostid (Get-FogHost).id -pkgList @('Office365','chrome','slack')

This would associate snapins that match the titles of office365, chrome, and slack to the provided host id
they could then be deployed with start-fogsnapins

.NOTES
General notes
#>

    [CmdletBinding()]
    [Alias('Add-FogSnapins')]
    param (
        $hostid = ((Get-FogHost).id),
        $pkgList,
        $dept
    )

    process {
        Write-Verbose "Association snapins from package list with host";
        $snapins = Get-FogSnapins;
        $urlPath = "snapinassociation/create"
        $curSnapins = Get-FogAssociatedSnapins -hostId $hostid;
        $result = New-Object System.Collections.Generic.List[Object];
        $pkgList | ForEach-Object {
            $json = @{
                hostID = $hostid
                snapinID = (($snapins | Where-Object name -match "$($_)").id);
            };
            Write-Verbose "$_ is pkg snapin id found is $($json.snapinID)";
            if (($null -ne $json.SnapinID) -AND ($json.SnapinID -notin $curSnapins.id)) {
                $json = $json | ConvertTo-Json;
                $result.add((New-FogObject -type object -coreObject snapinassociation -jsonData $json));
            } elseif ($json.SnapinID -in $curSnapins.id) {
                Write-Warning "$_ snapin of id $($json.SnapinID) is already associated with this host";
            } else {
                Write-Warning "no snapin ID found for $_ pkg";
            }
            # Invoke-FogApi -Method POST -uriPath $urlPath -jsonData $json;
        }
        return $result;
    }


}
