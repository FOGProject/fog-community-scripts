#!/bin/bash

cwd="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$cwd/settings.sh"


if [[ -z $(command -v jq) ]]; then
    echo "This requires jq to be installed, exiting."
    exit 1
fi


#Ask for the host ID to be passed in.
if [[ -z $1 ]]; then
    echo "$(date +%x_%r) No host ID passed for argument 1, exiting." >> $output
    exit
else
    hostID=$1
fi


cmd="curl --silent -X GET -H 'content-type: application/json' -H 'fog-user-token: ${testServerUserToken}' -H 'fog-api-token: ${testServerApiToken}' http://${testServerIP}/fog/task/active -d '{\"hostID\": [${hostID}]}'"
result=$(eval $cmd)

echo $result | jq '.count'


