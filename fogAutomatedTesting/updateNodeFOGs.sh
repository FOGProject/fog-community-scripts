#!/bin/bash
cwd="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$cwd/settings.sh"
branch=$1


#Create hidden file for each node - for status reporting.
for i in "${storageNodes[@]}"
do
    echo "-1" > $cwd/.$i
done

#Loop through each box.
for i in "${storageNodes[@]}"
do
    echo "Installing branch $branch onto $i"
    printf $(timeout $fogTimeout ssh -o ConnectTimeout=$sshTimeout $i "cd /root/git/fogproject > /dev/null 2>&1;git reset --hard > /dev/null 2>&1;git pull > /dev/null 2>&1;git checkout $branch > /dev/null 2>&1;git pull > /dev/null 2>&1;cd bin > /dev/null 2>&1;./installfog.sh -y > /dev/null 2>&1;echo \$?") > $cwd/.$i

    sleep 10

    status=$(cat $cwd/.$i)
    if [[ "$status" == "-1" ]]; then
        complete="false"
    elif [[ "$status" == "0" ]]; then
        echo "$i successfully installed commit $(ssh -o ConnectTimeout=$sshTimeout $i "cd /root/git/fogproject;git rev-parse HEAD") from branch $branch" >> $report
    else
        logname=$(timeout $sshTime ssh -o ConnectTimeout=$sshTimeout $i "ls -dtr1 /root/git/fogproject/bin/error_logs/* | tail -1")
        rightNow=$(date +%Y-%m-%d_%H-%M)
        mkdir -p "/var/www/html/fog_distro_check/$i/fog"
        chown apache:apache /var/www/html/fog_distro_check/$i/fog
        if [[ -f /root/$(basename $logname) ]]; then
            rm -f /root/$(basename $logname)
        fi
        timeout $sshTime scp -o ConnectTimeout=$sshTimeout $i:$logname /root/$(basename $logname)
        logname=$(basename $logname)
        commit=$(timeout $sshTime ssh -o ConnectTimeout=$sshTimeout $i "cd /root/git/fogproject;git rev-parse HEAD")
        echo "Date=$rightNow" > /var/www/html/fog_distro_check/$i/fog/${rightNow}.log
        echo "Branch=$branch" >> /var/www/html/fog_distro_check/$i/fog/${rightNow}.log
        echo "Commit=$commit" >> /var/www/html/fog_distro_check/$i/fog/${rightNow}.log
        echo "OS=$i" >> /var/www/html/fog_distro_check/$i/fog/${rightNow}.log
        echo "Log_Name=$logname" >> /var/www/html/fog_distro_check/$i/fog/${rightNow}.log
        echo "#####Begin Log#####" >> /var/www/html/fog_distro_check/$i/fog/${rightNow}.log
        echo "" >> /var/www/html/fog_distro_check/$i/fog/${rightNow}.log
        cat /root/$logname >> /var/www/html/fog_distro_check/$i/fog/${rightNow}.log
        rm -f /root/$logname
        chown apache:apache /var/www/html/fog_distro_check/$i/fog/${rightNow}.log
        publicIP=$(/usr/bin/curl -s http://whatismyip.akamai.com/)
        echo "$i failed to install commit $commit from branch $branch, logs here: http://$publicIP:20080/fog_distro_check/$i/fog/$rightNow.log" >> $report
    fi
done



#Cleanup after all is done.
for i in "${storageNodes[@]}"
do
    rm -f $cwd/.$i
done


