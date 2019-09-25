function Get-FogHosts {
<#
    .SYNOPSIS
    Gets all fog hosts
    
    .DESCRIPTION
    helper function for get-fogobject that gets all host objects
    
    .EXAMPLE
    Get-FogHosts
    
#>
    
    [CmdletBinding()]
    param (

    )
    
    begin {
        Write-Verbose "getting fog hosts"
    }
    
    process {
        $hosts = Get-FogObject -type Object -CoreObject host | Select-Object -ExpandProperty hosts
    }
    
    end {
        return $hosts;
    }

}
