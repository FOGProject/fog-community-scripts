function Get-DynmicParam {
<#
.SYNOPSIS
Gets the dynamic parameter for the main functions

.DESCRIPTION
Dynamically sets the correct tab completeable validate set for the coreobject, coretaskobject, coreactivetaskobject, or string to search

.PARAMETER paramName
the name of the parameter being dynamically set within the validate set

.PARAMETER position
the position to put the dynamic parameter in

#>

    [CmdletBinding()]
    param (
        [Parameter(Position=0)]
        [ValidateSet('coreObject','coreTaskObject','coreActiveTaskObject','stringToSearch')]
        [string]$paramName,
        $position=1
    )
    begin {
        #initilzie objects
        $attributes = New-Object Parameter; #System.Management.Automation.ParameterAttribute;
        $attributeCollection = New-Object -Type System.Collections.ObjectModel.Collection[System.Attribute]
        # $paramDictionary = New-Object System.Management.Automation.RuntimeDefinedParameterDictionary
        # Set attributes
        $attributes.Position = $position;
        $attributes.Mandatory = $true;

        $attributeCollection.Add($attributes)

        $coreObjects = @(
            "clientupdater", "dircleaner", "greenfog", "group", "groupassociation",
            "history", "hookevent", "host", "hostautologout", "hostscreensetting", "image",
            "imageassociation", "imagepartitiontype", "imagetype", "imaginglog", "inventory", "ipxe",
            "keysequence", "macaddressassociation", "module", "moduleassociation", "multicastsession",
            "multicastsessionsassociation", "nodefailure", "notifyevent", "os", "oui", "plugin",
            "powermanagement", "printer", "printerassociation", "pxemenuoptions", "scheduledtask",
            "service", "snapin", "snapinassociation", "snapingroupassociation", "snapinjob",
            "snapintask", "storagegroup", "storagenode", "task", "tasklog", "taskstate", "tasktype",
            "usercleanup", "usertracking", "virus"
        );
        $coreTaskObjects = @("group", "host", "multicastsession", "snapinjob", "snapintask", "task");
        $coreActiveTaskObjects = @("multicastsession", "scheduledtask", "snapinjob", "snapintask", "task");
    }

    process {
        switch ($paramName) {
            coreObject { $attributeCollection.Add((New-Object ValidateSet($coreObjects)));}
            coreTaskObject {$attributeCollection.Add((New-Object ValidateSet($coreTaskObjects)));}
            coreActiveTaskObject {$attributeCollection.Add((New-Object ValidateSet($coreActiveTaskObjects)));}
        }
        $dynParam = New-Object System.Management.Automation.RuntimeDefinedParameter($paramName, [string], $attributeCollection);
        # $paramDictionary.Add($paramName, $dynParam);
    }
    end {
        return $dynParam;
    }

}
