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

    #Kick the tires. It helps, makes ssh load into ram, makes the switch learn where the traffic needs to go.
    nonsense=$(timeout $sshTime ssh -o ConnectTimeout=$sshTimeout $i "wakeup")
    nonsense=$(timeout $sshTime ssh -o ConnectTimeout=$sshTimeout $i "get ready")

    #Start the installation process.
    timeout $sshTime scp -o ConnectTimeout=$sshTimeout $cwd/installBranch.sh $i:/root/installBranch.sh
    printf $(timeout $fogTimeout ssh -o ConnectTimeout=$sshTimeout $i "/root/./installBranch.sh $branch;echo \$?") > $cwd/.$i
    timeout $sshTime ssh -o ConnectTimeout=$sshTimeout $i "rm -f /root/installBranch.sh"
    status=$(cat $cwd/.$i)

    echo "Return code was $status" >> $output

    if [[ "$status" == "0" ]]; then
        echo "$i success on branch $branch" >> $report
    elif [[ "$status" -eq "-1" ]]; then
        echo "$i failure on branch $branch did not return within $fogTimeout" >> $report
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
        echo "Date=$rightNow" > /var/www/html/fog_distro_check/$i/fog/${rightNow}_fog.log
        echo "Branch=$branch" >> /var/www/html/fog_distro_check/$i/fog/${rightNow}_fog.log
        echo "Commit=$commit" >> /var/www/html/fog_distro_check/$i/fog/${rightNow}_fog.log
        echo "OS=$i" >> /var/www/html/fog_distro_check/$i/fog/${rightNow}_fog.log
        echo "Log_Name=$logname" >> /var/www/html/fog_distro_check/$i/fog/${rightNow}_fog.log
        echo "#####Begin Log#####" >> /var/www/html/fog_distro_check/$i/fog/${rightNow}_fog.log
        echo "" >> /var/www/html/fog_distro_check/$i/fog/${rightNow}_fog.log
        cat /root/$logname >> /var/www/html/fog_distro_check/$i/fog/${rightNow}_fog.log
        rm -f /root/$logname
        mv /root/apache.log /var/www/html/fog_distro_check/$i/fog/${rightNow}_apache.log
        chown apache:apache /var/www/html/fog_distro_check/$i/fog/${rightNow}_fog.log
        chown apache:apache /var/www/html/fog_distro_check/$i/fog/${rightNow}_apache.log
        publicIP=$(/usr/bin/curl -s http://whatismyip.akamai.com/)

        case $status in
            2) echo "$i on branch $branch failed to reset git" >> $report ;;
            3) echo "$i on branch $branch failed to pull git" >> $report ;;
            4) echo "$i on branch $branch failed to checkout git" >> $report ;;
            5) echo "$i on branch $branch failed to change directory" >> $report ;;
            6) echo "$i on branch $branch failed installation" >> $report ;;
        esac

        echo "Fog log: http://$publicIP:20080/fog_distro_check/$i/fog/${rightNow}_fog.log" >> $report
        echo "Apache log: http://$publicIP:20080/fog_distro_check/$i/fog/${rightNow}_apache.log" >> $report
    fi
done



#Cleanup after all is done.
for i in "${storageNodes[@]}"
do
    rm -f $cwd/.$i
done


