#!/bin/bash
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
