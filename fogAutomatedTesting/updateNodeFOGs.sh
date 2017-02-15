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
    echo "Installing branch $branch onto $i" >> $output
    printf $(timeout $fogTimeout ssh -o ConnectTimeout=$sshTimeout $i "cd /root/git/fogproject > /dev/null 2>&1;git reset --hard > /dev/null 2>&1;git pull > /dev/null 2>&1;git checkout $branch > /dev/null 2>&1;git pull > /dev/null 2>&1;cd bin > /dev/null 2>&1;./installfog.sh -y > /dev/null 2>&1;echo \$?") > $cwd/.$i

    sleep 10

    status=$(cat $cwd/.$i)
    if [[ "$status" == "-1" ]]; then
        complete="false"
    elif [[ "$status" == "0" ]]; then
        echo "$i success on branch $branch" >> $report
    else
        logname=$(timeout $sshTime ssh -o ConnectTimeout=$sshTimeout $i "ls -dtr1 /root/git/fogproject/bin/error_logs/* | tail -1")
        rightNow=$(date +%Y-%m-%d_%H-%M)
        mkdir -p "/var/www/html/fog_distro_check/$i/fog"
        chown apache:apache /var/www/html/fog_distro_check/$i/fog
        if [[ -f /root/$(basename $logname) ]]; then
            rm -f /root/$(basename $logname)
        fi
        if [[ -f /root/apache.log ]]; then
            rm -f /root/apache.log
        fi
        timeout $sshTime scp -o ConnectTimeout=$sshTimeout $i:$logname /root/$(basename $logname)
        timeout $sshTime scp -o ConnectTimeout=$sshTimeout $i:/var/log/httpd/error_log /root/apache.log
        timeout $sshTime scp -o ConnectTimeout=$sshTimeout $i:/var/log/apache2/error.log /root/apache.log

        logname=$(basename $logname)
        commit=$(timeout $sshTime ssh -o ConnectTimeout=$sshTimeout $i "cd /root/git/fogproject;git rev-parse HEAD")
        echo "Date=$rightNow" > /var/www/html/fog_distro_check/$i/fog/${rightNow}.log
        echo "Branch=$branch" >> /var/www/html/fog_distro_check/$i/fog/${rightNow}.log
        echo "Commit=$commit" >> /var/www/html/fog_distro_check/$i/fog/${rightNow}.log
        echo "OS=$i" >> /var/www/html/fog_distro_check/$i/fog/${rightNow}.log
        echo "Log_Name=$logname" >> /var/www/html/fog_distro_check/$i/fog/${rightNow}.log
        echo "#####Begin Log#####" >> /var/www/html/fog_distro_check/$i/fog/${rightNow}.log
        echo "" >> /var/www/html/fog_distro_check/$i/fog/${rightNow}.log
        mv /root/$logname /var/www/html/fog_distro_check/$i/fog/${rightNow}_fog.log
        mv /root/apache.log /var/www/html/fog_distro_check/$i/fog/${rightNow}_apache.log
        chown apache:apache /var/www/html/fog_distro_check/$i/fog/${rightNow}_fog.log
        chown apache:apache /var/www/html/fog_distro_check/$i/fog/${rightNow}_apache.log
        publicIP=$(/usr/bin/curl -s http://whatismyip.akamai.com/)
        echo "$i failed on branch $branch" >> $report
        echo "Fog log: http://$publicIP:20080/fog_distro_check/$i/fog/${rightNow}_fog.log" >> $report
        echo "Apache log: http://$publicIP:20080/fog_distro_check/$i/fog/${rightNow}_apache.log" >> $report
    fi
done



#Cleanup after all is done.
for i in "${storageNodes[@]}"
do
    rm -f $cwd/.$i
done


