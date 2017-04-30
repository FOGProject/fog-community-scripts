#!/bin/bash

cwd="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$cwd/settings.sh"


if [[ -z $(command -v jq) ]]; then
    echo "This requires jq to be installed, exiting."
    exit 1
fi

#Get the host ID if present. Having just a blank variable within brackets breaks it.
if [[ -z $1 ]]; then
    cmd="curl --silent -X GET -H 'content-type: application/json' -H 'fog-user-token: ${testServerUserToken}' -H 'fog-api-token: ${testServerApiToken}' http://${testServerIP}/fog/task/active -d '{\"hostID\": }'"
else
    hostID=$1
    cmd="curl --silent -X GET -H 'content-type: application/json' -H 'fog-user-token: ${testServerUserToken}' -H 'fog-api-token: ${testServerApiToken}' http://${testServerIP}/fog/task/active -d '{\"hostID\": [${hostID}]}'"
fi

#Run the command.
result=$(eval $cmd)

echo $result | jq '.count'


