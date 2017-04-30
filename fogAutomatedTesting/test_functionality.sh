#!/bin/bash
cwd="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$cwd/settings.sh"

#If an old report exists here, delete it.
if [[ -f $report ]]; then
    rm -f $report
fi

#If old output file exists, delete it.
if [[ -f $output ]]; then
    rm -f $output
fi


#Here, we begin testing fog functionality.

echo "getTestServerReady.sh"
$cwd/./getTestServerReady.sh
$cwd/./setTestHostImages.sh $testHost1ImageID "${testHost1ID},${testHost2ID},${testHost3ID}"
$cwd/./captureImage.sh $testHost1Snapshot1 $testHost1VM $testHost1ID

sleep 5

#Restore blank snapshots to the three test hosts.
ssh -o ConnectTimeout=$sshTimeout $hostsystem "virsh snapshot-revert $testHost1VM $blankSnapshot" > /dev/null 2>&1"
ssh -o ConnectTimeout=$sshTimeout $hostsystem "virsh snapshot-revert $testHost2VM $blankSnapshot" > /dev/null 2>&1"
ssh -o ConnectTimeout=$sshTimeout $hostsystem "virsh snapshot-revert $testHost3VM $blankSnapshot" > /dev/null 2>&1"

sleep 5

$cwd/./deployImage.sh $testHost2VM $testHost2ID &

#Small delay here to give the queuing system the best chance at actually queuing.
sleep 10

$cwd/./deployImage.sh $testHost3VM $testHost3ID &

echo "$(date +%x_%r) Waiting for image deployments to complete..." >> $output

count=0
#Need to monitor task progress somehow. Once done, should exit.
while true; do
    if [[ "$($cwd/./getTaskStatus.sh)" == "0" ]]; then
        echo "$(date +%x_%r) Image deployments complete." >> $output
        exit
    else
        count=$(($count + 1))
        sleep 60
        if [[ $count -gt $deployLimit ]]; then
            echo "$(date +%x_%r) Image deployments did not complete within ${deployLimit} minutes." >> $output
            break
        fi
    fi
done

echo "$(date +%x_%r) Shutting down all test hosts and test server." >> $output
#Destory test hosts, shutdown test server.
ssh -o ConnectTimeout=$sshTimeout $hostsystem "virsh destroy $testHost1VM" > /dev/null 2>&1"
ssh -o ConnectTimeout=$sshTimeout $hostsystem "virsh destroy $testHost2VM" > /dev/null 2>&1"
ssh -o ConnectTimeout=$sshTimeout $hostsystem "virsh destroy $testHost3VM" > /dev/null 2>&1"
ssh -o ConnectTimeout=$sshTimeout $hostsystem "virsh shutdown $testServer" > /dev/null 2>&1"


