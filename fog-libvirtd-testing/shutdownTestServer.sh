#!/bin/bash

#Simple little utility script to shutdown the test fog server VM.

cwd="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$cwd/settings.sh"

echo "$(date +%x_%r) Shutting down $testServerVMName" >> $output
ssh -o ConnectTimeout=$sshTimeout $hostsystem "virsh shutdown $testServerVMName > /dev/null 2>&1"
sleep 60
ssh -o ConnectTimeout=$sshTimeout $hostsystem "virsh destroy $testServerVMName > /dev/null 2>&1"



