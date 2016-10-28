#!/bin/bash
cwd="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$cwd/storageNodes.sh"

#Packages are space seperated if there are multiple ones.
#You must edit the below line to remove the packages you need removed.
packages="mod_evasive"

#example space seperated list:
#packages="mod_evasive php* lib*php"

for i in "${storageNodes[@]}"
do
    printf "Removing $packages at: $i..."
    successCheck=$(ssh $i "yum remove $packages -y > /dev/null 2>&1;echo \$?")
    if [[ "$successCheck" -eq 0 ]]; then
        printf "Success!\n"
    else
        printf "Failed!\n"
    fi
    printf "\n"


done
