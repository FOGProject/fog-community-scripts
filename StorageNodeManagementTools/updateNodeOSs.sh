#!/bin/bash
cwd="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$cwd/storageNodes.sh"

clear
echo
echo
echo "Updating storage node operating systems."
echo
for i in "${storageNodes[@]}"
do
    printf "Updating installed packages at: $i..."
    successCheck=$( ssh $i "yum update -y > /dev/null 2>&1;echo \$?")
    if [[ "$successCheck" -eq 0 ]]; then
        printf "Success!\n"
    else
        printf "Failed!\n"
    fi
    printf "\n"
done
