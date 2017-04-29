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


echo "$(date +%x_%r) Restoring snapshot \"$snapshot\" to \"$vmGuest\"" >> $output
ssh -o ConnectTimeout=$sshTimeout $hostsystem "virsh snapshot-revert $vmGuest $snapshot > /dev/null 2>&1"
#Gracefully shutdown VM.
echo "$(date +%x_%r) Asking \"$vmGuest\" to gracefully shutdown if it's not already." >> $output
ssh -o ConnectTimeout=$sshTimeout $hostsystem "virsh shutdown \"$vmGuest\" > /dev/null 2>&1"
sleep 30
#Kill it if it lags.
ssh -o ConnectTimeout=$sshTimeout $hostsystem "virsh destroy \"$vmGuest\" > /dev/null 2>&1"

echo "$(date +%x_%r) Queuing the capture job on the server." >> $output

#Queue the capture job with the test fog server.
cmd="curl -k --header 'content-type: application/json' --header 'fog-user-token: ${testServerUserToken}' --header 'fog-api-token: $testServerApiToken' http://${testServerIP}/fog/host/${vmGuestFogID}/task --data '{\"taskTypeID\":2}'"
eval $cmd >> $output

sleep 5

#Start the VM back up.
echo "$(date +%x_%r) Starting up \"$testHost1VM\" for capture." >> $output
ssh -o ConnectTimeout=$sshTimeout $hostsystem "virsh start $testHost1VM > /dev/null 2>&1"




#Need to monitor task progress somehow. Once done, should exit.

while true; do
    sleep 3
    curl -k --header "content-type: application/json" --header 'fog-user-token: ${testServerUserToken}' --header "fog-api-token: $testServerApiToken" http://${testServerIP}/fog/host/${vmGuestFogID}/task -X '{"hosts": [${vmGuestFogID}]}'
done




