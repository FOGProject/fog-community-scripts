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

    printf $(ssh -o ConnectTimeout=$sshTimeout $i "cd /root/git/fogproject > /dev/null 2>&1;git reset --hard > /dev/null 2>&1;git pull > /dev/null 2>&1;git checkout $branch > /dev/null 2>&1;git pull > /dev/null 2>&1;cd bin > /dev/null 2>&1;./installfog.sh -y > /dev/null 2>&1;echo \$?") > $cwd/.$i &

done

#Initially set completion status to false in order to enter into the loop.
complete="false"

#Run this loop until completion isn't false. This is the outter loop.
while [[ "$complete" == "false" ]]; do

    complete="true"
    #Loop through each node to check status, this is the inner loop.
    for i in "${storageNodes[@]}"
    do

        status=$(cat $cwd/.$i)
        if [[ "$status" == "-1" ]]; then
            complete="false"
        fi

    done #Inner loop done.
    sleep 1 #Update frequency.
done #Outter loop done.



for i in "${storageNodes[@]}"
    do

    status=$(cat $cwd/.$i)
    if [[ "$status" == "-1" ]]; then
        complete="false"
    elif [[ "$status" == "0" ]]; then
        echo "$i successfully completed FOG installer."
    else
        echo "$i failed to complete FOG installer."
    fi
done

for i in "${storageNodes[@]}"
do

    commit=$(ssh -o ConnectTimeout=$sshTimeout $i "git -C /root/git/fogproject rev-parse HEAD")
    echo "$i was using commit: $commit" >> $report

done








#Cleanup after all is done.
for i in "${storageNodes[@]}"
do
    rm -f $cwd/.$i
done


