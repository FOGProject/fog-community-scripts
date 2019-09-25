---
external help file: fogapi-help.xml
Module Name: fogapi
online version:
schema: 2.0.0
---

# Get-FogGroup

## SYNOPSIS
needs to return the group name of the group that isn't the everyone group
will use groupassociation call to get group id then group id to get group name from group uriPath

## SYNTAX

```
Get-FogGroup [[-hostId] <Int32>] [<CommonParameters>]
```

## DESCRIPTION
requires the id of the host you want the groups that aren't the everyone group for

## EXAMPLES

### Example 1
```powershell
PS C:\> {{ Add example code here }}
```

{{ Add example description here }}

## PARAMETERS

### -hostId
{{ Fill hostId Description }}

```yaml
Type: Int32
Parameter Sets: (All)
Aliases:

Required: False
Position: 1
Default value: 0
Accept pipeline input: False
Accept wildcard characters: False
```

### CommonParameters
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

## OUTPUTS

## NOTES

## RELATED LINKS
