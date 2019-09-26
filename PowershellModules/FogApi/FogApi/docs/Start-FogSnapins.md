---
external help file: fogapi-help.xml
Module Name: fogapi
online version: https://forums.fogproject.org/topic/10837/usb-ethernet-adapter-mac-s-for-imaging-multiple-hosts-universal-imaging-nics-wired-nic-for-all-wireless-devices/14
schema: 2.0.0
---

# Start-FogSnapins

## SYNOPSIS
Starts all associated snapins of a host

## SYNTAX

```
Start-FogSnapins [[-hostid] <Object>] [[-taskTypeid] <Object>] [<CommonParameters>]
```

## DESCRIPTION
Starts the allsnapins task on a provided hostid

## EXAMPLES

### EXAMPLE 1
```
Start-FogSnapins
```

will get the current hosts id and start all snapins on it

## PARAMETERS

### -hostid
the hostid to start the task on

```yaml
Type: Object
Parameter Sets: (All)
Aliases:

Required: False
Position: 1
Default value: ((Get-FogHost).id)
Accept pipeline input: False
Accept wildcard characters: False
```

### -taskTypeid
the id of the task to start, defaults to 12

```yaml
Type: Object
Parameter Sets: (All)
Aliases:

Required: False
Position: 2
Default value: 12
Accept pipeline input: False
Accept wildcard characters: False
```

### CommonParameters
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

## OUTPUTS

## NOTES

## RELATED LINKS
