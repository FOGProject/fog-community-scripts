---
external help file: fogapi-help.xml
Module Name: fogapi
online version: https://news.fogproject.org/simplified-api-documentation/
schema: 2.0.0
---

# Invoke-FogApi

## SYNOPSIS
a cmdlet function for making fogAPI calls via powershell

## SYNTAX

```
Invoke-FogApi [[-uriPath] <String>] [[-Method] <String>] [[-jsonData] <String>] [<CommonParameters>]
```

## DESCRIPTION
Takes a few parameters with some pulled from settings.json and others are put in from the wrapper cmdlets
Makes a call to the api of a fog server and returns the results of the call
The returned value is an object that can then be easily filtered, processed,
 and otherwise manipulated in poweshell.
The defaults for each setting explain how to find or a description of the property needed.
fogApiToken = "fog API token found at https://fog-server/fog/management/index.php?node=about&sub=settings under API System";
fogUserToken = "your fog user api token found in the user settings https://fog-server/fog/management/index.php?node=user&sub=list select your api enabled used and view the api tab";
fogServer = "your fog server hostname or ip address to be used for created the url used in api calls default is fog-server or fogServer";

## EXAMPLES

### EXAMPLE 1
```
#if you had the api tokens set as default values and wanted to get all hosts and info you could run this, assuming your fogserver is accessible on http://fog-server
```

Invoke-FogApi;

### EXAMPLE 2
```
#if your fogserver was named rawr and you wanted to put rename host 123 to meow
```

Invoke-FogApi -fogServer "rawr" -uriPath "host/123" -Method "Put" -jsonData "{ \`"name\`": meow }";

## PARAMETERS

### -uriPath
Put in the path of the apicall that would follow http://fog-server/fog/
i.e.
'host/1234' would access the host with an id of 1234
This is filled by the wrapper commands using parameter validation to
help ensure using the proper object names for the url

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: 1
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Method
Defaults to 'Get' can also be Post, put, or delete, this param is handled better
by the wrapper functions
get is Get-fogObject
post is New-fogObject
delete is Remove-fogObject
put is Update-fogObject

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: 2
Default value: GET
Accept pipeline input: False
Accept wildcard characters: False
```

### -jsonData
The jsondata string for including data in the body of a request

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: 3
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### CommonParameters
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

## OUTPUTS

## NOTES
The online version of this help takes you to the fog project api help page

## RELATED LINKS

[https://news.fogproject.org/simplified-api-documentation/](https://news.fogproject.org/simplified-api-documentation/)

