#!/bin/bash

cwd="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$cwd/settings.sh"


if [[ -z $(command -v jq) ]]; then
    echo "This requires jq to be installed, exiting."
    exit 1
fi


#Get the host ID if present.
if [[ -z $1 ]]; then
    hostID=""
else
    hostID=$1
fi


cmd="curl --silent -X GET -H 'content-type: application/json' -H 'fog-user-token: ${testServerUserToken}' -H 'fog-api-token: ${testServerApiToken}' http://${testServerIP}/fog/task/active -d '{\"hostID\": [${hostID}]}'"
result=$(eval $cmd)
echo
echo
echo "$cmd"
echo
echo

echo $result | jq '.count'


