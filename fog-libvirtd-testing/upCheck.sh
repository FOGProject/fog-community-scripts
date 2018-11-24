#!/bin/bash

#This is a custom command to send to all the nodes. Put your command in the "command" variable below.
#Depending on if you want to use parameter expansion or not, you need to single or double quote, and escape properly.


cwd="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$cwd/settings.sh"

command="echo 'I am up' > /dev/null 2>&1"


#Create hidden file for each node - for status reporting.
for i in "${storageNodes[@]}"
do
    echo "-1" > $cwd/.$i
done

for i in "${storageNodes[@]}"
do
    printf $(timeout $sshTime ssh -o ConnectTimeout=$sshTimeout $i "$command;echo \$?") > $cwd/.$i
    status=$(cat $cwd/.$i)
    if [[ "$status" == "-1" ]]; then
        echo "$i did not complete."
    elif [[ "$status" == "0" ]]; then
        echo "$i success."
    else
        echo "$i Failure!"
    fi
done


#Cleanup after all is done.
for i in "${storageNodes[@]}"
do
    rm -f $cwd/.$i
done

