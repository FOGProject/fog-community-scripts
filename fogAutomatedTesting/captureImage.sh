#!/bin/bash

cwd="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$cwd/settings.sh"



#Ask for the snapshot name to be passed in.
if [[ -z $1 ]]; then
    echo "$(date +%x_%r) No snapshot passed for argument 1, exiting." >> $output
    exit
else
    snapshot=$1
fi


#Ask for the VM guest.
if [[ -z $2 ]]; then
    echo "$(date +%x_%r) No vmGuest passed for argument 2, exiting." >> $output
    exit
else
    vmGuest=$2
fi


#Ask for the FOG ID of the guest we are to use for capture.
if [[ -z $3 ]]; then
    echo "$(date +%x_%r) No vmGuestFogID passed for argument 3, exiting." >> $output
    exit
else
    vmGuestFogID=$3
fi

echo "$(date +%x_%r) Beginning capture testing. snapshot=\"${snapshot}\" vmGuest=\"${vmGuest}\" vmGuestFogID=\"${vmGuestFogID}"\" >> $output
echo "Beginning capture testing using \"$snapshot\"" >> $report


echo "$(date +%x_%r) Restoring snapshot \"$snapshotName\" to $vmGuest" >> $output
ssh -o ConnectTimeout=$sshTimeout $hostsystem "virsh snapshot-revert $vmGuest $snapshot > /dev/null 2>&1"
#Gracefully shutdown VM.
echo "$(date +%x_%r) Asking \"$vmGuest\" to gracefully shutdown if it's not already." >> $output
ssh -o ConnectTimeout=$sshTimeout $hostsystem "virsh shutdown \"$vmGuest\" > /dev/null 2>&1"
sleep 30
ssh -o ConnectTimeout=$sshTimeout $hostsystem "virsh destroy \"$vmGuest\" > /dev/null 2>&1"

echo "$(date +%x_%r) Queuing the capture job on the server." >> $output
#Queue the capture job with the test fog server.
curl -ku "$testServerWebCredentials" --header "content-type: application/json" --header "fog-api-token: $testServerApiToken" http://${testServerIP}/fog/host/${vmGuestFogID}/task --data "{\"taskTypeID\":2}"

sleep 5

#Start the VM back up.
echo "$(date +%x_%r) Starting up \"$testHost1VM\" for capture." >> $output
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



