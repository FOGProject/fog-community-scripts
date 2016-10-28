#!/bin/bash
cwd="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$cwd/storageNodes.sh"


#Packages are space seperated if there are multiple ones.
#You must change the below line to what you need.
packages="lsof"

#example list of packages:
#packages="lsof iftop git svn firewalld"

for i in "${storageNodes[@]}"
do
    printf "Installing $packages at: $i..."
    successCheck=$(ssh $i "yum install $packages -y > /dev/null 2>&1;echo \$?")
    if [[ "$successCheck" -eq 0 ]]; then
        printf "Success!\n"
    else
        printf "Failed!\n"
    fi
    printf "\n"


done
