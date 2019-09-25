---
external help file: fogapi-help.xml
Module Name: fogapi
online version: https://forums.fogproject.org/topic/10837/usb-ethernet-adapter-mac-s-for-imaging-multiple-hosts-universal-imaging-nics-wired-nic-for-all-wireless-devices/14
schema: 2.0.0
---

# Set-FogSnapins

## SYNOPSIS
Sets a list of snapins to a host, appends to existing ones

## SYNTAX

```
Set-FogSnapins [[-hostid] <Object>] [[-pkgList] <Object>] [[-dept] <Object>] [<CommonParameters>]
```

## DESCRIPTION
Goes through a provided list variable and adds each matching snapin to the provided
hostid

## EXAMPLES

### EXAMPLE 1
```
Set-FogSnapins -hostid (Get-FogHost).id -pkgList @('Office365','chrome','slack')
```

This would associate snapins that match the titles of office365, chrome, and slack to the provided host id
they could then be deployed with start-fogsnapins

## PARAMETERS

### -hostid
{{ Fill hostid Description }}

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

### -pkgList
{{ Fill pkgList Description }}

```yaml
Type: Object
Parameter Sets: (All)
Aliases:

Required: False
Position: 2
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -dept
{{ Fill dept Description }}

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

### CommonParameters
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

## OUTPUTS

## NOTES
General notes

## RELATED LINKS
