<# 
	-----------------------------------------------------------------------------
	Script Name: FogApi
	Original Author: JJ Fullmer
	Original Created Date: 2018-06-04
	Version: 1.6
	----------------------------------------------------------------------------- 
#>

function Get-DynmicParam {
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

 
function Set-DynamicParams {
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

function Get-FogServerSettings {
    [CmdletBinding()]
    param ()
    
    begin {
        Write-Verbose "Pulling settings from settings file"
        $settingsFile = "$PSScriptRoot\settings.json";
    }
    
    process {
        $serverSettings = (Get-Content $settingsFile | ConvertFrom-Json);
    }
    
    end {
        return $serverSettings;
    }
}

function Set-FogServerSettings {
    [CmdletBinding()]
    param (
        [string]$fogApiToken, 
        [string]$fogUserToken, 
        [string]$fogServer,
        [switch]$interactive = $false
    )
    begin {
        $settingsFile = "$PSScriptRoot\settings.json";        
        $serverSettings = Get-FogServerSettings;
        Write-Verbose "Current/old Settings are $($serverSettings)";
        $helpTxt = @{
            fogApiToken = "fog API token found at https://fog-server/fog/management/index.php?node=about&sub=settings under API System";
            fogUserToken = "your fog user api token found in the user settings https://fog-server/fog/management/index.php?node=user&sub=list select your api enabled used and view the api tab";
            fogServer = "your fog server hostname or ip address to be used for created the url used in api calls default is fog-server or fogServer";
        }
    }
    
    process {
        # If given paras are null just pulls from settings file
        # If they are not null sets the object to passed value
        $serverSettings.psobject.properties | % {
            $var = (Get-Variable -Name $_.Name);
            if ($var.Value -eq $null -OR $var.Value -eq "") {
                if($interactive) {
                    Set-Variable -name $var.Name -Value (Read-Host -Prompt "Enter the $($var.name), help message: $($helpTxt.($_.name)) ");
                }
                else {
                    Write-Verbose "Not interactive and no $($var.Name) specificed, pulling from settings file";
                    Set-Variable -name $var.Name -Value ($serverSettings.$($_.Name));
                }
            }
            Set-Variable -name $serverSettings.$($_.Name) -Value $var.Value;
        }

        Write-Verbose "making sure all settings are set";
        if ( $fogApiToken -eq $helpTxt.fogApiToken -OR 
            $fogUserToken -eq $helpTxt.fogUserToken -OR $fogServer -eq $helpTxt.fogServer) {
            Write-Host -BackgroundColor Yellow -ForegroundColor Red -Object "a fog setting is still set to its default help text, opening the settings file for you to set the settings"
            Write-Host -BackgroundColor Yellow -ForegroundColor Red -Object "This script will close after opening settings in notepad, please re-run command after updating settings file";            
            if ($isLinux) {
                $editor = 'nano';
            }
            elseif($IsMacOS) {
                $editor = 'TextEdit';
            }
            else {
                $editor = 'notepad.exe';
            }
            Start-Process -FilePath $editor -ArgumentList "$SettingsFile" -NoNewWindow -PassThru;
            return;
        }
    }
    
    end {
        Write-Verbose "Writing new Settings";
        $serverSettings | ConvertTo-Json | Out-File -FilePath $settingsFile -Encoding oem -Force;
        return;
    }
}

function Invoke-FogApi {
    <#
        .SYNOPSIS
           a cmdlet function for making fogAPI calls via powershell
        
        .DESCRIPTION
            Takes a few parameters with some pulled from settings.json and others are put in from the wrapper cmdlets
            Makes a call to the api of a fog server and returns the results of the call
            The returned value is an object that can then be easily filtered, processed,
             and otherwise manipulated in poweshell.
            The defaults for each setting explain how to find or a description of the property needed.
            fogApiToken = "fog API token found at https://fog-server/fog/management/index.php?node=about&sub=settings under API System";
            fogUserToken = "your fog user api token found in the user settings https://fog-server/fog/management/index.php?node=user&sub=list select your api enabled used and view the api tab";
            fogServer = "your fog server hostname or ip address to be used for created the url used in api calls default is fog-server or fogServer";
                    
        .PARAMETER serverSettings
            this variable pulls the values from settings.json and assigns the values to 
            the associated params. The defaults explain how to get the needed settings
            fogApiToken = "fog API token found at https://fog-server/fog/management/index.php?node=about&sub=settings under API System";
            fogUserToken = "your fog user api token found in the user settings https://fog-server/fog/management/index.php?node=user&sub=list select your api enabled used and view the api tab";
            fogServer = "your fog server hostname or ip address to be used for created the url used in api calls default is fog-server or fogServer";

        .PARAMETER fogApiToken
            a string of your fogApiToken gotten from the fog web ui. 
            this value is pulled from the settings.json file
        
        .PARAMETER fogUserToken
           a string of your fog user token gotten from the fog web ui in the user section.
           this value is pulled from the settings.json file
        
        .PARAMETER fogServer
            The hostname or ip address of your fogserver, 
            defaults to the default name fog-server
            this value is pulled from the settings.json file
        
        .PARAMETER uriPath
            Put in the path of the apicall that would follow http://fog-server/fog/
            i.e. 'host/1234' would access the host with an id of 1234
            This is filled by the wrapper commands using parameter validation to 
            help ensure using the proper object names for the url 
            
        .PARAMETER Method
          Defaults to 'Get' can also be Post, put, or delete, this param is handled better
          by the wrapper functions
          get is Get-fogObject
          post is New-fogObject
          delete is Remove-fogObject
          put is Update-fogObject
        
        .PARAMETER jsonData
            The jsondata string for including data in the body of a request
        
        .EXAMPLE
            #if you had the api tokens set as default values and wanted to get all hosts and info you could run this, assuming your fogserver is accessible on http://fog-server
            Invoke-FogApi;

        .Example
            #if your fogserver was named rawr and you wanted to put rename host 123 to meow
            Invoke-FogApi -fogServer "rawr" -uriPath "host/123" -Method "Put" -jsonData "{ `"name`": meow }";

        .Link
            https://news.fogproject.org/simplified-api-documentation/
        
        .NOTES
            The online version of this help takes you to the fog project api help page
            
    #>

    [CmdletBinding()]
    param (
        [string]$uriPath,
        [string]$Method,
        [string]$jsonData
    )
        
    begin {
        Write-Verbose "Pulling settings from settings file"
        Set-FogServerSettings;
        $serverSettings = Get-FogServerSettings;
        
        [string]$fogApiToken = ($serverSettings.fogApiToken);
        [string]$fogUserToken = ($serverSettings.fogUserToken);
        [string]$fogServer = ($serverSettings.fogServer);
        
        $baseUri = "http://$fogServer/fog";
        
        # Create headers
        Write-Verbose "Building Headers...";
        $headers = @{};
        $headers.Add('fog-api-token', $fogApiToken);
        $headers.Add('fog-user-token', $fogUserToken);

        # Set the Uri
        Write-Verbose "Building api call URI...";
        $uri = "$baseUri/$uriPath";

        $apiCall = @{
            Uri = $uri;
            Method = $Method;
            Headers = $headers;
            Body = $jsonData;
            ContentType = "application/json"
        }
        if ($apiCall.Body -eq $null -OR $apiCall.Body -eq "") {
            Write-Verbose "removing body from call as it is null"
            $apiCall.Remove("Body");
        }
    
    }
    
    process {
        Write-Verbose "$Method`ing $jsonData to/from $uri";
        $result = Invoke-RestMethod @apiCall;
    }
    
    end {
        Write-Verbose "finished api call";
        return $result;
    }
}

function Get-FogObject {
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
                if($IDofObject -eq $null -OR $IDofObject -eq "") {
                    $uri = "$coreObject";
                }
                else {
                    $uri = "$coreObject)/$IDofObject";
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

function New-FogObject {
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

function Update-FogObject {
    [CmdletBinding()]
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
        [string]$IDofObject
    )
    
    DynamicParam { $paramDict = Set-DynamicParams $type; return $paramDict;}

    begin {
        $paramDict | % { New-Variable -Name $_.Keys -Value $($_.Values.Value);}
        Write-Verbose "Building uri and api call";
        $uri = "$CoreTaskObject/$IDofObject/edit";
        
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

function Remove-FogObject {
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
        $paramDict | % { New-Variable -Name $_.Keys -Value $($_.Values.Value);}
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

function Install-FogService {
    param (
        $fogServer = ((Get-FogServerSettings).fogServer)
    )
    $fileUrl = "https://$fogServer/fog/client/download.php?newclient";
    Write-Host "Making temp download dir";
    mkdir C:\fogtemp;
    Write-Host "downloading installer";
    Invoke-WebRequest $fileUrl -OutFile 'C:\fogtemp\fog.msi';
    Write-Host "installing fog service";    
    Start-Process -FilePath msiexec -ArgumentList @('/i','C:\fogtemp\fog,msi','/quiet','/qn','/norestart') -NoNewWindow -Wait;
    Write-Host "removing download file and temp folder";    
    Remove-Item -Force -Recurse C:\fogtemp;
    Write-Host "Starting fogservice";    
    Start-Service FOGService;
    return;
}

Export-ModuleMember -Function *;


# SIG # Begin signature block
# MIILGQYJKoZIhvcNAQcCoIILCjCCCwYCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQU6+vgiwgsT6u46XyKI1jAcaA8
# NpWgggeAMIIHfDCCBWSgAwIBAgITXQAAAEy4LtSLbbnUTQAAAAAATDANBgkqhkiG
# 9w0BAQsFADBLMRMwEQYKCZImiZPyLGQBGRYDY29tMR8wHQYKCZImiZPyLGQBGRYP
# YXJyb3doZWFkZGVudGFsMRMwEQYDVQQDEwpBcnJvd1NlY0NhMB4XDTE4MDYwMTE2
# NTkwOVoXDTIwMDYwMTE3MDkwOVowRTEdMBsGA1UEChMUQXJyb3doZWFkIERlbnRh
# bCBMYWIxJDAiBgNVBAMTG0Fycm93aGVhZCBJVCBTY3JpcHQgTW9ua2V5czCCAiIw
# DQYJKoZIhvcNAQEBBQADggIPADCCAgoCggIBAMcAzhPOrGMSjPHMx2YOHav/AI+1
# NkulmUZjllvNIIRUJrOZ/BkFaLXIigoo+d6BlW+nJFy7d31qiXck7YePKCZfVmtv
# r22quLO/VubM2EthyXTM4PcYdrtBeRNF46XB8tGm1OCFU7WG/3q7fRjciySpFvG3
# oevlNr5XJd9QNe6w1YYNWJfrZsTsMcMTX31nEeR2QhVKyFw0yMjIJLeChZT++fi/
# Q+z1yVQpN01ZgjX1mCmLJiQba11SlesG+zJuebhm6utfNs5K5YU9Fh2ZsBCXozoM
# s+IN683r8t+yRP7Bu9t5+Btia95My8L3i2119zQ6HjAmJGFnlRqn6AtBTj9FjO7+
# 6IMURZXFmlelDhVYq04U8BBNF7HvycOMur0tgYKgveK4YmZNB6BqBU/JyFlbVHOU
# KSgtpKMJDPL9d2KvABiFiAagXJznapRkl6GXPe5Ui8Zi2l2CUdmvUkY5OuUif0RD
# tgncPzzWdswr+2CRZafHenPc3FAdkscEMQNI0slEk9Kd9+Jv0BFxklxbJDpW3/jT
# NQnFGs5nOkNY0u36oONL4sPkn+SMipMPZbDl1+/hZnDISFsPdSxRm6DxG+yGn/bw
# rpQglTMfWIUDstziofGCfUXFwsxsHIU0Cdv10OumrRfa76zoDrU83nRxZlJQ62o8
# kP3xxnvtoVRi8TyxAgMBAAGjggJdMIICWTA6BgkrBgEEAYI3FQcELTArBiMrBgEE
# AYI3FQiHm6N1hYL2QYWBDIOug2iExrVZeNX2QIitQAIBZAIBAzATBgNVHSUEDDAK
# BggrBgEFBQcDAzAOBgNVHQ8BAf8EBAMCBsAwGwYJKwYBBAGCNxUKBA4wDDAKBggr
# BgEFBQcDAzAdBgNVHQ4EFgQUYKhr8Wj4IN0J0qozc3wHQ92ZOYkwHwYDVR0jBBgw
# FoAUUVk537Vv3WyyDq8JiPiXIoo4Q+UwgdEGA1UdHwSByTCBxjCBw6CBwKCBvYaB
# umxkYXA6Ly8vQ049QXJyb3dTZWNDYSxDTj1hcnJvd3NlYyxDTj1DRFAsQ049UHVi
# bGljJTIwS2V5JTIwU2VydmljZXMsQ049U2VydmljZXMsQ049Q29uZmlndXJhdGlv
# bixEQz1hcnJvd2hlYWRkZW50YWwsREM9Y29tP2NlcnRpZmljYXRlUmV2b2NhdGlv
# bkxpc3Q/YmFzZT9vYmplY3RDbGFzcz1jUkxEaXN0cmlidXRpb25Qb2ludDCBxAYI
# KwYBBQUHAQEEgbcwgbQwgbEGCCsGAQUFBzAChoGkbGRhcDovLy9DTj1BcnJvd1Nl
# Y0NhLENOPUFJQSxDTj1QdWJsaWMlMjBLZXklMjBTZXJ2aWNlcyxDTj1TZXJ2aWNl
# cyxDTj1Db25maWd1cmF0aW9uLERDPWFycm93aGVhZGRlbnRhbCxEQz1jb20/Y0FD
# ZXJ0aWZpY2F0ZT9iYXNlP29iamVjdENsYXNzPWNlcnRpZmljYXRpb25BdXRob3Jp
# dHkwDQYJKoZIhvcNAQELBQADggIBAJb67qysV0lRIutM7odRWhwQkfnDHIQMGWJu
# f5OIlWxjVFHjhrQZWQy8EmLqDB3o9xDXahNG91f9AWfSjw9lmYZXe6E70Z9B40ve
# 4t+YyNVz1aQX5Lc2yAamSX20MtmmP8XX3C+G1RiIFWXYGYQrxXDNx9YECygftw3I
# o4IAQv0vdQJkYt/nFF9jNXzlFPYZpV+i8u7PLDIwBtmJ3aMqj35kEnD07oojZtwE
# ZWt14L4JGyApTCivAh+TTU29uPp1axQxujC0h90GyjfM1RM5Y9uUYMcHXvX8f9oQ
# EPdz9sIEUY6TOeQQP/aCjd8TJ0G+MDvO1BI5nKwDCW5ysckQIG6bsA1tQUbl1MJj
# 0CuH7fGjSVHvPOMFqtXy9Qfs0TvI3NsQJBu3LZwpM49z4tL9yGbXxM0IgTShdHFl
# ++XHQe7IlkFmk5gpFTKEXA4AmVh0NvFJA1EdIWK/4xrH4Kd4VQgjLch4Zd+RGHmo
# 8zntyx31ykMYsHONk3pYembVBA0Z3VHwfG6crf/a3L1PkvmBXL/0Vx7Ypjwtd9PD
# iGLT2Pi0Xnzas94Mq9uLiABHHMUI1Bw7ALbUAuztZy8LPFEoFXn+ik+izhKhj+Zs
# SF4l5h+mUS+hv6mkSGieZLunvAZEYqis48w4Jhn2zw23LEBN+wUvjLNqBiHyxFKC
# TLk1RyxqMYIDAzCCAv8CAQEwYjBLMRMwEQYKCZImiZPyLGQBGRYDY29tMR8wHQYK
# CZImiZPyLGQBGRYPYXJyb3doZWFkZGVudGFsMRMwEQYDVQQDEwpBcnJvd1NlY0Nh
# AhNdAAAATLgu1IttudRNAAAAAABMMAkGBSsOAwIaBQCgeDAYBgorBgEEAYI3AgEM
# MQowCKACgAChAoAAMBkGCSqGSIb3DQEJAzEMBgorBgEEAYI3AgEEMBwGCisGAQQB
# gjcCAQsxDjAMBgorBgEEAYI3AgEVMCMGCSqGSIb3DQEJBDEWBBTBv7+o8hCxtoee
# FZS2616ckK6cVjANBgkqhkiG9w0BAQEFAASCAgAGuqYyQYObGu2zzktyoq3Hmq++
# okPGzqcvQR16zZy8QhuLt4rBlHEf5rYNvjMuJfGP3C4LafVQzfKS/pFmGBykue5V
# V+FmiHT682jIjTbhJdtwxy8h6PFIUNyTXmR1KhcpEwDxzIto7u71iFVMelnGb5zO
# ZVbll02t4c0p2QB+89NEzls/n4iWX/pMq2QTyUiPO7tfWlYnXd6OXDoJoxxROqq6
# mtPVeldeB5d8vbyrSUb53IO5CNe4IMPnnUSIDMIT8heZF2xoEx9074jOiczUunYU
# BDSr8l5AcGKoANi0UduQ3z60+nRSr8GFfj8es2IaxtTJjmDJhHs74mRHIsZ+d5nn
# W1Y7s0ijhZtq/vhgZf5Y5ZROatNmbfRQsBiVd9Zc7KME+jG0Gp9xxDXs+FoH95l3
# OQLcg187wglKA7ASRZC0nCrQ1bg93gdlV+ttzD3TC2dPDf3tPFMwh6OlTa7qLnP4
# hq3C4VobHTWZ7DfOV34owsyngRKtGCYUZvpX26fbppl0BFY3SJSGlkCTheTVvkRW
# awX84AEZr9YFRvNMeDL1rgU692Sv1C1PLBgkgvdl2qigKKqPnhretjOJlnSj2YDa
# H3axI3XI7wbdohxqmoKnYv/jUaWLHdi4TTHdybYezXoPjyqjwbnpoBGwfe7hXHA+
# +jRfrpfHhbEmnBCOng==
# SIG # End signature block
