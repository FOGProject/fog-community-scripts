#!/bin/bash
cwd="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$cwd/settings.sh"



#Create hidden file for each node - for status reporting.
for i in "${storageNodes[@]}"
do
    echo "-1" > $cwd/.$i
done

#Loop through each box.
for i in "${storageNodes[@]}"
do
    echo "Updating OS for $i"
    if [[ $(timeout $sshTime ssh -o ConnectTimeout=$sshTimeout $i "command -v dnf > /dev/null 2>&1;echo \$?") -eq "0" ]]; then
        printf $(timeout $osTimeout ssh -o ConnectTimeout=$sshTimeout $i "dnf update -y > /root/update_output.txt;echo \$?") > $cwd/.$i
    elif [[ $(timeout $sshTime ssh -o ConnectTimeout=$sshTimeout $i "command -v yum > /dev/null 2>&1;echo \$?") -eq "0" ]]; then
        printf $(timeout $osTimeout ssh -o ConnectTimeout=$sshTimeout $i "yum update -y > /root/update_output.txt;echo \$?") > $cwd/.$i
    elif [[ $(timeout $sshTime ssh -o ConnectTimeout=$sshTimeout $i "DEBIAN_FRONTEND=noninteractive;command -v apt-get > /dev/null 2>&1;echo \$?") -eq "0" ]]; then
        printf $(timeout $osTimeout ssh -o ConnectTimeout=$sshTimeout $i "DEBIAN_FRONTEND=noninteractive;apt-get -y update > /dev/null 2>&1;apt-get -y dist-upgrade > /root/update_output.txt;echo \$?") > $cwd/.$i
    elif [[ $(timeout $sshTime ssh -o ConnectTimeout=$sshTimeout $i "command -v pacman > /dev/null 2>&1;echo \$?") -eq "0" ]]; then
        printf $(timeout $osTimeout ssh -o ConnectTimeout=$sshTimeout $i "pacman -Syu --noconfirm > /root/update_output.txt;echo \$?") > $cwd/.$i
    else
        echo "Don't know how to update $i. Seems like it won't accept DNF, YUM, APT-GET, or PACMAN." >> $report
    fi

    sleep 10

    status=$(cat $cwd/.$i)
    if [[ "$status" == "-1" ]]; then
        complete="false"
    elif [[ "$status" == "0" ]]; then
        echo "$i successfully updated OS to latest." >> $report
    else
        rightNow=$(date +%Y-%m-%d_%H-%M)
        mkdir -p "/var/www/html/fog_distro_check/$i/os"
        chown apache:apache /var/www/html/fog_distro_check/$i/os
        timeout $sshTime scp -o ConnectTimeout=$sshTimeout $i:/root/update_output.txt /var/www/html/fog_distro_check/$i/os/${rightNow}.log
        chown apache:apache /var/www/html/fog_distro_check/$i/os/${rightNow}.log
        publicIP=$(/usr/bin/curl -s http://whatismyip.akamai.com/)
        echo "$i failed to update OS to latest, logs here: http://$publicIP:20080/fog_distro_check/$i/os/$rightNow.log" >> $report
    fi
done




#Cleanup after all is done.
for i in "${storageNodes[@]}"
do
    rm -f $cwd/.$i
done

