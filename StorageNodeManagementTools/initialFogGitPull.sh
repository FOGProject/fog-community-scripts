#!/bin/bash


#Note:
# Trying to run this on the fog repo with more than a few systems at a time across a small
# internet pipe will likely result in a few of the nodes failing to clone.
# You may install and use trickle, but it's not available by default on many OSs.
# you can always download it and install it though, by copying the install script and then modifying the copy.
# The command to clone fog using trickle would be:

# trickle -sd 100 git clone https://github.com/FOGProject/fogproject.git /root/git/fogproject > /dev/null 2>&1

# Just replace the existing git clone command with that and all nodes would download at 1,000Kbps, or 1Mbps.

# If you're reading this after you've had a clone failure, just add a command at the begining to delete the clone, and to kill any git processes as well. Such as:

# pkill -f git > /dev/null 2>&1;rm -rf /root/git/fogproject;






cwd="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$cwd/settings.sh"


clear

#Create hidden file for each node - for status reporting.
for i in "${storageNodes[@]}"
do
    echo "-1" > $cwd/.$i
done

#Start the commands going in unison.
for i in "${storageNodes[@]}"
do

    printf $(ssh -o ConnectTimeout=$sshTimeout $i "mkdir /root/git > /dev/null 2>&1;git clone https://github.com/FOGProject/fogproject.git /root/git/fogproject > /dev/null 2>&1;echo \$?") > $cwd/.$i &

done

#Initially set completion status to false in order to enter into the loop.
complete="false"

#Run this loop until completion isn't false. This is the outter loop.
while [[ "$complete" == "false" ]]; do

    clear
    echo
    echo
    echo "Updating node operating systems."
    echo
    complete="true"
    #Loop through each node to check status, this is the inner loop.
    for i in "${storageNodes[@]}"
    do

    status=$(cat $cwd/.$i)
    if [[ "$status" == "-1" ]]; then
        echo "$i...waiting for return"
        complete="false"
    elif [[ "$status" == "0" ]]; then
        echo "$i...Success!"
    else
        echo "$i...Failure!"
    fi

    done #Inner loop done.
    sleep 1 #Update frequency.
done #Outter loop done.


#Cleanup after all is done.
for i in "${storageNodes[@]}"
do
    rm -f $cwd/.$i
done


#Say it's done.
echo
echo "Complete"
echo
