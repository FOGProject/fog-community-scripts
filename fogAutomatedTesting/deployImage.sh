#!/bin/bash

cwd="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$cwd/settings.sh"

#Ask for the VM guest name.
if [[ -z $1 ]]; then
    echo "$(date +%x_%r) No vmGuest name passed for argument 1, exiting." >> $output
    exit
else
    vmGuest=$1
fi


#Ask for the FOG ID of the guest we are to use for deploy.
if [[ -z $2 ]]; then
    echo "$(date +%x_%r) No vmGuestFogID passed for argument 2, exiting." >> $output
    exit
else
    vmGuestFogID=$2
fi


echo "$(date +%x_%r) Queuing deploy. vmGuest=\"${vmGuest}\" vmGuestFogID=\"${vmGuestFogID}"\" >> $output

#Queue the deploy jobs with the test fog server.
cmd="curl --silent -k --header 'content-type: application/json' --header 'fog-user-token: ${testServerUserToken}' --header 'fog-api-token: $testServerApiToken' http://${testServerIP}/fog/host/${vmGuestFogID}/task --data '{\"taskTypeID\":1}'"
eval $cmd > /dev/null 2>&1 #Don't care that it says null.

sleep 5

#reset the VM forcefully.
echo "$(date +%x_%r) Resetting \"$vmGuest\" to begin deploy." >> $output
ssh -o ConnectTimeout=$sshTimeout $hostsystem "virsh destroy \"$vmGuest\" > /dev/null 2>&1"
ssh -o ConnectTimeout=$sshTimeout $hostsystem "virsh start \"$vmGuest\" > /dev/null 2>&1"


count=0
#Need to monitor task progress somehow. Once done, should exit.
while true; do
    if [[ "$($cwd/./getTaskStatus.sh $vmGuestFogID)" == "0" ]]; then
        echo "$(date +%x_%r) Completed image deployment to \"$vmGuest\" in about \"$count\" minutes." >> $output
        echo "Completed image deployment to \"$vmGuest\" in about \"$count\" minutes." >> $report
        exit
    else
        count=$(($count + 1))
        sleep 60
        if [[ $count -gt $deployLimit ]]; then
            echo "$(date +%x_%r) Image Capture did not complete within ${deployLimit} seconds." >> $output
            echo "Image Capture did not complete within ${deployLimit} minutes." >> $report
            break
        fi
    fi
done
nonsense=$(timeout $sshTime ssh -o ConnectTimeout=$sshTimeout $testServerSshAlias "echo wakeup")
nonsense=$(timeout $sshTime ssh -o ConnectTimeout=$sshTimeout $testServerSshAlias "echo get ready")
sleep 5
ssh -o ConnectTimeout=$sshTimeout $hostsystem "virsh destroy \"$vmGuest\" > /dev/null 2>&1

