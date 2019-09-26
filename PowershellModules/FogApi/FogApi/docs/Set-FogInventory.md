---
external help file: fogapi-help.xml
Module Name: fogapi
online version: https://forums.fogproject.org/topic/10837/usb-ethernet-adapter-mac-s-for-imaging-multiple-hosts-universal-imaging-nics-wired-nic-for-all-wireless-devices/14
schema: 2.0.0
---

# Set-FogInventory

## SYNOPSIS
Sets a fog hosts inventory

## SYNTAX

```
Set-FogInventory [[-hostObj] <Object>] [[-jsonData] <Object>] [<CommonParameters>]
```

## DESCRIPTION
Sets the inventory of a fog host object to json data gotten from get-foginventory

## EXAMPLES

### Example 1
```powershell
PS C:\> {{ Add example code here }}
```

{{ Add example description here }}

## PARAMETERS

### -hostObj
the host object to set on

```yaml
Type: Object
Parameter Sets: (All)
Aliases:

Required: False
Position: 1
Default value: (Get-FogHost)
Accept pipeline input: False
Accept wildcard characters: False
```

### -jsonData
the jsondata with the inventory

```yaml
Type: Object
Parameter Sets: (All)
Aliases:

Required: False
Position: 2
Default value: (Get-FogInventory -hostObj $hostObj)
Accept pipeline input: False
Accept wildcard characters: False
```

### CommonParameters
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

## OUTPUTS

## NOTES

## RELATED LINKS
