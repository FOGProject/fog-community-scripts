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
        $settingsFile = "$PSScriptRoot\settings.json";
        $serverSettings = (Get-Content $settingsFile | ConvertFrom-Json);
        [string]$fogApiToken = ($serverSettings.fogApiToken);
        [string]$fogUserToken = ($serverSettings.fogUserToken);
        [string]$fogServer = ($serverSettings.fogServer);
        $baseUri = "http://$fogServer/fog";
        $helpTxt = @{
            fogApiToken = "fog API token found at https://fog-server/fog/management/index.php?node=about&sub=settings under API System";
            fogUserToken = "your fog user api token found in the user settings https://fog-server/fog/management/index.php?node=user&sub=list select your api enabled used and view the api tab";
            fogServer = "your fog server hostname or ip address to be used for created the url used in api calls default is fog-server or fogServer";
        }
        Write-Verbose "making sure settings are set";
        if ( $fogApiToken -eq $helpTxt.fogApiToken -OR
             $fogUserToken -eq $helpTxt.fogUserToken -OR
             $fogServer -eq $helpTxt.fogServer
        ) {
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
            return -1;
        }
        else {
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
                Write-Host "removing body from call as it is null"
                $apiCall.Remove("Body");
            }
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
        [string]
        $type,
        # The Core object of the object type
        [Parameter(Position=1)]
        [ValidateSet(
            "clientupdater",
            "dircleaner",
            "greenfog",
            "group",
            "groupassociation",
            "history",
            "hookevent",
            "host",
            "hostautologout",
            "hostscreensetting",
            "image",
            "imageassociation",
            "imagepartitiontype",
            "imagetype",
            "imaginglog",
            "inventory",
            "ipxe",
            "keysequence",
            "macaddressassociation",
            "module",
            "moduleassociation",
            "multicastsession",
            "multicastsessionsassociation",
            "nodefailure",
            "notifyevent",
            "os",
            "oui",
            "plugin",
            "powermanagement",
            "printer",
            "printerassociation",
            "pxemenuoptions",
            "scheduledtask",
            "service",
            "snapin",
            "snapinassociation",
            "snapingroupassociation",
            "snapinjob",
            "snapintask",
            "storagegroup",
            "storagenode",
            "task",
            "tasklog",
            "taskstate",
            "tasktype",
            "usercleanup",
            "usertracking",
            "virus"
        )]
        [string]
        $CoreObject,
        # The core object active task type
        [Parameter(Position=1)]
        [ValidateSet(
            "multicastsession",
            "scheduledtask",
            "snapinjob",
            "snapintask",
            "task"
        )]
        [String]
        $CoreActiveTaskType,
        # The search term when choosing the search option
        [Parameter(Position=1)]
        [string]
        $stringToSearch,
        # The json data for the body of the request
        [Parameter(Position=2)]
        [Object]
        $jsonData,
        # The id of the object to get
        [Parameter(Position=3)]
        [string]
        $IDofObject
    )
    
    begin {
        Write-Verbose "Building uri and api call";
        switch ($type) {
            objectactivetasktype { 
                $uri = "$CoreActiveTaskType/current";
             }
            object {
                if($IDofObject -eq $null) {
                    $uri = "$CoreObject";
                }
                else {
                    $uri = "$CoreObject/$IDofObject";                    
                }
            }
            search {
                $uri = "$type/$stringToSearch";
            }
        }
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
        # The Core object of the object type
        [Parameter(Position=1)]
        [ValidateSet(
            "clientupdater",
            "dircleaner",
            "greenfog",
            "group",
            "groupassociation",
            "history",
            "hookevent",
            "host",
            "hostautologout",
            "hostscreensetting",
            "image",
            "imageassociation",
            "imagepartitiontype",
            "imagetype",
            "imaginglog",
            "inventory",
            "ipxe",
            "keysequence",
            "macaddressassociation",
            "module",
            "moduleassociation",
            "multicastsession",
            "multicastsessionsassociation",
            "nodefailure",
            "notifyevent",
            "os",
            "oui",
            "plugin",
            "powermanagement",
            "printer",
            "printerassociation",
            "pxemenuoptions",
            "scheduledtask",
            "service",
            "snapin",
            "snapinassociation",
            "snapingroupassociation",
            "snapinjob",
            "snapintask",
            "storagegroup",
            "storagenode",
            "task",
            "tasklog",
            "taskstate",
            "tasktype",
            "usercleanup",
            "usertracking",
            "virus"
        )]
        [string]
        $CoreObject,
        # The core object type to create a task for
        [Parameter(Position=1)]
        [ValidateSet(
            "group",
            "host",
            "multicastsession",
            "snapinjob",
            "snapintask",
            "task"
        )]
        [String]
        $CoreTaskType,
        # The json data for the body of the request
        [Parameter(Position=2,Mandatory=$true)]
        [Object]
        $jsonData,
        # The id of the object when creating a new task
        [Parameter(Position=3,Mandatory=$true)]
        [string]
        $IDofObject
    )
    
    begin {
        Write-Verbose "Building uri and api call";
        switch ($type) {
            objecttasktype { 
                $uri = "$CoreTaskType/$IDofObject/task";
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
        [string]
        $type,
        # The Core object of the object type
        [Parameter(Position=1)]
        [ValidateSet(
            "clientupdater",
            "dircleaner",
            "greenfog",
            "group",
            "groupassociation",
            "history",
            "hookevent",
            "host",
            "hostautologout",
            "hostscreensetting",
            "image",
            "imageassociation",
            "imagepartitiontype",
            "imagetype",
            "imaginglog",
            "inventory",
            "ipxe",
            "keysequence",
            "macaddressassociation",
            "module",
            "moduleassociation",
            "multicastsession",
            "multicastsessionsassociation",
            "nodefailure",
            "notifyevent",
            "os",
            "oui",
            "plugin",
            "powermanagement",
            "printer",
            "printerassociation",
            "pxemenuoptions",
            "scheduledtask",
            "service",
            "snapin",
            "snapinassociation",
            "snapingroupassociation",
            "snapinjob",
            "snapintask",
            "storagegroup",
            "storagenode",
            "task",
            "tasklog",
            "taskstate",
            "tasktype",
            "usercleanup",
            "usertracking",
            "virus"
        )]
        [string]
        $CoreObject,
        # The json data for the body of the request
        [Parameter(Position=2)]
        [Object]
        $jsonData,
        # The id of the object to remove
        [Parameter(Position=3)]
        [string]
        $IDofObject
    )
    
    begin {
        Write-Verbose "Building uri and api call";
        $uri = "$CoreTaskType/$IDofObject/edit";
        
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
        [string]
        $type,
        # The Core object of the object type
        [Parameter(Position=1)]
        [ValidateSet(
            "clientupdater",
            "dircleaner",
            "greenfog",
            "group",
            "groupassociation",
            "history",
            "hookevent",
            "host",
            "hostautologout",
            "hostscreensetting",
            "image",
            "imageassociation",
            "imagepartitiontype",
            "imagetype",
            "imaginglog",
            "inventory",
            "ipxe",
            "keysequence",
            "macaddressassociation",
            "module",
            "moduleassociation",
            "multicastsession",
            "multicastsessionsassociation",
            "nodefailure",
            "notifyevent",
            "os",
            "oui",
            "plugin",
            "powermanagement",
            "printer",
            "printerassociation",
            "pxemenuoptions",
            "scheduledtask",
            "service",
            "snapin",
            "snapinassociation",
            "snapingroupassociation",
            "snapinjob",
            "snapintask",
            "storagegroup",
            "storagenode",
            "task",
            "tasklog",
            "taskstate",
            "tasktype",
            "usercleanup",
            "usertracking",
            "virus"
        )]
        [string]
        $CoreObject,
        # The core object active task type
        [Parameter(Position=1)]
        [ValidateSet(
            "multicastsession",
            "scheduledtask",
            "snapinjob",
            "snapintask",
            "task"
        )]
        [String]
        $CoreActiveTaskType,
        # The core object type to create a task for
        [Parameter(Position=1)]
        [ValidateSet(
            "group",
            "host",
            "multicastsession",
            "snapinjob",
            "snapintask",
            "task"
        )]
        [String]
        $CoreTaskType,
        # The json data for the body of the request
        [Parameter(Position=2)]
        [Object]
        $jsonData,
        # The id of the object to remove
        [Parameter(Position=3)]
        [string]
        $IDofObject
    )
    
    begin {
        Write-Verbose "Building uri and api call";
        switch ($type) {
            objecttasktype { 
                $uri = "$CoreTaskType/$IDofObject/cancel";
             }
            object {
                $uri = "$CoreObject/$IDofObject/delete";
            }
            objectactivetasktype {
                $uri = "$CoreActiveTaskType/cancel"
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
        $fogServer
    )
    $serverSettings = (Get-Content $settingsFile | ConvertFrom-Json);
    if($fogServer -eq $null){
        $fogServer=$serverSettings.fogServer;
    }
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