function Remove-FogObject {
<#
.SYNOPSIS
Removes/Deletes a object via fog api

.DESCRIPTION
Calls a delete function via the api

.PARAMETER type
the type of api object

.PARAMETER jsonData
json data in json string

.PARAMETER IDofObject
the id of the object

#>

    [CmdletBinding()]
    param (
        # The type of object being requested
        [Parameter(Position=0)]
        [ValidateSet("objecttasktype","objectactivetasktype","object")]
        [string]$type,
        # The json data for the body of the request
        [Parameter(Position=2)]
        [Object]$jsonData,
        # The id of the object to remove
        [Parameter(Position=3)]
        [string]$IDofObject
    )

    DynamicParam { $paramDict = Set-DynamicParams $type; return $paramDict;}

    begin {
        $paramDict | ForEach-Object { New-Variable -Name $_.Keys -Value $($_.Values.Value);}
        Write-Verbose "Building uri and api call";
        switch ($type) {
            objecttasktype {
                $uri = "$CoreTaskObject/$IDofObject/cancel";
             }
            object {
                $uri = "$CoreObject/$IDofObject/delete";
            }
            objectactivetasktype {
                $uri = "$CoreActiveTaskObject/cancel"
            }
        }
        $apiInvoke = @{
            uriPath=$uri;
            Method="DELETE";
            jsonData=$jsonData;
        }
        if ($apiInvoke.jsonData -eq $null -OR $apiInvoke.jsonData -eq "") {
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
