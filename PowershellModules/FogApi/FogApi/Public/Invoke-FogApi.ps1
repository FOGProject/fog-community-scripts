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
        [string]$Method="GET",
        [string]$jsonData
    )

    begin {
        Write-Verbose "Pulling settings from settings file"
        # Set-FogServerSettings;
        $serverSettings = Get-FogServerSettings;

        [string]$fogApiToken = $serverSettings.fogApiToken;
        [string]$fogUserToken = $serverSettings.fogUserToken;
        [string]$fogServer = $serverSettings.fogServer;

        $baseUri = "http://$fogServer/fog";

        # Create headers
        Write-Verbose "Building Headers...";
        $headers = @{};
        $headers.Add('fog-api-token', $fogApiToken);
        $headers.Add('fog-user-token', $fogUserToken);

        # Set the Uri
        Write-Verbose "Building api call URI...";
        $uri = "$baseUri/$uriPath";
        $uri = $uri.Replace('//','/')
        $uri = $uri.Replace('http:/','http://')


        $apiCall = @{
            Uri = $uri;
            Method = $Method;
            Headers = $headers;
            Body = $jsonData;
            ContentType = "application/json"
        }
        if ($null -eq $apiCall.Body -OR $apiCall.Body -eq "") {
            Write-Verbose "removing body from call as it is null"
            $apiCall.Remove("Body");
        }

    }

    process {
        Write-Verbose "$Method`ing $jsonData to/from $uri";
        try {
            $result = Invoke-RestMethod @apiCall -ea Stop;
        } catch {
            $result = Invoke-WebRequest @apiCall;
        }
    }

    end {
        Write-Verbose "finished api call";
        return $result;
    }

}
