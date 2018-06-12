<# 
	-----------------------------------------------------------------------------
	Script Name: FogApi
	Original Author: JJ Fullmer
	Original Created Date: 2018-06-04
	Version: 1.5
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
# MIIQpgYJKoZIhvcNAQcCoIIQlzCCEJMCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUa5N4PUPsZgC5dc+22v+4g8dG
# 16mggg0NMIIFiTCCA3GgAwIBAgIQN1osf+GqS6BH6tcXABgA1DANBgkqhkiG9w0B
# AQsFADBLMRMwEQYKCZImiZPyLGQBGRYDY29tMR8wHQYKCZImiZPyLGQBGRYPYXJy
# b3doZWFkZGVudGFsMRMwEQYDVQQDEwpBcnJvd1NlY0NhMB4XDTE3MDIwNzIxNTg1
# MFoXDTIyMDIwNzIyMDg0MlowSzETMBEGCgmSJomT8ixkARkWA2NvbTEfMB0GCgmS
# JomT8ixkARkWD2Fycm93aGVhZGRlbnRhbDETMBEGA1UEAxMKQXJyb3dTZWNDYTCC
# AiIwDQYJKoZIhvcNAQEBBQADggIPADCCAgoCggIBAMhkMlfIR+4RxhLYnlPRHxIp
# NDa2/xRM1tlJM9EH+4+OuMO0EQMFZyYQOBCoJtsEgwGAPQ8sakSeYNE2Tjt4Tyou
# abr6kOHdY6OIQPEf5cIqoTi2unlQLWnC/2tx5MBXmKFZV2ZkPeZRghJwnHByZXFn
# bX31f+BRk3Bx+/PPW7h7oJTwufLo7uJAoRNJkKfTsgijyASiVqmkh5C0Vg5o5C9G
# gv9DAMarhcSa1+ShF+EtxKWM4m3/MloAhb/rNPZUCUuyjqFEDQV8PdBrQh56oBZL
# Q+If2pYoPPxxn8H+WPJfVTj9lkZG0IJe2ca6hmBa7dymYjQSUIBEQFC8tK2bE2er
# 1vj61rORZPoxargJXTaF0SV+Hq0frPBD4GkIOQWGKbuaCfIo6nVnrPZuQ7trEAvN
# 4S2mvzHvJ+nwX1CQhwcCsRW0GaLXxrfyeBsfZW67UgHcGK1tXV5h6+DR0bSPFPaa
# l3kI+8rf+9NVyDAZrCm2i0Lw4NW4cxL6JBKPQPKtFV3UouwWOac9MEoqibbpYVJ3
# rYcNyNeps1oekiVKN8jydfZ3AqKXQfLzqTJdB16YWbFYs5Yn1liiJfAWT7AaxfAE
# HJ67Oqr9IzGxGEM//IxqBJQeIf5/5CcMJH2UeksHZ3z3wR6VpkA/v/1rJEDfgKY/
# GJPDMv8GPbCDu3ElADbpAgMBAAGjaTBnMBMGCSsGAQQBgjcUAgQGHgQAQwBBMA4G
# A1UdDwEB/wQEAwIBhjAPBgNVHRMBAf8EBTADAQH/MB0GA1UdDgQWBBRRWTnftW/d
# bLIOrwmI+JciijhD5TAQBgkrBgEEAYI3FQEEAwIBADANBgkqhkiG9w0BAQsFAAOC
# AgEAw8bm2JLVfX4caZHQ52YZB5Td/6XAoznPTAmdycOTyvCmTyUjv9A8Ftc1OexN
# v2IPFRD7bL95Ms3mBfE2IBWpk/h5Mm/8ZN+6AuLXkc6200zhgbMnjvGb5s8YgSUM
# nPNHnyFBA1V+P66HBc5emJKLHY50aHyI+vk0udaMHYNrfMvlopvUzpMiumWSgp3M
# Y9GfiMmC2h3tjJ7E8JwNh+FSqUi63kZLqaK0B/mjtBG4DXaWLk5kSXxnntgX9oLs
# 3iX9U/I0rolonjt3UVOJeRPOGiRqcCH376lgkI/FRf4aFAKf3H6WHAqgbyx+vN2h
# e1uwbMQdX0gl3mok5aZoSI9znJbVIjBsZrjglvd3fXyPGbMUWCRVmOSlFwDO+zm1
# s8f5cFDtVnzMr8W+TOXd6+oxbplAMJ6XdKQPrvZTBBN55eB3WadXa/BdSXBxnBhn
# SwLq+o0H9W205eXFRZNCnH3KJlnsEIsMvLiNAw9/qVYo+2nU91x4lRrPa19DqmF2
# 5D/Eh0XkubjUa4b954jX+JpffObTyc5CvpL5gUODVlyMX0a40y74zubi7Zq9+xXj
# lOeOnOWpgDmWJD6iJbayIdyfZBlf/B9h3c9eFBWeCyFSuCpu8uBzmHUtem/JjF2t
# MTiJ4Cvmw1eNC8MqQrXDx3s1G5qpVNE3DWNzlCJs+QfHdJIwggd8MIIFZKADAgEC
# AhNdAAAATLgu1IttudRNAAAAAABMMA0GCSqGSIb3DQEBCwUAMEsxEzARBgoJkiaJ
# k/IsZAEZFgNjb20xHzAdBgoJkiaJk/IsZAEZFg9hcnJvd2hlYWRkZW50YWwxEzAR
# BgNVBAMTCkFycm93U2VjQ2EwHhcNMTgwNjAxMTY1OTA5WhcNMjAwNjAxMTcwOTA5
# WjBFMR0wGwYDVQQKExRBcnJvd2hlYWQgRGVudGFsIExhYjEkMCIGA1UEAxMbQXJy
# b3doZWFkIElUIFNjcmlwdCBNb25rZXlzMIICIjANBgkqhkiG9w0BAQEFAAOCAg8A
# MIICCgKCAgEAxwDOE86sYxKM8czHZg4dq/8Aj7U2S6WZRmOWW80ghFQms5n8GQVo
# tciKCij53oGVb6ckXLt3fWqJdyTth48oJl9Wa2+vbaq4s79W5szYS2HJdMzg9xh2
# u0F5E0XjpcHy0abU4IVTtYb/ert9GNyLJKkW8beh6+U2vlcl31A17rDVhg1Yl+tm
# xOwxwxNffWcR5HZCFUrIXDTIyMgkt4KFlP75+L9D7PXJVCk3TVmCNfWYKYsmJBtr
# XVKV6wb7Mm55uGbq6182zkrlhT0WHZmwEJejOgyz4g3rzevy37JE/sG723n4G2Jr
# 3kzLwveLbXX3NDoeMCYkYWeVGqfoC0FOP0WM7v7ogxRFlcWaV6UOFVirThTwEE0X
# se/Jw4y6vS2BgqC94rhiZk0HoGoFT8nIWVtUc5QpKC2kowkM8v13Yq8AGIWIBqBc
# nOdqlGSXoZc97lSLxmLaXYJR2a9SRjk65SJ/REO2Cdw/PNZ2zCv7YJFlp8d6c9zc
# UB2SxwQxA0jSyUST0p334m/QEXGSXFskOlbf+NM1CcUazmc6Q1jS7fqg40viw+Sf
# 5IyKkw9lsOXX7+FmcMhIWw91LFGboPEb7Iaf9vCulCCVMx9YhQOy3OKh8YJ9RcXC
# zGwchTQJ2/XQ66atF9rvrOgOtTzedHFmUlDrajyQ/fHGe+2hVGLxPLECAwEAAaOC
# Al0wggJZMDoGCSsGAQQBgjcVBwQtMCsGIysGAQQBgjcVCIebo3WFgvZBhYEMg66D
# aITGtVl41fZAiK1AAgFkAgEDMBMGA1UdJQQMMAoGCCsGAQUFBwMDMA4GA1UdDwEB
# /wQEAwIGwDAbBgkrBgEEAYI3FQoEDjAMMAoGCCsGAQUFBwMDMB0GA1UdDgQWBBRg
# qGvxaPgg3QnSqjNzfAdD3Zk5iTAfBgNVHSMEGDAWgBRRWTnftW/dbLIOrwmI+Jci
# ijhD5TCB0QYDVR0fBIHJMIHGMIHDoIHAoIG9hoG6bGRhcDovLy9DTj1BcnJvd1Nl
# Y0NhLENOPWFycm93c2VjLENOPUNEUCxDTj1QdWJsaWMlMjBLZXklMjBTZXJ2aWNl
# cyxDTj1TZXJ2aWNlcyxDTj1Db25maWd1cmF0aW9uLERDPWFycm93aGVhZGRlbnRh
# bCxEQz1jb20/Y2VydGlmaWNhdGVSZXZvY2F0aW9uTGlzdD9iYXNlP29iamVjdENs
# YXNzPWNSTERpc3RyaWJ1dGlvblBvaW50MIHEBggrBgEFBQcBAQSBtzCBtDCBsQYI
# KwYBBQUHMAKGgaRsZGFwOi8vL0NOPUFycm93U2VjQ2EsQ049QUlBLENOPVB1Ymxp
# YyUyMEtleSUyMFNlcnZpY2VzLENOPVNlcnZpY2VzLENOPUNvbmZpZ3VyYXRpb24s
# REM9YXJyb3doZWFkZGVudGFsLERDPWNvbT9jQUNlcnRpZmljYXRlP2Jhc2U/b2Jq
# ZWN0Q2xhc3M9Y2VydGlmaWNhdGlvbkF1dGhvcml0eTANBgkqhkiG9w0BAQsFAAOC
# AgEAlvrurKxXSVEi60zuh1FaHBCR+cMchAwZYm5/k4iVbGNUUeOGtBlZDLwSYuoM
# Hej3ENdqE0b3V/0BZ9KPD2WZhld7oTvRn0HjS97i35jI1XPVpBfktzbIBqZJfbQy
# 2aY/xdfcL4bVGIgVZdgZhCvFcM3H1gQLKB+3DcijggBC/S91AmRi3+cUX2M1fOUU
# 9hmlX6Ly7s8sMjAG2YndoyqPfmQScPTuiiNm3ARla3XgvgkbIClMKK8CH5NNTb24
# +nVrFDG6MLSH3QbKN8zVEzlj25Rgxwde9fx/2hAQ93P2wgRRjpM55BA/9oKN3xMn
# Qb4wO87UEjmcrAMJbnKxyRAgbpuwDW1BRuXUwmPQK4ft8aNJUe884wWq1fL1B+zR
# O8jc2xAkG7ctnCkzj3Pi0v3IZtfEzQiBNKF0cWX75cdB7siWQWaTmCkVMoRcDgCZ
# WHQ28UkDUR0hYr/jGsfgp3hVCCMtyHhl35EYeajzOe3LHfXKQxiwc42Telh6ZtUE
# DRndUfB8bpyt/9rcvU+S+YFcv/RXHtimPC1308OIYtPY+LRefNqz3gyr24uIAEcc
# xQjUHDsAttQC7O1nLws8USgVef6KT6LOEqGP5mxIXiXmH6ZRL6G/qaRIaJ5ku6e8
# BkRiqKzjzDgmGfbPDbcsQE37BS+Ms2oGIfLEUoJMuTVHLGoxggMDMIIC/wIBATBi
# MEsxEzARBgoJkiaJk/IsZAEZFgNjb20xHzAdBgoJkiaJk/IsZAEZFg9hcnJvd2hl
# YWRkZW50YWwxEzARBgNVBAMTCkFycm93U2VjQ2ECE10AAABMuC7Ui2251E0AAAAA
# AEwwCQYFKw4DAhoFAKB4MBgGCisGAQQBgjcCAQwxCjAIoAKAAKECgAAwGQYJKoZI
# hvcNAQkDMQwGCisGAQQBgjcCAQQwHAYKKwYBBAGCNwIBCzEOMAwGCisGAQQBgjcC
# ARUwIwYJKoZIhvcNAQkEMRYEFJnSg3GjJ6929x31dZCozURw4qAqMA0GCSqGSIb3
# DQEBAQUABIICALL3HJlXcPTovXitYkzyQmOVNHrpqPpFvWkbjy9oJ7/IFEh7Kn9I
# RRpC5O4IzGGPjHBsMFPp1X6CKSPGocCoNGsK7liFP+0XRC5+7auCaHpIiOpjEz4Q
# CpToYDuU4EjpYXuAGN4XJfJjiIS5KuUuJmMXZRGjIYRUBZfyqHi+XkipJBuXwWIL
# /1hvjYUVFJCsDuilJgvcIgWrI08bGhRNOshwkbDrHAcDBEzWocc25UBWMvk6ucXz
# kA7haINRZt4gxGI8YZQbg5Jd5N9hkMNSWu8c9EM458Da5NHofk41WQEf91BwkX92
# 0SMYN+TezT8VqEseoaBROwqa6VCVHW3cBCIAsHUwrS4drD+zw5iXzmI3+CqjGqKh
# mtIbfFi95xuwcyuvkBEzqF+hCecab3ukCNcbe83SodE5N2i0mlv8Gd/GYAr+GlE+
# YZITAuc7rTDI5Qg/Z0n1ew2o7PRhDa/48ftVP+gQDfyh81uah8njQqrVivbAqqx0
# s982mKosei39hXji66cFcFJEXz08ExoXjyE6M23LB5giohhUJ8RFtTfv/G5/Np66
# PJNyeItxt33hpObkzyrkhpfN3GGMKJZAfgJP2SPP12AiKcyVB22B89E+Ep+0fFxu
# nIgIstxiM2/yn02fEhmUipAra1hA4MBzRlNOPYA/Ffu1OBYAwpdYVwYQ
# SIG # End signature block
