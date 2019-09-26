---
external help file: fogapi-help.xml
Module Name: fogapi
online version:
schema: 2.0.0
---

# Get-FogHost

## SYNOPSIS
Gets the object of a specific fog host

## SYNTAX

```
Get-FogHost [[-uuid] <String>] [[-hostName] <String>] [[-macAddr] <String>] [[-hosts] <Object>]
 [<CommonParameters>]
```

## DESCRIPTION
Searches a new or existing object of hosts for a specific host (or hosts) with search options of uuid, hostname, or mac address
if no search terms are specified then it gets the search terms from your host that is making the request and tries to find your
computer in fog

## EXAMPLES

### EXAMPLE 1
```
Get-FogHost -hostName MewoMachine
```

This would return the fog details of a host named MeowMachine in your fog instance

### EXAMPLE 2
```
Get-FogHost
```

If you specify no param it will return your current host from fog

## PARAMETERS

### -uuid
the uuid of the host

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

### -hostName
the hostname of the host

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

### -macAddr
a mac address linked to the host

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

### -hosts
defaults to calling Get-FogHosts but if you already have that in an object you can pass it here to speed up processing

```yaml
Type: Object
Parameter Sets: (All)
Aliases:

Required: False
Position: 4
Default value: (Get-FogHosts)
Accept pipeline input: False
Accept wildcard characters: False
```

### CommonParameters
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

## OUTPUTS

## NOTES

## RELATED LINKS

[Get-FogHosts]()

[Get-FogObject]()

