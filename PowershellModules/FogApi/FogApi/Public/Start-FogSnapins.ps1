function Start-FogSnapins {
<#
    .SYNOPSIS
    Starts all associated snapins of a host

    .DESCRIPTION
    Starts the allsnapins task on a provided hostid

    .PARAMETER hostid
    the hostid to start the task on

    .PARAMETER taskTypeid
    the id of the task to start, defaults to 12

    .EXAMPLE
    Start-FogSnapins

    will get the current hosts id and start all snapins on it
#>

    [CmdletBinding()]
    param (
        $hostid = ((Get-FogHost).id),
        $taskTypeid = 12
    )

    begin {
        Write-Verbose "Stopping any queued snapin tasks";
        try {
            $tasks = Get-FogObject -type objectactivetasktype -coreActiveTaskObject task;
        } catch {
            $tasks = Invoke-FogApi -Method GET -uriPath "task/active";
        }
        $taskID = (($tasks | Where-Object hostID -match $hostid).id);
        Write-Verbose "Found $($taskID.count) tasks deleting them now";
        $taskID | ForEach-Object{
            try {
                Remove-FogObject -type objecttasktype -coreTaskObject task -IDofObject $_;
            } catch {
                Invoke-FogApi -Method DELETE -uriPath "task/$_/cancel";
            }
        }
        # $snapAssocs = Invoke-FogApi -uriPath snapinassociation -Method Get;
        # $snaps = $snapAssocs.snapinassociations | ? hostid -eq $hostid;
    }

    process {
        Write-Verbose "starting all snapin task for host";
        $json = (@{
            "taskTypeID"=$taskTypeid;
            "deploySnapins"=-1;
        } | ConvertTo-Json);
        New-FogObject -type objecttasktype -coreTaskObject host -jsonData $json -IDofObject $hostid;
    }

    end {
        Write-Verbose "Snapin tasks have been queued on the server";
        return;
    }

}
