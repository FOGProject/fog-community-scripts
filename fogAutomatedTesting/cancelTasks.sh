#!/bin/bash

cwd="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$cwd/settings.sh"


if [[ -z $(command -v jq) ]]; then
    echo "This requires jq to be installed, exiting."
    exit 1
fi

#Get the host ID if present. If present, just delete host's tasks. Else, delete all tasks.
if [[ -z $1 ]]; then
    cmd="timeout $sshTimeout curl --silent -X DELETE -H 'content-type: application/json' -H 'fog-user-token: ${testServerUserToken}' -H 'fog-api-token: ${testServerApiToken}' http://${testServerIP}/fog/task/cancel -d '{\"typeID\": [1,2] }'"
else
    hostID=$1
    cmd="timeout $sshTimeout curl --silent -X GET -H 'content-type: application/json' -H 'fog-user-token: ${testServerUserToken}' -H 'fog-api-token: ${testServerApiToken}' http://${testServerIP}/fog/task/cancel -d '{\"hostID\": [${hostID}]}'"
fi

#Run the command.
result=$(eval $cmd)


