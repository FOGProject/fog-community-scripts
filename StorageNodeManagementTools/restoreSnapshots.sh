#!/bin/bash
cwd="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$cwd/settings.sh"


clear


#Start the commands going in unison.
for i in "${storageNodes[@]}"
do

    ssh -o ConnectTimeout=$sshTimeout $hostsystem "virsh snapshot-revert $i clean > /dev/null 2>&1;echo $i complete"


done


