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



#Make sure test VMs are off.
#Destory test hosts.
echo "$(date +%x_%r) Making sure all testHosts are off." >> $output
nonsense=$(timeout $sshTime ssh -o ConnectTimeout=$sshTimeout $hostsystem "echo wakeup")
nonsense=$(timeout $sshTime ssh -o ConnectTimeout=$sshTimeout $hostsystem "echo get ready")
ssh -o ConnectTimeout=$sshTimeout $hostsystem "virsh destroy $testHost1VM" > /dev/null 2>&1
ssh -o ConnectTimeout=$sshTimeout $hostsystem "virsh destroy $testHost2VM" > /dev/null 2>&1
ssh -o ConnectTimeout=$sshTimeout $hostsystem "virsh destroy $testHost3VM" > /dev/null 2>&1
sleep 5


#Here, we begin testing fog functionality.
$cwd/./getTestServerReady.sh


#Push new postinit and postdownload scripts to the test server.
echo "$(date +%x_%r) Sending new post scripts to \"$testServerSshAlias\"" >> $output
nonsense=$(timeout $sshTime ssh -o ConnectTimeout=$sshTimeout $testServerSshAlias "echo wakeup")
nonsense=$(timeout $sshTime ssh -o ConnectTimeout=$sshTimeout $testServerSshAlias "echo get ready")
sleep 5
timeout $sshTime ssh -o ConnectTimeout=$sshTimeout $testServerSshAlias "rm -f /images/dev/postinitscripts/postinit.sh" > /dev/null 2>&1
timeout $sshTime scp -o ConnectTimeout=$sshTimeout $cwd/postinit.sh $testServerSshAlias:/images/dev/postinitscripts/postinit.sh > /dev/null 2>&1
timeout $sshTime ssh -o ConnectTimeout=$sshTimeout $testServerSshAlias "chmod +x /images/dev/postinitscripts/postinit.sh" > /dev/null 2>&1
timeout $sshTime ssh -o ConnectTimeout=$sshTimeout $testServerSshAlias "rm -f /images/postdownloadscripts/postdownload.sh" > /dev/null 2>&1
timeout $sshTime scp -o ConnectTimeout=$sshTimeout $cwd/postinit.sh $testServerSshAlias:/images/postdownloadscripts/postdownload.sh > /dev/null 2>&1
timeout $sshTime ssh -o ConnectTimeout=$sshTimeout $testServerSshAlias "chmod +x /images/postdownloadscripts/postdownload.sh" > /dev/null 2>&1

sleep 5

$cwd/./setTestHostImages.sh $testHost1ImageID "${testHost1ID},${testHost2ID},${testHost3ID}"
$cwd/./captureImage.sh $testHost1Snapshot1 $testHost1VM $testHost1ID

nonsense=$(timeout $sshTime ssh -o ConnectTimeout=$sshTimeout $hostsystem "echo wakeup")
nonsense=$(timeout $sshTime ssh -o ConnectTimeout=$sshTimeout $hostsystem "echo get ready")
sleep 5

#Restore blank snapshots to the three test hosts.
echo "$(date +%x_%r) Restoring snapshot \"$blankSnapshot\" to \"$testHost1VM\"" >> $output
ssh -o ConnectTimeout=$sshTimeout $hostsystem "virsh snapshot-revert $testHost1VM $blankSnapshot" > /dev/null 2>&1
sleep 5
echo "$(date +%x_%r) Restoring snapshot \"$blankSnapshot\" to \"$testHost2VM\"" >> $output
ssh -o ConnectTimeout=$sshTimeout $hostsystem "virsh snapshot-revert $testHost2VM $blankSnapshot" > /dev/null 2>&1
sleep 5
echo "$(date +%x_%r) Restoring snapshot \"$blankSnapshot\" to \"$testHost3VM\"" >> $output
ssh -o ConnectTimeout=$sshTimeout $hostsystem "virsh snapshot-revert $testHost3VM $blankSnapshot" > /dev/null 2>&1
sleep 5


$cwd/./deployImage.sh $testHost1VM $testHost1ID &
sleep 120
$cwd/./deployImage.sh $testHost2VM $testHost2ID &
sleep 120
$cwd/./deployImage.sh $testHost3VM $testHost3ID &
sleep 120


echo "$(date +%x_%r) Waiting for image deployments to complete." >> $output

count=0
#Need to monitor task progress somehow. Once done, should exit.
while true; do
    if [[ "$(timeout $sshTimeout $cwd/./getTaskStatus.sh)" == "0" ]]; then
        break
    else
        count=$(($count + 1))
        sleep 60
        if [[ $count -gt $deployLimit ]]; then
            #Kill the monitoring scripts if they are still running.
            pkill deployImage.sh
            break
        fi
    fi
done

sleep 120 #Make this value double that of the unit of measurement.
          #This is so the logs fromthe backgrounded deployImage.sh appear in the right order.

if [[ $count -gt $deployLimit ]]; then
    echo "$(date +%x_%r) All image deployments did not complete within ${deployLimit} minutes." >> $output
else
    echo "$(date +%x_%r) All image deployments complete." >> $output
fi



#Destory test hosts, shutdown test server.
echo "$(date +%x_%r) Shutting down all test hosts and test server." >> $output
nonsense=$(timeout $sshTime ssh -o ConnectTimeout=$sshTimeout $hostsystem "echo wakeup")
nonsense=$(timeout $sshTime ssh -o ConnectTimeout=$sshTimeout $hostsystem "echo get ready")
ssh -o ConnectTimeout=$sshTimeout $hostsystem "virsh destroy $testHost1VM" > /dev/null 2>&1
ssh -o ConnectTimeout=$sshTimeout $hostsystem "virsh destroy $testHost2VM" > /dev/null 2>&1
ssh -o ConnectTimeout=$sshTimeout $hostsystem "virsh destroy $testHost3VM" > /dev/null 2>&1
ssh -o ConnectTimeout=$sshTimeout $hostsystem "virsh shutdown $testServer" > /dev/null 2>&1
echo "$(date +%x_%r) Testing complete." >> $output


#Make the imaging logs available.







