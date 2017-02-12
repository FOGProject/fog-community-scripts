#!/bin/bash
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
    if [[ $(ssh -o ConnectTimeout=$sshTimeout $i "command -v dnf > /dev/null 2>&1;echo \$?") -eq "0" ]]; then
        printf $(ssh -o ConnectTimeout=$sshTimeout $i "dnf update -y > /dev/null 2>&1;echo \$?") > $cwd/.$i &
    elif [[ $(ssh -o ConnectTimeout=$sshTimeout $i "command -v yum > /dev/null 2>&1;echo \$?") -eq "0" ]]; then
        printf $(ssh -o ConnectTimeout=$sshTimeout $i "yum update -y > /dev/null 2>&1;echo \$?") > $cwd/.$i &
    elif [[ $(ssh -o ConnectTimeout=$sshTimeout $i "command -v apt-get > /dev/null 2>&1;echo \$?") -eq "0" ]]; then
        printf $(ssh -o ConnectTimeout=$sshTimeout $i "apt-get -y update > /dev/null 2>&1;apt-get -y dist-upgrade > /dev/null 2>&1;echo \$?") > $cwd/.$i &
    else
        echo "Don't know how to update $i. Seems like it won't accept DNF, YUM, or APT-GET."
    fi
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
