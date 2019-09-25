function Set-FogServerSettings {
<#
.SYNOPSIS
Set fog server settings

.DESCRIPTION
Set the apitokens and server settings for api calls with this module
the settings are stored in a json file in the current users roaming appdata ($ENV:APPDATA\FogApi)
this is to keep it locked down and inaccessible to standard users
and keeps the settings from being overwritten when updating the module

.PARAMETER fogApiToken
fog API token found at https://fog-server/fog/management/index.php?node=about&sub=settings under API System

.PARAMETER fogUserToken
your fog user api token found in the user settings https://fog-server/fog/management/index.php?node=user&sub=list select your api enabled used and view the api tab

.PARAMETER fogServer
your fog server hostname or ip address to be used for created the url used in api calls default is fog-server or fogServer

.PARAMETER interactive
switch to make setting these an interactive process

#>

    [CmdletBinding()]
    param (
        [string]$fogApiToken,
        [string]$fogUserToken,
        [string]$fogServer,
        [switch]$interactive
    )
    begin {
        
        $settingsFile = "$ENV:APPDATA\FogApi\api-settings.json"
        if (!(Test-path $settingsFile)) {
            if (!(Test-Path "$ENV:APPDATA\FogApi")) {
                mkdir "$ENV:APPDATA\FogApi";
            }
            Copy-Item "$tools\settings.json" $settingsFile -Force
        }
        $ServerSettings = Get-FogServerSettings;
        Write-Verbose "Current/old Settings are $($ServerSettings)";
        $helpTxt = @{
            fogApiToken = "fog API token found at https://fog-server/fog/management/index.php?node=about&sub=settings under API System";
            fogUserToken = "your fog user api token found in the user settings https://fog-server/fog/management/index.php?node=user&sub=list select your api enabled used and view the api tab";
            fogServer = "your fog server hostname or ip address to be used for created the url used in api calls default is fog-server or fogServer";
        }
        
    }
    
    process {
        if($null -ne $fogApiToken -and $null -ne $fogUserToken -AND $null -ne $fogServer) {
            $serverSettings = @{
                fogApiToken = $fogApiToken;
                fogUserToken = $fogUserToken;
                fogServer = $fogServer;
            }
        }
        # If given paras are null just pulls from settings file
        # If they are not null sets the object to passed value
        if($interactive) {
            $serverSettings.psobject.properties | ForEach-Object {
                $var = (Get-Variable -Name $_.Name);
                if ($null -eq $var.Value -OR $var.Value -eq "") {
                        Set-Variable -name $var.Name -Value (Read-Host -Prompt "Enter the $($var.name), help message: $($helpTxt.($_.name)) ");        
                }
            }
        }
        

        Write-Verbose "making sure all settings are set";
        if ( $ServerSettings.fogApiToken -eq $helpTxt.fogApiToken -OR
            $ServerSettings.fogUserToken -eq $helpTxt.fogUserToken -OR $ServerSettings.fogServer -eq $helpTxt.fogServer) {
            Write-Host -BackgroundColor Yellow -ForegroundColor Red -Object "a fog setting is still set to its default help text, opening the settings file for you to set the settings"
            Write-Host -BackgroundColor Yellow -ForegroundColor Red -Object "This script will close after opening settings in notepad, please re-run command after updating settings file";
            if ($isLinux) {
                $editor = 'nano';
            }
            elseif($IsMacOS) {
                $editor = 'TextEdit';
            }
            else {
                $editor = 'notepad.exe';
            }
            Start-Process -FilePath $editor -ArgumentList "$SettingsFile" -NoNewWindow -PassThru;
            return;
        }
    }

    end {
        Write-Verbose "Writing new Settings";
        $serverSettings | ConvertTo-Json | Out-File -FilePath $settingsFile -Encoding oem -Force;
        return (Get-Content $settingsFile | ConvertFrom-Json);
    }

}
