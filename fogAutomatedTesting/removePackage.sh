#!/bin/bash
cwd="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$cwd/settings.sh"

#Packages are space seperated if there are multiple ones.
#You must change the below line to what you need.
packages="mod_evasive"

#example list of packages:
#packages="lsof iftop git svn firewalld"

clear

#Create hidden file for each node - for status reporting.
for i in "${storageNodes[@]}"
do
    echo "-1" > $cwd/.$i
done

#Start the commands going in unison.
for i in "${storageNodes[@]}"
do

    printf $(ssh -o ConnectTimeout=$sshTimeout $i "yum remove $packages -y > /dev/null 2>&1;echo \$?") > $cwd/.$i &

done

#Initially set completion status to false in order to enter into the loop.
complete="false"

#Run this loop until completion isn't false. This is the outter loop.
while [[ "$complete" == "false" ]]; do

    clear
    echo
    echo
    echo "Removing packages: $packages"
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


