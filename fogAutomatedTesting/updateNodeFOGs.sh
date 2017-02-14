#!/bin/bash
cwd="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$cwd/settings.sh"
branch=$1


#Create hidden file for each node - for status reporting.
for i in "${storageNodes[@]}"
do
    echo "-1" > $cwd/.$i
done

#Start the commands going in unison.
for i in "${storageNodes[@]}"
do
    echo "Installing branch $branch onto $i"
    printf $(ssh -o ConnectTimeout=$sshTimeout $i "cd /root/git/fogproject > /dev/null 2>&1;git reset --hard > /dev/null 2>&1;git pull > /dev/null 2>&1;git checkout $branch > /dev/null 2>&1;git pull > /dev/null 2>&1;cd bin > /dev/null 2>&1;./installfog.sh -y > /dev/null 2>&1;echo \$?") > $cwd/.$i

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


sleep 15


for i in "${storageNodes[@]}"
    do

    status=$(cat $cwd/.$i)
    if [[ "$status" == "-1" ]]; then
        complete="false"
    elif [[ "$status" == "0" ]]; then
        echo "$i SUCCESSFULLY installed commit $(ssh -o ConnectTimeout=$sshTimeout $i "cd /root/git/fogproject;git rev-parse HEAD") from branch $branch" >> $report
    else

        
        logname=$(ssh -o ConnectTimeout=$sshTimeout $i "ls -dtr1 /root/git/fogproject/bin/error_logs/* | tail -1")
       
        rightNow=$(date +%Y-%m-%d_%H-%M)
        mkdir -p "/var/www/html/$i/fog"
        chown apache:apache /var/www/html/$i/fog

        if [[ -f /root/$logname ]]; then
            rm -f /root/$logname
        fi

        scp -o ConnectTimeout=$sshTimeout $i:$logname /root/$(basename $logname)
        logname=$(basename $logname)
        commit=$(ssh -o ConnectTimeout=$sshTimeout $i "cd /root/git/fogproject;git rev-parse HEAD")

        echo "Date=$rightNow" > /var/www/html/$i/fog/${rightNow}.log
        echo "Branch=$branch" >> /var/www/html/$i/fog/${rightNow}.log
        echo "Commit=$commit" >> /var/www/html/$i/fog/${rightNow}.log
        echo "OS=$i" >> /var/www/html/$i/fog/${rightNow}.log
        echo "Log_Name=$logname" >> /var/www/html/$i/fog/${rightNow}.log
        echo "#####Begin Log#####" >> /var/www/html/$i/fog/${rightNow}.log
        echo "" >> /var/www/html/$i/fog/${rightNow}.log
        cat /root/$logname >> /var/www/html/$i/fog/${rightNow}.log
        rm -f /root/$logname
        chown apache:apache /var/www/html/$i/fog/${rightNow}.log
        publicIP=$(/usr/bin/curl -s http://whatismyip.akamai.com/)
        echo "$i failed to install commit $commit from branch $branch, logs here: http://$publicIP:20080/$i/fog/$rightNow.log" >> $report
    fi
    sleep 15
done


#Cleanup after all is done.
for i in "${storageNodes[@]}"
do
    rm -f $cwd/.$i
done


