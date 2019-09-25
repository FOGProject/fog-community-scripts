function New-FogObject {
<#
.SYNOPSIS
Create a new fog object with the api

.DESCRIPTION
creates a new object such as a host or task

.PARAMETER type
the type of api object

.PARAMETER jsonData
json data in json string for api call

.PARAMETER IDofObject
the id of the object

#>

    [CmdletBinding()]
    param (
        # The type of object being requested
        [Parameter(Position=0)]
        [ValidateSet("objecttasktype","object")]
        [string]
        $type,
        # The json data for the body of the request
        [Parameter(Position=2)]
        [Object]$jsonData,
        # The id of the object when creating a new task
        [Parameter(Position=3)]
        [string]$IDofObject
    )

    DynamicParam { $paramDict = Set-DynamicParams $type; return $paramDict;}

    begin {
        $paramDict | % { New-Variable -Name $_.Keys -Value $($_.Values.Value);}
        Write-Verbose "Building uri and api call";
        switch ($type) {
            objecttasktype {
                $uri = "$CoreTaskObject/$IDofObject/task";
             }
            object {
                $uri = "$CoreObject/create";
            }
        }
        $apiInvoke = @{
            uriPath=$uri;
            Method="POST";
            jsonData=$jsonData;
        }
    }

    process {
        $result = Invoke-FogApi @apiInvoke;
    }

    end {
        return $result;
    }

}
