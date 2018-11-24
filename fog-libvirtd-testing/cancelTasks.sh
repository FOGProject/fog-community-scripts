#!/bin/bash

# This script optionally accepts the hostID you want to cancel tasks on.
# Requires that jq is installed.
# If no host ID is supplied as an argument, all host's tasks are canceled.
# Example usages:

# Cancel all tasks:
# ./cancelTasks.sh
# Cancel all tasks for host 5:
# ./cancelTasks.sh 5




cwd="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$cwd/settings.sh"


if [[ -z $(command -v jq) ]]; then
    echo "This requires jq to be installed, exiting."
    exit 1
fi

#Get the host ID if present. If present, just delete host's tasks. Else, delete all tasks.
if [[ -z $1 ]]; then
    echo "$(date +%x_%r) Canceling all tasks on \"$testServerIP\"" >> $output
    cmd="timeout $sshTimeout curl --silent -X DELETE -H 'content-type: application/json' -H 'fog-user-token: ${testServerUserToken}' -H 'fog-api-token: ${testServerApiToken}' http://${testServerIP}/fog/task/cancel -d '{\"typeID\": [1,2] }'"
else
    hostID=$1
    echo "$(date +%x_%r) Canceling tasks for host \"$hostID\"" >> $output
    cmd="timeout $sshTimeout curl --silent -X GET -H 'content-type: application/json' -H 'fog-user-token: ${testServerUserToken}' -H 'fog-api-token: ${testServerApiToken}' http://${testServerIP}/fog/task/cancel -d '{\"hostID\": [${hostID}]}'"
fi

#Run the command.
result=$(eval $cmd)


