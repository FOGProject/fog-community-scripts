#!/bin/bash

cwd="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$cwd/settings.sh"


#Get the image ID.
if [[ -z $1 ]]; then
    echo "$(date +%x_%r) No image ID passed for argument 1, exiting." >> $output 
    exit 1
else
    imageID=$1
fi


#Get the host IDs.
if [[ -z $2 ]]; then
    echo "$(date +%x_%r) No host IDs passed for argument 2, exiting." >> $output
    exit 1
else
    hostIDs=$2
fi


echo "$(date +%x_%r) Setting FOG hosts \"$hostIDs\" image IDs to $imageID" >> $output

#Set all the fog hosts to the same image.
curl -k --header "content-type: application/json" --header "fog-user-token: $testServerUserToken" --header "fog-api-token: $testServerApiToken" http://${testServerIP}/fog/image/${imageID}/edit -X PUT -d '{"hosts": [${hostIDs}]}'



