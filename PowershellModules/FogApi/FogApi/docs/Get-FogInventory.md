---
external help file: fogapi-help.xml
Module Name: fogapi
online version:
schema: 2.0.0
---

# Get-FogInventory

## SYNOPSIS
Gets a local computer's inventory with wmi and returns 
a json object that can be used to set fog inventory

## SYNTAX

```
Get-FogInventory [[-hostObj] <Object>] [<CommonParameters>]
```

## DESCRIPTION
Uses various wmi classes to get every possible inventory item to set in fog

## EXAMPLES

### Example 1
```powershell
PS C:\> {{ Add example code here }}
```

{{ Add example description here }}

## PARAMETERS

### -hostObj
the host to get the model of the inventory object from

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

### CommonParameters
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

## OUTPUTS

## NOTES

## RELATED LINKS
