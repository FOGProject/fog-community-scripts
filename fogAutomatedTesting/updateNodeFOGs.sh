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
    nonsense=$(timeout $sshTime ssh -o ConnectTimeout=$sshTimeout $i "echo wakeup")
    nonsense=$(timeout $sshTime ssh -o ConnectTimeout=$sshTimeout $i "echo get ready")

    #Start the installation process.
    timeout $sshTime scp -o ConnectTimeout=$sshTimeout $cwd/installBranch.sh $i:/root/installBranch.sh
    echo "branch=$branch"
    echo "sshTime=$sshTime"
    echo "fogTimeout=$fogTimeout"
    echo "sshTimeout=$sshTimeout"
    echo "cwd=$cwd"
    printf $(timeout $fogTimeout ssh -o ConnectTimeout=$sshTimeout $i "/root/./installBranch.sh $branch;echo \$?") > $cwd/.$i
    timeout $sshTime ssh -o ConnectTimeout=$sshTimeout $i "rm -f /root/installBranch.sh"
    status=$(cat $cwd/.$i)
    echo "status=$status"

    echo "Return code was $status" >> $output

    if [[ "$status" == "0" ]]; then
        echo "$i success on branch $branch" >> $report
    else
        foglog=$(timeout $sshTime ssh -o ConnectTimeout=$sshTimeout $i "ls -dtr1 /root/git/fogproject/bin/error_logs/* | tail -1")
        rightNow=$(date +%Y-%m-%d_%H-%M)
        mkdir -p "/var/www/html/fog_distro_check/$i/fog"
        chown apache:apache /var/www/html/fog_distro_check/$i/fog
        if [[ -f /root/$(basename $foglog) ]]; then
            rm -f /root/$(basename $foglog)
        fi
        if [[ -f /root/apache.log ]]; then
            rm -f /root/apache.log
        fi

        #Get fog log.
        timeout $sshTime scp -o ConnectTimeout=$sshTimeout $i:$foglog /root/$(basename $foglog) > /dev/null 2>&1
        #Get apache log. It can only be in one of two spots.
        timeout $sshTime scp -o ConnectTimeout=$sshTimeout $i:/var/log/httpd/error_log /var/www/html/fog_distro_check/$i/fog/${rightNow}_apache.log > /dev/null 2>&1
        timeout $sshTime scp -o ConnectTimeout=$sshTimeout $i:/var/log/apache2/error.log /var/www/html/fog_distro_check/$i/fog/${rightNow}_apache.log > /dev/null 2>&1
        #Set owernship.
        chown apache:apache /var/www/html/fog_distro_check/$i/fog/${rightNow}_apache.log > /dev/null 2>&1

        foglog=$(basename $foglog)
        commit=$(timeout $sshTime ssh -o ConnectTimeout=$sshTimeout $i "cd /root/git/fogproject;git rev-parse HEAD")
        echo "Date=$rightNow" > /var/www/html/fog_distro_check/$i/fog/${rightNow}_fog.log
        echo "Branch=$branch" >> /var/www/html/fog_distro_check/$i/fog/${rightNow}_fog.log
        echo "Commit=$commit" >> /var/www/html/fog_distro_check/$i/fog/${rightNow}_fog.log
        echo "OS=$i" >> /var/www/html/fog_distro_check/$i/fog/${rightNow}_fog.log
        echo "Log_Name=$foglog" >> /var/www/html/fog_distro_check/$i/fog/${rightNow}_fog.log
        echo "#####Begin Log#####" >> /var/www/html/fog_distro_check/$i/fog/${rightNow}_fog.log
        echo "" >> /var/www/html/fog_distro_check/$i/fog/${rightNow}_fog.log
        cat /root/$foglog >> /var/www/html/fog_distro_check/$i/fog/${rightNow}_fog.log
        rm -f /root/$foglog
        chown apache:apache /var/www/html/fog_distro_check/$i/fog/${rightNow}_fog.log



        if [[ -z $status ]]; then
            echo "$i on branch $branch returned no exit code" >> $report
        else
            case $status in
                -1) echo "$i failure on branch $branch did not return within time limit $fogTimeout" >> $report ;;
                1) echo "$i on branch $branch failed, no branch passed" >> $report ;;
                2) echo "$i on branch $branch failed to reset git" >> $report ;;
                3) echo "$i on branch $branch failed to pull git" >> $report ;;
                4) echo "$i on branch $branch failed to checkout git" >> $report ;;
                5) echo "$i on branch $branch failed to change directory" >> $report ;;
                6) echo "$i on branch $branch failed installation" >> $report ;;
                *) echo "$i on branch $branch failed with exit code \"$status\"" >> $report ;;
            esac
        fi

        publicIP=$(/usr/bin/curl -s http://whatismyip.akamai.com/)

        if [[ -f /var/www/html/fog_distro_check/$i/fog/${rightNow}_fog.log ]]; then
            echo "Fog log: http://$publicIP:20080/fog_distro_check/$i/fog/${rightNow}_fog.log" >> $report
        else
            echo "No fog log could be retrieved from $i" >> $report
        fi
 
        if [[ -f /var/www/html/fog_distro_check/$i/fog/${rightNow}_apache.log ]]; then
            echo "Apache log: http://$publicIP:20080/fog_distro_check/$i/fog/${rightNow}_apache.log" >> $report
        else
            echo "No apache log could be retrieved from $i" >> $report
        fi

    fi
done



#Cleanup after all is done.
for i in "${storageNodes[@]}"
do
    rm -f $cwd/.$i
done


