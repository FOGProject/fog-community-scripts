function Update-FogObject {
<#
.SYNOPSIS
Update/patch/edit api calls

.DESCRIPTION
Runs update calls to the api

.PARAMETER type
the type of fog object

.PARAMETER jsonData
the json data string

.PARAMETER IDofObject
The ID of the object

.PARAMETER uri
The explicit uri to use

.NOTES
 just saw this and just today was finding some issue with Update-fogobject
The issue appears to be with the dynamic parameter variable I have in the function for the coreobjecttype.
For some reason it is working when you call the function and brings up all the coreobject type choices but then the variable is being set to null when the function is running.
Meaning that when function builds the uri it only gets
http://fogserver/fog//id/edit
instead of
http://fogserver/fog/coreObjectType/id/edit

So one workaround I will try to publish by the end of the day is adding an optional uri parameter to that function so that you can manually override it when neccesarry.
Also I should really add more documentation to each of the functions instead of just having it all under Invoke-fogapi

I also will add a try/catch block to invoke-fogapi for when invoke-restmethod fails and have it try invoke-webrequest. 
#>
    [CmdletBinding()]
    [Alias('Set-FogObject')]
    param (
        # The type of object being requested
        [Parameter(Position=0)]
        [ValidateSet("object")]
        [string]$type,
        # The json data for the body of the request
        [Parameter(Position=2)]
        [Object]$jsonData,
        # The id of the object to remove
        [Parameter(Position=3)]
        [string]$IDofObject,
        [Parameter(Position=4)]
        [string]$uri
    )

    DynamicParam { $paramDict = Set-DynamicParams $type; return $paramDict; }

    begin {
        $paramDict | ForEach-Object { New-Variable -Name $_.Keys -Value $($_.Values.Value);}
        Write-Verbose "Building uri and api call";
        if([string]::IsNullOrEmpty($uri)) {
            $uri = "$CoreObject/$IDofObject/edit";
        }

        $apiInvoke = @{
            uriPath=$uri;
            Method="PUT";
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
