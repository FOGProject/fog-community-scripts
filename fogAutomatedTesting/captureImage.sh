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


#Make the hosts directory for logs on the share.
rm -rf ${shareDir}/${vmGuest}
mkdir -p ${shareDir}/${vmGuest}/screenshots
chown -R $sharePermissions $shareDir


echo "$(date +%x_%r) Restoring snapshot \"$snapshot\" to \"$vmGuest\"" >> $output
ssh -o ConnectTimeout=$sshTimeout $hostsystem "virsh snapshot-revert $vmGuest $snapshot" > /dev/null 2>&1



#Gracefully shutdown VM incase it's on.
if [[ $(ssh -o ConnectTimeout=$sshTimeout $hostsystem "virsh domstate $vmGuest") == "running" ]]; then
    echo "$(date +%x_%r) Asking \"$vmGuest\" to gracefully shutdown." >> $output
    ssh -o ConnectTimeout=$sshTimeout $hostsystem "virsh shutdown \"$vmGuest\" > /dev/null 2>&1
    sleep 30
    ssh -o ConnectTimeout=$sshTimeout $hostsystem "virsh destroy \"$vmGuest\" > /dev/null 2>&1
else
    echo "$(date +%x_%r) \"$vmGuest\" is already shutdown." >> $output
fi


echo "$(date +%x_%r) Queuing the capture job on the server." >> $output

#Queue the capture job with the test fog server.
cmd="curl --silent -k --header 'content-type: application/json' --header 'fog-user-token: ${testServerUserToken}' --header 'fog-api-token: $testServerApiToken' http://${testServerIP}/fog/host/${vmGuestFogID}/task --data '{\"taskTypeID\":2}'"
eval $cmd > /dev/null 2>&1 #Don't care that it says null.

sleep 5

#Start the VM.
echo "$(date +%x_%r) Starting up \"$testHost1VM\" for capture." >> $output
ssh -o ConnectTimeout=$sshTimeout $hostsystem "virsh start $testHost1VM" > /dev/null 2>&1

echo "$(date +%x_%r) Waiting for capture to complete..." >> $output

count=0
#Need to monitor task progress somehow.
while true; do
    nonsense=$(timeout $sshTime ssh -o ConnectTimeout=$sshTimeout $hostsystem "echo wakeup")
    nonsense=$(timeout $sshTime ssh -o ConnectTimeout=$sshTimeout $hostsystem "echo get ready")
    timeout $sshTime ssh -o ConnectTimeout=$sshTimeout $hostsystem "virsh screenshot $vmGuest /root/${vmGuest}_${count}.ppm" > /dev/null 2>&1
    timeout $sshTime scp -o ConnectTimeout=$sshTimeout $hostsystem:/root/${vmGuest}_${count}.ppm ${shareDir}/${vmGuest}/screenshots > /dev/null 2>&1
    timeout $sshTime ssh -o ConnectTimeout=$sshTimeout $hostsystem "rm -f /root/${vmGuest}_${count}.ppm" > /dev/null 2>&1

    if [[ "$(timeout $sshTimeout $cwd/./getTaskStatus.sh $vmGuestFogID)" == "0" ]]; then
        echo "$(date +%x_%r) Image capture of \"$vmGuest\" completed in about \"$(($count / 2))\" minutes." >> $output
        echo "Image capture of \"$vmGuest\" completed in about \"$(($count / 2))\" minutes." >> $report
        break
    else
        count=$(($count + 1))
        sleep $captureLimitUnit
        if [[ $count -gt $captureLimit ]]; then
            echo "$(date +%x_%r) Image capture of \"$vmGuest\" did not complete within $(($captureLimit / 2)) minutes." >> $output
            echo "Image capture of \"$vmGuest\" did not complete within $(($captureLimit / 2)) minutes." >> $report
            break
        fi
    fi
done

ssh -o ConnectTimeout=$sshTimeout $hostsystem "virsh destroy $vmGuest" > /dev/null 2>&1

#Get capture logs.
$cwd/./getImageLogs.sh $vmGuest capture

sleep 5

