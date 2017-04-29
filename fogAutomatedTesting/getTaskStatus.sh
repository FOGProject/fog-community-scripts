#!/bin/bash

cwd="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$cwd/settings.sh"



#Ask for the host ID to be passed in.
if [[ -z $1 ]]; then
    echo "$(date +%x_%r) No host ID passed for argument 1, exiting." >> $output
    exit
else
    hostID=$1
fi




cmd="curl -k --header 'content-type: application/json' --header 'fog-user-token: ${testServerUserToken}' --header 'fog-api-token: $testServerApiToken' http://${testServerIP}/fog/task/active --get --data '{\"hosts\": [${hostID}]}'"
eval $cmd

echo
echo
echo
echo "$cmd"
echo
echo
