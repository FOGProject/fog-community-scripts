#!/bin/bash
cwd="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$cwd/storageNodes.sh"

clear
echo
echo
echo "Updating FOG on defined systems."
echo
for i in "${storageNodes[@]}"
do
    printf "Updating FOG at: $i..."
    successCheck=$(ssh $i "cd /root/git/fogproject > /dev/null 2>&1;git reset --hard > /dev/null 2>&1;git pull > /dev/null 2>&1;git checkout dev-branch > /dev/null 2>&1;cd bin > /dev/null 2>&1;./installfog.sh -y > /dev/null 2>&1;echo \$?")
    if [[ "$successCheck" -eq 0 ]]; then
        printf "Success!\n"
    else
        printf "Failed!\n"
    fi
    printf "\n"

done
