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



Yesterday=$(date -d '-1 day' +%Y-%m-%d)
Today=$(date +%Y-%m-%d)
Tomorrow=$(date -d '+1 day' +%Y-%m-%d)
branches=$(cd $gitDir/fogproject;git branch -r | grep -v HEAD;cd $cwd)
first="yes"



#Get last x branches.
for branch in $branches; do    

    #This line is for later checking if the branch was last updated yesterday, today, or tomorrow.
    thisBranch=$(echo -e $(git show --format="%ci" $branch | head -n 1) \\t$branch)
    #Remove everything before first "/" and including the "/" in branch name.
    branch="${branch##*/}"

    #We want to do the latest working branch every single day.
    if [[ "$branch" == *"working"* ]]; then
        #If this is the first run, we don't need to restore the snapshot we just took. Otherwise restore snapshot.
        if [[ "$first" == "no" ]]; then
            $cwd/./restoreSnapshots.sh updated
            sleep 60
        else
            first="no"
        fi

        echo "Working on branch $branch"
        $cwd/./updateNodeFOGs.sh $branch

    #If other branches were updated yesterday, today, or tomorrow, check them too.
    elif [[ ( *"$thisBranch"* =~ "$Yesterday" || *"$thisBranch"* =~ "$Today" || *"$thisBranch"* =~ "$Tomorrow" ) && ( "$branch" == "dev-branch" || "branch" == "master" ) ]]; then
        #If this is the first run, we don't need to restore the snapshot we just took. Otherwise restore snapshot.
        if [[ "$first" == "no" ]]; then
            $cwd/./restoreSnapshots.sh updated
            sleep 60
        else
            first="no"
        fi

        echo "Working on branch $branch"
        $cwd/./updateNodeFOGs.sh $branch
  
    #If nothing matches, just continue through the loop.
    else
        continue
    fi

done




mkdir -p /var/www/html/fog_distro_check/reports
chown -R apache:apache /var/www/html/fog_distro_check
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
