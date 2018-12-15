#!/bin/bash

#This deletes the specified snapshot for all $storageNodes


cwd="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$cwd/settings.sh"


#Ask for the snapshot name to be passed in.
if [[ -z $1 ]]; then
    echo "$(date +%x_%r) No snapshotName passed for argument 1, exiting." >> $output
    exit
else
    snapshotName=$1
fi



#Start the commands going in unison.
for i in "${storageNodes[@]}"
do
    nonsense=$(timeout $sshTime ssh -o ConnectTimeout=$sshTimeout $hostsystem "echo wakeup")
    nonsense=$(timeout $sshTime ssh -o ConnectTimeout=$sshTimeout $hostsystem "echo get ready")
    sleep 5
    echo "$(date +%x_%r) Deleting snapshot $snapshotName from $i" >> $output
    ssh -o ConnectTimeout=$sshTimeout $hostsystem "virsh snapshot-delete $i $snapshotName > /dev/null 2>&1"


done


