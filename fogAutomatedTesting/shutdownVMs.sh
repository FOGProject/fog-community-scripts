#!/bin/bash
cwd="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$cwd/settings.sh"


#Start the commands going in unison.
for i in "${storageNodes[@]}"
do
    ssh -o ConnectTimeout=$sshTimeout $hostsystem "virsh shutdown $i > /dev/null 2>&1"
done
sleep 120
#Start the commands going in unison.
for i in "${storageNodes[@]}"
do
    ssh -o ConnectTimeout=$sshTimeout $hostsystem "virsh destroy $i > /dev/null 2>&1"
done
