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



#If repository exists, git pull. Else clone it.
if [[ -d $gitDir/fogproject ]]; then
    echo "$(date +%x_%r) Updating local fogproject repository" >> $output
    mkdir -p $gitDir/fogproject
    cd $gitDir/fogproject;git pull > /dev/null 2>&1;cd $cwd
else
    echo "$(date +%x_%r) Local fogproject repository does not exist, cloning" >> $output
    git clone https://github.com/FOGProject/fogproject.git $gitDir/fogproject > /dev/null 2>&1
fi


echo "$(date +%x_%r) Restoring base snapshots" >> $output
$cwd/./restoreSnapshots.sh clean
echo "$(date +%x_%r) Rebooting VMs." >> $output
$cwd/./rebootVMs.sh
echo "$(date +%x_%r) Updating Node OSs" >> $output
$cwd/./updateNodeOSs.sh
echo "$(date +%x_%r) Rebooting VMs." >> $output
$cwd/./rebootVMs.sh
echo "$(date +%x_%r) Creating temporary snapshots." >> $output
$cwd/./createSnapshots.sh updated
sleep 60



Yesterday=$(date -d '-1 day' +%Y-%m-%d)
Today=$(date +%Y-%m-%d)
Tomorrow=$(date -d '+1 day' +%Y-%m-%d)
branches=$(cd $gitDir/fogproject;git for-each-ref --count=10 --sort=-committerdate refs --format='%(committerdate:short)_%(refname:short)';cd $cwd)
first="yes"



#Get last x branches.
for branch in $branches; do    

    #This line is for later checking if the branch was last updated yesterday, today, or tomorrow.
    thisBranch=$branch
    #Remove everything before first "/" and including the "/" in branch name.
    branch="${branch##*/}"


    #If the three main branches were updated yesterday, today, or tomorrow, check them.
    if [[ ( *"$thisBranch"* =~ "$Yesterday" || *"$thisBranch"* =~ "$Today" || *"$thisBranch"* =~ "$Tomorrow" ) && ( "$branch" == "working" || "$branch" == "dev-branch" || "branch" == "master" ) ]]; then
        #If this is the first run, we don't need to restore the snapshot we just took. Otherwise restore snapshot.
        if [[ "$first" == "no" ]]; then
            $cwd/./restoreSnapshots.sh updated
            sleep 60
            echo "$(date +%x_%r) Rebooting VMs." >> $output
            $cwd/./rebootVMs.sh
        else
            first="no"
        fi

        echo "$(date +%x_%r) Working on branch $branch" >> $output
        $cwd/./updateNodeFOGs.sh $branch
  
    fi

done



echo "$(date +%x_%r) Deleting temprary snapshots." >> $output
$cwd/./deleteSnapshots.sh updated
echo "$(date +%x_%r) Shutting down VMs." >> $output
$cwd/./shutdownVMs.sh




mkdir -p $webdir/reports
chown -R $permissions $webdir
rightNow=$(date +%Y-%m-%d_%H-%M)
mv $output $webdir/reports/${rightNow}_install.log
chown $permissions $webdir/reports/${rightNow}_install.log


echo "Full Report: http://${domainName}${port}${netdir}/reports/${rightNow}_install.log" >> $report
cat $report | slacktee.sh -p






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
$cwd/./getTestServerReady.sh

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
    echo "$(date +%x_%r) All image deployments complete." >> $output
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










