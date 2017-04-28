#!/bin/bash

cwd="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$cwd/settings.sh"


#Ask for the snapshot name to be passed in. We only do one at a time.
snapshot=$1

#Ask for the VM guest.
vmGuest=$2

#Ask for the FOG ID we are to use for capture.
vmGuestFogID=$3

#Ask for the branch we are using.
branch=$4


if [[ -z $snapshot ]]; then
    echo "$(date +%x_%r) No snapshot passed for argument 1, exiting." >> $output
    exit
fi


if [[ -z $vmGuest ]]; then
    echo "$(date +%x_%r) No vmGuest passed for argument 2, exiting." >> $output
    exit
fi


if [[ -z $vmGuestFogID ]]; then
    echo "$(date +%x_%r) No vmGuestFogID passed for argument 3, exiting." >> $output
    exit
fi


if [[ -z $branch ]]; then
    echo "$(date +%x_%r) No branch passed for argument 4, exiting." >> $output
    exit
fi


echo "$(date +%x_%r) Beginning capture testing. snapshot=${snapshot} vmGuest=${vmGuest} vmGuestFogID=${vmGuestFogID} branch=${branch}" >> $output


echo "$(date +%x_%r) Restoring snapshot $snapshotName to $vmGuest" >> $output
ssh -o ConnectTimeout=$sshTimeout $hostsystem "virsh snapshot-revert $vmGuest $snapshot > /dev/null 2>&1"
#Gracefully shutdown VM.
echo "$(date +%x_%r) Asking $vmGuest to gracefully shutdown if it's not already." >> $output
ssh -o ConnectTimeout=$sshTimeout $hostsystem "virsh shutdown $vmGuest > /dev/null 2>&1"
#Give the FOG Server a reboot.
echo "$(date +%x_%r) Asking $testServerVMName to gracefully shutdown if it's not already." >> $output
ssh -o ConnectTimeout=$sshTimeout $hostsystem "virsh shutdown $testServerVMName > /dev/null 2>&1"
sleep 30
#force-off if it straggles.
ssh -o ConnectTimeout=$sshTimeout $hostsystem "virsh destroy $vmGuest > /dev/null 2>&1"
sh -o ConnectTimeout=$sshTimeout $hostsystem "virsh destroy $testServerVMName > /dev/null 2>&1"




#####Get the FOG Server ready - install latest working branch.



#Start the server back up.
echo "$(date +%x_%r) Starting up $testServerVMName." >> $output
ssh -o ConnectTimeout=$sshTimeout $hostsystem "virsh start $testServerVMName > /dev/null 2>&1"

sleep 60


#Create hidden file for server - for status reporting.
echo "-1" > $cwd/.$testServerSshAlias
echo "$(date +%x_%r) Installing branch $branch onto $testServerSshAlias" >> $output

#Kick the tires. It helps, makes ssh load into ram, makes the switch learn where the traffic needs to go.
nonsense=$(timeout $sshTime ssh -o ConnectTimeout=$sshTimeout $testServerSshAlias "echo wakeup")
nonsense=$(timeout $sshTime ssh -o ConnectTimeout=$sshTimeout $testServerSshAlias "echo get ready")

#Start the installation process.
timeout $sshTime scp -o ConnectTimeout=$sshTimeout $cwd/installBranch.sh $testServerSshAlias:/root/installBranch.sh
printf $(timeout $fogTimeout ssh -o ConnectTimeout=$sshTimeout $testServerSshAlias "/root/./installBranch.sh $branch;echo \$?") > $cwd/.$testServerSshAlias
timeout $sshTime ssh -o ConnectTimeout=$sshTimeout $testServerSshAlias "rm -f /root/installBranch.sh"
status=$(cat $cwd/.$testServerSshAlias)

echo "$(date +%x_%r) Return code was $status" >> $output


#Cleanup after all is done.
rm -f $cwd/.$testServerSshAlias


if [[ "$status" != "0" ]]; then
    echo "$(date +%x_%r) non-zero exit code, not continuing." >> $output
    exit
fi



#Queue the capture job with the test fog server.
curl -ku "$testServerWebCredentials" --header "content-type: application/json" --header "fog-api-token: $testServerApiToken" http://${testServerIP}/fog/host/${vmGuestFogID}/task --data "{\"taskTypeID\":2}"

sleep 10
#Start the VM back up.
echo "$(date +%x_%r) Starting up $testHost1VM for capture." >> $output
ssh -o ConnectTimeout=$sshTimeout $hostsystem "virsh start $testHost1VM > /dev/null 2>&1"


# Now what?
#Need to monitor task progress somehow.
#Need to grab the small files from the image on the server.
#Need to get a directory listing of the image on the server.
#Need to somehow check if the reference box can still boot. This may require the fog client & a snapin task.



sleep 3600

#At the end, we know to shut down these VMs.
echo "$(date +%x_%r) Asking $testServerVMName to gracefully shutdown if it's not already." >> $output
ssh -o ConnectTimeout=$sshTimeout $hostsystem "virsh shutdown $testServerVMName > /dev/null 2>&1"
sleep 30
#force-off if it straggles.
ssh -o ConnectTimeout=$sshTimeout $hostsystem "virsh destroy $testServerVMName > /dev/null 2>&1"
#Shutdown test guest.
echo "$(date +%x_%r) Asking $vmGuest to gracefully shutdown if it's not already." >> $output
ssh -o ConnectTimeout=$sshTimeout $hostsystem "virsh shutdown $vmGuest > /dev/null 2>&1"
sleep 30
#force-off if it straggles.
ssh -o ConnectTimeout=$sshTimeout $hostsystem "virsh destroy $vmGuest > /dev/null 2>&1"



