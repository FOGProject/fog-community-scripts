#!/bin/bash

##Get current working directory
cwd="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

##Source functions file.
. $cwd/functions.sh

# Variable definitions
## FOG Settings
[[ -z $fogsettings ]] && fogsettings="/opt/fog/.fogsettings"
## Storage Node Name
[[ -z $storageNode ]] && storageNode="DefaultMember"
## Database Name
[[ -z $database ]] && database="fog"
## default.ipxe location
[[ -z $tftpfile ]] && tftpfile="/tftpboot/default.ipxe"
## Get current directory
[[ -z $DIR ]] && DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

##Clear screen.
clear


# Check fogsettings existence
checkFilePresence "$fogsettings"
checkFilePresence "$tftpfile"

## Source fogsettings file.
. $fogsettings


# Check our required checks first
checkFogSettingVars "$interface" "interface" "$fogsettings"
checkFogSettingVars "$ipaddress" "ipaddress" "$fogsettings"

##Get new interface/ip info.
identifyInterfaces #Will exit on failure. Provides $newIP and $newInterface


## Do changes:
updateIPinDB
updateTFTP

## Check docroot and webroot is set
checkFogSettingVars "$docroot" "docroot" "$fogsettings"
checkFogSettingVars "$webroot" "docroot" "$fogsettings"

##Update config.class.php
updateConfigClassPHP


##Have to update/restart ISC-DHCP here if it's supposed to be built/enabled in .fogsettings.
## Update ISC-DHCP
configureDHCP




##Only give message about DHCP/ProxyDHCP if "use dhcp" in fogsettings was disabled.
printf "\n"
printf "All done."
if [[ "$dodhcp" == "N" || "$dodhcp" == "0" ]]; then
    printf " Don't forget to update your DHCP/ProxyDHCP to use: $newIP\n"
else
    printf "\n"
fi
printf "\n"



