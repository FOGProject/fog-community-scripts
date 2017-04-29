#!/bin/bash

cwd="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$cwd/settings.sh"

#We only test working.
branch="working"


#Start the server up.
echo "$(date +%x_%r) Starting up \"$testServerVMName\"" >> $output
ssh -o ConnectTimeout=$sshTimeout $hostsystem "virsh start $testServerVMName > /dev/null 2>&1"
sleep 60



#Create hidden file for server - for status reporting.
echo "-1" > $cwd/.$testServerSshAlias
echo "$(date +%x_%r) Installing branch \"$branch\" onto \"$testServerSshAlias\"" >> $output

#Kick the tires. It helps, makes ssh load into ram, makes the switch learn where the traffic needs to go.
nonsense=$(timeout $sshTime ssh -o ConnectTimeout=$sshTimeout $testServerSshAlias "echo wakeup")
nonsense=$(timeout $sshTime ssh -o ConnectTimeout=$sshTimeout $testServerSshAlias "echo get ready")

#Start the installation process.
timeout $sshTime scp -o ConnectTimeout=$sshTimeout $cwd/installBranch.sh $testServerSshAlias:/root/installBranch.sh
printf $(timeout $fogTimeout ssh -o ConnectTimeout=$sshTimeout $testServerSshAlias "/root/./installBranch.sh $branch;echo \$?") > $cwd/.$testServerSshAlias
timeout $sshTime ssh -o ConnectTimeout=$sshTimeout $testServerSshAlias "rm -f /root/installBranch.sh"
status=$(cat $cwd/.$testServerSshAlias)

#Cleanup after all is done.
rm -f $cwd/.$testServerSshAlias


if [[ "$status" != "0" ]]; then
    echo "$(date +%x_%r) Exit code was \"$status\", not continuing." >> $output
    echo "Exit code was \"$status\", not continuing." >> $report
    exit $status
fi

echo "$(date +%x_%r) Update was successful." >> $output
echo "Update was successful." >> $report

exit 0

