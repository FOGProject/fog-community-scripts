#!/bin/bash
cwd="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$cwd/settings.sh"
echo " " > $report



#If repository exists, git pull. Else clone it.
if [[ -d $gitDir/fogproject ]]; then
    echo "Directory exists, updating fogproject"
    mkdir -p $gitDir/fogproject
    cd $gitDir/fogproject;git pull;cd $cwd
else
    echo "Directory does not exist, cloning"
    git clone https://github.com/FOGProject/fogproject.git $gitDir/fogproject
fi

didMaster="no"
didDev="no"

echo "Restoring base snapshots"
$cwd/./restoreSnapshots.sh clean
echo "Rebooting VMs."
$cwd/./rebootVMs.sh
echo "Updating Node OSs"
$cwd/./updateNodeOSs.sh
echo "Rebooting VMs."
$cwd/./rebootVMs.sh
echo "Creating temporary snapshots."
$cwd/./createSnapshots.sh updated
sleep 60


first="yes"

branches=$(cd $gitDir/fogproject;git for-each-ref --count=1 --sort=-committerdate --format='%(refname:short)';cd $cwd)

#Get last x branches.
for branch in $branches; do 


    #Remove everything before first "/" in branch name.
    branch="${branch##*/}"
    echo "Working on branch $branch"
    if [[ "$branch" == "master" ]]; then
        didMaster="yes"
    fi
    if [[ "$branch" == "dev-branch" ]]; then
        didDev="yes"
    fi
    if [[ "$first" == "no" ]]; then
        $cwd/./restoreSnapshots.sh updated
    else
        first="no"
    fi
    sleep 60
    $cwd/./updateNodeFOGs.sh $branch
done

if [[ "$didMaster" == "no" ]]; then
    branch="master"
    echo "Working on branch $branch"
    $cwd/./restoreSnapshots.sh updated
    sleep 60
    $cwd/./updateNodeFOGs.sh $branch
fi

if [[ "$didDev" == "no" ]]; then
    branch="dev-branch"
    echo "Working on branch $branch"
    $cwd/./restoreSnapshots.sh updated
    sleep 60
    $cwd/./updateNodeFOGs.sh $branch
fi


mkdir -p /var/www/html/fog_distro_check/reports
chown apache:apache /var/www/html/fog_distro_check/reports
rightNow=$(date +%Y-%m-%d_%H-%M)
mv $report /var/www/html/fog_distro_check/reports/${rightNow}.log
chown apache:apache /var/www/html/fog_distro_check/reports/${rightNow}.log
publicIP=$(/usr/bin/curl -s http://whatismyip.akamai.com/)
echo "New report available: http://$publicIP:20080/fog_distro_check/reports/${rightNow}.log" | slacktee.sh -p
cat /var/www/html/fog_distro_check/reports/${rightNow}.log | slacktee.sh -p


echo "Deleting temprary snapshots."
$cwd/./deleteSnapshots.sh updated
echo "Shutting down VMs."
$cwd/./shutdownVMs.sh
