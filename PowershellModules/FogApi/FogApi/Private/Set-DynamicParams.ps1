function Set-DynamicParams {
<#
.SYNOPSIS
Sets the dynamic param dictionary

.DESCRIPTION
Sets dynamic parameters inside functions

.PARAMETER type
the type of parameter

#>

    [CmdletBinding()]
    param ($type)
    $paramDictionary = New-Object System.Management.Automation.RuntimeDefinedParameterDictionary;

    # Sub function for setting
    function Set-Param($paramName) {
        $param = Get-DynmicParam -paramName $paramName;
        $paramDictionary.Add($paramName, $param);
    }
    switch ($type) {
        object { Set-Param('coreObject');}
        objectactivetasktype { Set-Param('coreActiveTaskObject');}
        objecttasktype {Set-Param('coreTaskObject');}
        search {Set-Param('stringToSearch');}
    }
    return $paramDictionary;

}
