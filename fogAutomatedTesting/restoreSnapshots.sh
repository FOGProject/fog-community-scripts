#!/bin/bash
cwd="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$cwd/settings.sh"

snapshotName=$1



#Start the commands going in unison.
for i in "${storageNodes[@]}"
do
    echo "Restoring snapshot $snapshotName to $i"
    ssh -o ConnectTimeout=$sshTimeout $hostsystem "virsh snapshot-revert $i $snapshotName > /dev/null 2>&1"
done


