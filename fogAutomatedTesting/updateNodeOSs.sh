#!/bin/bash
cwd="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$cwd/settings.sh"



#Create hidden file for each node - for status reporting.
for i in "${storageNodes[@]}"
do
    echo "-1" > $cwd/.$i
done



#Begin the dashboard building.
echo '<table>' >> $installer_dashboard
echo "<caption>OS Patching Status - Last updated: $(date +%c)</caption>" >> $installer_dashboard
echo '<tr>' >> $installer_dashboard
echo '<th>OS</th>' >> $installer_dashboard
echo '<th>Status</th>' >> $installer_dashboard
echo '<th>Patch Log</th>' >> $installer_dashboard
echo '</tr>' >> $installer_dashboard


#Loop through each box.
for i in "${storageNodes[@]}"
do
    #Kick the tires first.
    timeout $sshTime ssh -o ConnectTimeout=$sshTimeout $i "echo \"hey wake up\"" > /dev/null 2>&1
    timeout $sshTime ssh -o ConnectTimeout=$sshTimeout $i "echo \"right now\"" > /dev/null 2>&1

    #Remove existing update log if it's present.
    timeout $sshTime ssh -o ConnectTimeout=$sshTimeout $i "rm -f /root/update_output.txt > /dev/null 2>&1"


    # Start looking for which update commands are available.
    # DNF should always be checked before YUM, but besides that they should be ordered by popularity. Therefore pacman is last.
    echo "$(date +%x_%r) Updating OS for $i" >> $output
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
        echo "$(date +%x_%r) Don't know how to update $i. Seems like it won't accept DNF, YUM, APT-GET, or PACMAN." >> $output
    fi

    sleep 10

    status=$(cat $cwd/.$i)
    if [[ "$status" == "-1" ]]; then
        complete="false"
        echo '<tr>' >> $installer_dashboard
        echo "<td>${i}</td>" >> $installer_dashboard
        echo "<td>${orange}</td>" >> $installer_dashboard
        echo "<td>NA</td>" >> $installer_dashboard
        echo '</tr>' >> $installer_dashboard
      
    elif [[ "$status" == "0" ]]; then
        echo "$i successfully updated OS." >> $report
        echo "$(date +%x_%r) $i successfully updated OS." >> $output
        echo '<tr>' >> $installer_dashboard
        echo "<td>${i}</td>" >> $installer_dashboard
        echo "<td>${green}</td>" >> $installer_dashboard
	echo "<td>NA</td>" >> $installer_dashboard
        echo '</tr>' >> $installer_dashboard
    else
        #Tirekick again.
        timeout $sshTime ssh -o ConnectTimeout=$sshTimeout $i "echo \"hey wake up\"" > /dev/null 2>&1
        timeout $sshTime ssh -o ConnectTimeout=$sshTimeout $i "echo \"right now\"" > /dev/null 2>&1
  
        rightNow=$(date +%Y-%m-%d_%H-%M)
        mkdir -p "$webdir/$i/os"
        chown $permissions $webdir/$i/os
        timeout $sshTime scp -o ConnectTimeout=$sshTimeout $i:/root/update_output.txt $webdir/$i/os/${rightNow}.log
        if [[ -f $webdir/$i/os/${rightNow}.log ]]; then
            chown $permissions $webdir/$i/os/${rightNow}.log
            echo "$i failed to update OS, logs here: http://${domainName}${port}${netdir}/$i/os/$rightNow.log" >> $report
            echo "$(date +%x_%r) $i failed to update OS, logs here: http://${domainName}${port}${netdir}/$i/os/$rightNow.log" >> $output
            echo '<tr>' >> $installer_dashboard
            echo "<td>${i}</td>" >> $installer_dashboard
            echo "<td>${red}</td>" >> $installer_dashboard
	    echo "<td><a href=\"http://${domainName}${port}${netdir}/$i/os/$rightNow.log\">log</a>" >> $installer_dashboard
            echo '</tr>' >> $installer_dashboard
        else
            echo "$i failed to update OS, no log could be retrieved." >> $report
            echo "$(date +%x_%r) $i failed to update OS, no log could be retrieved." >> $output
            echo '<tr>' >> $installer_dashboard
            echo "<td>${i}</td>" >> $installer_dashboard
            echo "<td>${red}</td>" >> $installer_dashboard
	    echo "<td>NA</td>" >> $installer_dashboard
            echo '</tr>' >> $installer_dashboard
        fi 
    fi
done


echo '</table><br>' >> $installer_dashboard


#Cleanup after all is done.
for i in "${storageNodes[@]}"
do
    rm -f $cwd/.$i
done

