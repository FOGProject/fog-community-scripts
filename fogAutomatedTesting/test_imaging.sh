#!/bin/bash
cwd="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$cwd/settings.sh"


#Ensure jq is installed.
if [[ -z $(command -v jq) ]]; then
    if [[ ! -z $(command -v dnf) ]]; then
        dnf -y install jq > /dev/null 2>&1
    elif [[ ! -z $(command -v yum) ]]; then
        yum -y install jq > /dev/null 2>&1
    elif [[ ! -z $(command -v apt-get) ]]; then
        apt-get -y install jq > /dev/null 2>&1
    elif [[ ! -z $(command -v pacman) ]]; then
        pacman --noconfirm --sync jq > /dev/null 2>&1
    else
        echo "Don't know how to install jq, please install it first."
        exit 1
    fi	
fi

#If an old report exists here, delete it.
if [[ -f $report ]]; then
    rm -f $report
fi

#If old output file exists, delete it.
if [[ -f $output ]]; then
    rm -f $output
fi

#Make needed directories.
mkdir -p ${webdir}/${testHost1VM}
mkdir -p ${webdir}/${testHost2VM}
mkdir -p ${webdir}/${testHost3VM}


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
#$cwd/./getTestServerReady.sh

#Clear all existing tasks on test server.
$cwd/./cancelTasks.sh

#Set host images.
$cwd/./setTestHostImages.sh $testHost1ImageID "${testHost1ID},${testHost2ID},${testHost3ID}"

#Capture.
$cwd/./captureImage.sh $testHost1Snapshot1 $testHost1VM $testHost1ID

#Restore blank snapshots to the three test hosts.
nonsense=$(timeout $sshTime ssh -o ConnectTimeout=$sshTimeout $hostsystem "echo wakeup")
nonsense=$(timeout $sshTime ssh -o ConnectTimeout=$sshTimeout $hostsystem "echo get ready")
sleep 5
echo "$(date +%x_%r) Restoring snapshot \"$blankSnapshot\" to \"$testHost1VM\"" >> $output
ssh -o ConnectTimeout=$sshTimeout $hostsystem "virsh snapshot-revert $testHost1VM $blankSnapshot" > /dev/null 2>&1
sleep 5
echo "$(date +%x_%r) Restoring snapshot \"$blankSnapshot\" to \"$testHost2VM\"" >> $output
ssh -o ConnectTimeout=$sshTimeout $hostsystem "virsh snapshot-revert $testHost2VM $blankSnapshot" > /dev/null 2>&1
sleep 5
echo "$(date +%x_%r) Restoring snapshot \"$blankSnapshot\" to \"$testHost3VM\"" >> $output
ssh -o ConnectTimeout=$sshTimeout $hostsystem "virsh snapshot-revert $testHost3VM $blankSnapshot" > /dev/null 2>&1
sleep 5


#Deploy image to the three test hosts with two minutes between each to allow for proper queuing. 
$cwd/./deployImage.sh $testHost1VM $testHost1ID &
sleep 60
$cwd/./deployImage.sh $testHost2VM $testHost2ID &
sleep 60
$cwd/./deployImage.sh $testHost3VM $testHost3ID &
sleep 60


echo "$(date +%x_%r) Waiting for image deployments to complete." >> $output

count=6
#Need to monitor task progress somehow. Once done, should exit.
while true; do
    if [[ "$(timeout $sshTimeout $cwd/./getTaskStatus.sh)" == "0" ]]; then
        break
    else
        count=$(($count + 1))
        sleep $deployLimitUnit
        if [[ $count -gt $deployLimit ]]; then
            #Kill the monitoring scripts if they are still running.
            pkill deployImage.sh
            break
        fi
    fi
done

sleep $(( $deployLimitUnit * 2 )) #Make this value double that of the unit of measurement.
          #This is so the logs from the backgrounded deployImage.sh appear in the right order.

if [[ $count -gt $deployLimit ]]; then
    echo "$(date +%x_%r) All image deployments did not complete within ${deployLimit} minutes." >> $output
else
    echo "$(date +%x_%r) All image deployments completed in about \"$((count / 2))\" minutes." >> $output
    echo "All image deployments completed in about \"$((count / 2))\" minutes." >> $report
fi


#Clear all existing tasks on test server.
$cwd/./cancelTasks.sh

#Destory test hosts, shutdown test server.
echo "$(date +%x_%r) Shutting down all test hosts and test server." >> $output
nonsense=$(timeout $sshTime ssh -o ConnectTimeout=$sshTimeout $hostsystem "echo wakeup")
nonsense=$(timeout $sshTime ssh -o ConnectTimeout=$sshTimeout $hostsystem "echo get ready")
ssh -o ConnectTimeout=$sshTimeout $hostsystem "virsh destroy $testHost1VM" > /dev/null 2>&1
ssh -o ConnectTimeout=$sshTimeout $hostsystem "virsh destroy $testHost2VM" > /dev/null 2>&1
ssh -o ConnectTimeout=$sshTimeout $hostsystem "virsh destroy $testHost3VM" > /dev/null 2>&1
ssh -o ConnectTimeout=$sshTimeout $hostsystem "virsh shutdown $testServer" > /dev/null 2>&1


#Make the imaging logs available.
$cwd/./getImageLogs.sh $testHost1VM deploy
$cwd/./getImageLogs.sh $testHost2VM deploy
$cwd/./getImageLogs.sh $testHost3VM deploy


echo "$(date +%x_%r) Testing complete." >> $output

mkdir -p $webdir/reports
chown -R $permissions $webdir
rightNow=$(date +%Y-%m-%d_%H-%M)
mv $output $webdir/reports/${rightNow}_image.log
chown $permissions $webdir/reports/${rightNow}_image.log


echo "Full Report: http://${domainName}${port}${netdir}/reports/${rightNow}_image.log" >> $report
cat $report | slacktee.sh -p

