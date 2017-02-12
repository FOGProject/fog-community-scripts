#!/bin/bash
cwd="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$cwd/settings.sh"


clear
echo
echo "Rebooting all nodes."
echo
sleep 1

#Start the commands going in unison.
for i in "${storageNodes[@]}"
do

    printf "Issuing reboot command to $i..."
    ssh -o ConnectTimeout=$sshTimeout $i "shutdown +1 -r > /dev/null 2>&1"
    printf "Done\n"

done
echo
echo "Sleeping for 70 seconds."
sleep 70



#Initially set completion status to false in order to enter into the loop.
complete="false"

#Run this loop until completion isn't false. This is the outter loop.
while [[ "$complete" == "false" ]]; do

    message="\n\nWaiting for nodes to come back online.\n\n"
    complete="true"
    #Loop through each node to check status, this is the inner loop.
    for i in "${storageNodes[@]}"
    do

    status="offline"
    status=$(ssh -o ConnectTimeout=$sshTimeout $i "echo up" 2> /dev/null)

    if [[ "$status" == "up" ]]; then
        message="$message${i}...is online!\n"
    else
        message="$message${i}...is offline.\n"
        complete="false"
    fi
    done #Inner loop done.

    clear
    printf "$message"
    sleep 1 #Update frequency.
done #Outter loop done.




#Say it's done.
echo
echo "Complete"
echo



