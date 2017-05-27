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

#If old dashboard file exists, delete it.
if [[ -f $installer_dashboard ]]; then
    rm -f $installer_dashboard
fi





#Setup html header and style and stuff.
echo '<!DOCTYPE html>' >> $installer_dashboard
echo '<html>' >> $installer_dashboard
echo '<head>' >> $installer_dashboard
echo '<title>FOG Installer Dashboard</title>' >> $installer_dashboard
echo '<style>' >> $installer_dashboard
echo 'table {' >> $installer_dashboard
echo '    width:100%;' >> $installer_dashboard
echo '}' >> $installer_dashboard
echo 'table, th, td {' >> $installer_dashboard
echo '    border: 1px solid black;' >> $installer_dashboard
echo '    border-collapse: collapse;' >> $installer_dashboard
echo '}' >> $installer_dashboard
echo 'th, td {' >> $installer_dashboard
echo '    padding: 5px;' >> $installer_dashboard
echo '    text-align: left;' >> $installer_dashboard
echo '}' >> $installer_dashboard
echo 'tr:hover{background-color:#f5f5f5}' >> $installer_dashboard
echo 'th {' >> $installer_dashboard
echo '    background-color: #4CAF50;' >> $installer_dashboard
echo '    color: white;' >> $installer_dashboard
echo '}' >> $installer_dashboard

echo '</style>' >> $installer_dashboard
echo '</head>' >> $installer_dashboard
echo '<body>' >> $installer_dashboard
echo '<h1>FOG Installer Dashboard</h1><br><br><br>' >> $installer_dashboard




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
    if [[ ( *"$thisBranch"* =~ "$Yesterday" || *"$thisBranch"* =~ "$Today" || *"$thisBranch"* =~ "$Tomorrow" ) && ( "$branch" == "working" || "$branch" == "dev-branch" || "$branch" == "master" ) ]]; then
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


echo "<br>Full Report: http://${domainName}${port}${netdir}/reports/${rightNow}_install.log<br><br><br>" >> $installer_dashboard
#Close the html document.
echo '</body>' >> $installer_dashboard
echo '</html>' >> $installer_dashboard

#Replace red, orange, and green if they exist.
if [[ -e ${webdir}/${redfile} ]]; then
    rm -f ${webdir}/${redfile}
fi
cp ${cwd}/${redfile} ${webdir}/${redfile}
chown $permissions ${webdir}/${redfile}
if [[ -e ${webdir}/${orangefile} ]]; then
    rm -f ${webdir}/${orangefile}
fi
cp ${cwd}/${orangefile} ${webdir}/${orangefile}
chown $permissions ${webdir}/${orangefile}
if [[ -e ${webdir}/${greenfile} ]]; then
    rm -f ${webdir}/${greenfile}
fi
cp ${cwd}/${orangefile} ${webdir}/${greenfile}
chown $permissions ${webdir}/${greenfile}


if [[ -e $webdir/installer_dashboard.html ]]; then
    rm -f $webdir/installer_dashboard.html
fi
mv $installer_dashboard $webdir/installer_dashboard.html
chown $permissions $webdir/installer_dashboard.html

echo "Full Report: http://${domainName}${port}${netdir}/reports/${rightNow}_install.log" >> $report
cat $report | slacktee.sh -p

