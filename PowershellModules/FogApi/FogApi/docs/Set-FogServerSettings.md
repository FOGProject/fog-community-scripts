---
external help file: fogapi-help.xml
Module Name: fogapi
online version: https://forums.fogproject.org/topic/10837/usb-ethernet-adapter-mac-s-for-imaging-multiple-hosts-universal-imaging-nics-wired-nic-for-all-wireless-devices/14
schema: 2.0.0
---

# Set-FogServerSettings

## SYNOPSIS
Set fog server settings

## SYNTAX

```
Set-FogServerSettings [[-fogApiToken] <String>] [[-fogUserToken] <String>] [[-fogServer] <String>]
 [-interactive] [<CommonParameters>]
```

## DESCRIPTION
Set the apitokens and server settings for api calls with this module
the settings are stored in a json file in the current users roaming appdata ($ENV:APPDATA\FogApi)
this is to keep it locked down and inaccessible to standard users
and keeps the settings from being overwritten when updating the module

## EXAMPLES

### Example 1
```powershell
PS C:\> {{ Add example code here }}
```

{{ Add example description here }}

## PARAMETERS

### -fogApiToken
fog API token found at https://fog-server/fog/management/index.php?node=about&sub=settings under API System

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

### -fogUserToken
your fog user api token found in the user settings https://fog-server/fog/management/index.php?node=user&sub=list select your api enabled used and view the api tab

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: 2
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -fogServer
your fog server hostname or ip address to be used for created the url used in api calls default is fog-server or fogServer

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

### -interactive
switch to make setting these an interactive process

```yaml
Type: SwitchParameter
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: False
Accept pipeline input: False
Accept wildcard characters: False
```

### CommonParameters
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

## OUTPUTS

## NOTES

## RELATED LINKS
