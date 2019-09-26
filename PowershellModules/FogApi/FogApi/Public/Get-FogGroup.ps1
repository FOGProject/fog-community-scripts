function Get-FogGroup {
<#
    .SYNOPSIS
    needs to return the group name of the group that isn't the everyone group
    will use groupassociation call to get group id then group id to get group name from group uriPath

    .DESCRIPTION
    requires the id of the host you want the groups that aren't the everyone group for
#>
    [CmdletBinding()]
    param (
        [int]$hostId
    )

    begin {
        [bool]$found = $false;
        Write-Verbose 'Getting all fog group associations...';
        $groupAssocs = (Invoke-FogApi -uriPath groupassociation).groupassociations;
        Write-Verbose 'Getting all fog groups...';
        $groups = (Invoke-FogApi -uriPath group).groups;
    }

    process {
        Write-Verbose "Finding group association for hostid of $hostId";
        $hostGroups = $groupAssocs | Where-Object hostID -eq $hostId;
        Write-Verbose "filtering out everyone and touchscreen group";
        $hostGroups = $hostGroups | Where-Object groupID -ne 3; #groupID 3 is the everyone group, don't include that
        $hostGroups = $hostGroups | Where-Object groupID -ne 11; #groupID 11 is the wkstouchscreens group, don't include that either

        Write-Verbose "finding group that matches group id of $hostGroups...";
        $group = $groups | Where-Object id -eq $hostGroups.groupID;
        Write-Verbose 'checking if group was found...';
        if($null -ne $group -AND $group -ne "") { $found = $true; Write-Verbose 'group found!'}
    }

    end {
        if($found){
            return $group;
        }
        return $found;
    }

}
