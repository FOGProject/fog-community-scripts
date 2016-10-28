#!/bin/bash
cwd="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$cwd/storageNodes.sh"


for i in "${storageNodes[@]}"
do

    ssh $i "reboot"

done

