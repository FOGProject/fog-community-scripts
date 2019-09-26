---
external help file: fogapi-help.xml
Module Name: fogapi
online version:
schema: 2.0.0
---

# Install-FogService

## SYNOPSIS
Attempts to install the fog service

## SYNTAX

```
Install-FogService [[-fogServer] <Object>] [<CommonParameters>]
```

## DESCRIPTION
Attempts to download and install silently and then not so silently the fog service

## EXAMPLES

### Example 1
```powershell
PS C:\> {{ Add example code here }}
```

{{ Add example description here }}

## PARAMETERS

### -fogServer
the server to download from and connect to

```yaml
Type: Object
Parameter Sets: (All)
Aliases:

Required: False
Position: 1
Default value: ((Get-FogServerSettings).fogServer)
Accept pipeline input: False
Accept wildcard characters: False
```

### CommonParameters
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

## OUTPUTS

## NOTES

## RELATED LINKS
