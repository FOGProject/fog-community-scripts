#!/bin/bash

# This script returns the number of tasks for a single host ID, or for all hosts.
# Argument 1 is optional, the host ID.
# If the host ID is provided, the number of tasks for that host is returned.
# If the host ID is not provided, the total number of tasks is returned.

# No tasks in queue returns '0'
# Requires that jq is installed.


cwd="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$cwd/settings.sh"


if [[ -z $(command -v jq) ]]; then
    echo "This requires jq to be installed, exiting."
    exit 1
fi

#Get the host ID if present. Having just a blank variable within brackets breaks it.
if [[ -z $1 ]]; then
    cmd="timeout $sshTimeout curl --silent -X GET -H 'content-type: application/json' -H 'fog-user-token: ${testServerUserToken}' -H 'fog-api-token: ${testServerApiToken}' http://${testServerIP}/fog/task/active -d '{\"hostID\": }'"
else
    hostID=$1
    cmd="timeout $sshTimeout curl --silent -X GET -H 'content-type: application/json' -H 'fog-user-token: ${testServerUserToken}' -H 'fog-api-token: ${testServerApiToken}' http://${testServerIP}/fog/task/active -d '{\"hostID\": [${hostID}]}'"
fi

#Run the command.
result=$(eval $cmd)

echo $result | jq '.count'


