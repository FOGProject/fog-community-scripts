function Get-FogServerSettings {
<#
.SYNOPSIS
Gets the server settings set for this module

.DESCRIPTION
Gets the current settings for use in api calls

#>

    [CmdletBinding()]
    param ()

    begin {
        Write-Verbose "Pulling settings from settings file"
        $settingsFile = "$ENV:APPDATA\FogApi\api-settings.json"
        if (!(Test-path $settingsFile)) {
            if (!(Test-Path "$ENV:APPDATA\FogApi")) {
                mkdir "$ENV:APPDATA\FogApi";
            }
            Copy-Item "$tools\settings.json" $settingsFile -Force
        }       
    }

    process {
        $serverSettings = (Get-Content $settingsFile | ConvertFrom-Json);
    }

    end {
        return $serverSettings;
    }

}
