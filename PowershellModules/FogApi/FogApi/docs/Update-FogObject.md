---
external help file: fogapi-help.xml
Module Name: fogapi
online version: https://forums.fogproject.org/topic/10837/usb-ethernet-adapter-mac-s-for-imaging-multiple-hosts-universal-imaging-nics-wired-nic-for-all-wireless-devices/14
schema: 2.0.0
---

# Update-FogObject

## SYNOPSIS
Update/patch/edit api calls

## SYNTAX

```
Update-FogObject [[-type] <String>] [[-jsonData] <Object>] [[-IDofObject] <String>] [[-uri] <String>]
 [<CommonParameters>]
```

## DESCRIPTION
Runs update calls to the api

## EXAMPLES

### Example 1
```powershell
PS C:\> {{ Add example code here }}
```

{{ Add example description here }}

## PARAMETERS

### -type
the type of fog object

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

### -jsonData
the json data string

```yaml
Type: Object
Parameter Sets: (All)
Aliases:

Required: False
Position: 3
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -IDofObject
The ID of the object

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: 4
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -uri
The explicit uri to use

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: 5
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### CommonParameters
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

## OUTPUTS

## NOTES
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

## RELATED LINKS
