#!/bin/bash

# Script that restores a previous snapshot by name to all $storageNodes.
# Requires argument: Snapshot name.

cwd="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$cwd/settings.sh"


#Ask for the snapshot name to be passed in.
if [[ -z $1 ]]; then
    echo "$(date +%x_%r) No snapshotName passed for argument 1, exiting." >> $output
    exit
else
    snapshotName=$1
fi




for i in "${storageNodes[@]}"
do
    nonsense=$(timeout $sshTime ssh -o ConnectTimeout=$sshTimeout $hostsystem "echo wakeup")
    nonsense=$(timeout $sshTime ssh -o ConnectTimeout=$sshTimeout $hostsystem "echo get ready")
    sleep 5
    echo "$(date +%x_%r) Restoring snapshot $snapshotName to $i" >> $output
    ssh -o ConnectTimeout=$sshTimeout $hostsystem "virsh snapshot-revert $i $snapshotName > /dev/null 2>&1"
done


