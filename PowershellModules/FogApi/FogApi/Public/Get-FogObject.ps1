function Get-FogObject {
<#
    .SYNOPSIS
    Gets a fog object via the api

    .DESCRIPTION
    Gets a object, objecactivetasktype, or performs a search via the api

    .PARAMETER type
    the type of object to get

    .PARAMETER jsonData
    the json data in json string format if required

    .PARAMETER IDofObject
    the id of the object to get

#>

    [CmdletBinding()]
    param (
        # The type of object being requested
        [Parameter(Position=0)]
        [ValidateSet("objectactivetasktype","object","search")]
        [string]$type,
        # The json data for the body of the request
        [Parameter(Position=2)]
        [Object]$jsonData,
        # The id of the object to get
        [Parameter(Position=3)]
        [string]$IDofObject
    )

    DynamicParam { $paramDict = Set-DynamicParams $type; return $paramDict;}

    begin {
        $paramDict | % { New-Variable -Name $_.Keys -Value $($_.Values.Value);}
        Write-Verbose "Building uri and api call for $($paramDict.keys) $($paramDict.values.value)";
        switch ($type) {
            objectactivetasktype {
                $uri = "$coreActiveTaskObject/current";
            }
            object {
                if ($null -eq $IDofObject -OR $IDofObject -eq "") {
                    $uri = "$coreObject";
                }
                else {
                    $uri = "$coreObject/$IDofObject";
                }
            }
            search {
                $uri = "$type/$stringToSearch";
            }
        }
        Write-Verbose "uri for get is $uri";
        $apiInvoke = @{
            uriPath=$uri;
            Method="GET";
            jsonData=$jsonData;
        }
        if ($null -eq $apiInvoke.jsonData -OR $apiInvoke.jsonData -eq "") {
            $apiInvoke.Remove("jsonData");
        }
    }

    process {
        $result = Invoke-FogApi @apiInvoke;
    }

    end {
        return $result;
    }

}
