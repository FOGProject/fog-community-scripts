#!/bin/bash

#Script that reboots all $storageNodes VMs, and any stragglers that didn't want to reboot too.

cwd="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$cwd/settings.sh"

nonsense=$(timeout $sshTime ssh -o ConnectTimeout=$sshTimeout $hostsystem "echo wakeup")
nonsense=$(timeout $sshTime ssh -o ConnectTimeout=$sshTimeout $hostsystem "echo get ready")
sleep 5

#Gracefully shutdown all VMs.
for i in "${storageNodes[@]}"
do
    ssh -o ConnectTimeout=$sshTimeout $hostsystem "virsh shutdown $i > /dev/null 2>&1"
    sleep 5
done
sleep 30


#force-off any stragglers.
for i in "${storageNodes[@]}"
do
    ssh -o ConnectTimeout=$sshTimeout $hostsystem "virsh destroy $i > /dev/null 2>&1"
    sleep 5
done
sleep 5



#Start the VMs back up.
for i in "${storageNodes[@]}"
do
    ssh -o ConnectTimeout=$sshTimeout $hostsystem "virsh start $i > /dev/null 2>&1"
    sleep 5
done
howLongToWait=60
sleep $howLongToWait



#Initially set completion status to false in order to enter into the loop.
complete="false"

count=0
#Run this loop until completion isn't false. This is the outter loop.
while [[ "$complete" == "false" ]]; do

    complete="true"
    #Loop through each node to check status, this is the inner loop.
    for i in "${storageNodes[@]}"
    do

        status="offline"
        status=$(ssh -o ConnectTimeout=$sshTimeout $i "echo up" 2> /dev/null)

        if [[ "$status" != "up" ]]; then
            complete="false"
        fi
    done #Inner loop done.

    count=$(($count + 1))
    if [[ $count -gt $rebootTimeout ]]; then
        break
    fi
    sleep 1 #Update frequency.
done #Outter loop done.


