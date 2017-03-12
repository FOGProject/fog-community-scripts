#!/bin/bash
cwd="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$cwd/settings.sh"

snapshotName=$1


#Start the commands going in unison.
for i in "${storageNodes[@]}"
do
    echo "$(date +%x_%r) Creating snapshot $snapshotName for $i" >> $output
    ssh -o ConnectTimeout=$sshTimeout $hostsystem "virsh snapshot-delete $i $snapshotName > /dev/null 2>&1;virsh snapshot-create-as $i $snapshotName > /dev/null 2>&1"


done


