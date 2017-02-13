#!/bin/bash
cwd="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$cwd/settings.sh"


#Start the commands going in unison.
for i in "${storageNodes[@]}"
do
    ssh -o ConnectTimeout=$sshTimeout $hostsystem "virsh shutdown $i > /dev/null 2>&1"
done
howLongToWait=20
sleep $howLongToWait



#Initially set completion status to false in order to enter into the loop.
complete="false"

#Run this loop until completion isn't false. This is the outter loop.
while [[ "$complete" == "false" ]]; do

    complete="true"
    #Loop through each node to check status, this is the inner loop.
    for i in "${storageNodes[@]}"
    do

        status="offline"
        status=$(ssh -o ConnectTimeout=$sshTimeout $i "echo up" 2> /dev/null)

        if [[ ! "$status" == "up" ]]; then
            complete="false"
        fi
    done #Inner loop done.

    sleep 1 #Update frequency.
done #Outter loop done.

