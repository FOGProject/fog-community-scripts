#!/bin/bash
cwd="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PATH=/usr/local/bin:/usr/bin:/bin:/usr/local/games:/usr/games



# Automates installation of FOG.
# Arguments:
#  $1 The branch to checkout/pull from.
#  $2 ssh alias of the remote machine to use, the name.
branch=$1
name=$2
webdir=$3
statusDir=$4
now=$5


#### Settings
sshTimeout=15
fogTimeout="20m" #Time to wait for FOG installation to complete.
sshTime="${sshTimeout}s" #Time to wait for small SSH commands to complete.
#### End Settings



#Create hidden file for node - for status reporting.
echo "-1" > $statusDir/.${name}.${branch}
#Kick the tires. It helps, makes ssh load into ram, makes the switch learn where the traffic needs to go.
nonsense=$(timeout $sshTime ssh -o ConnectTimeout=$sshTimeout $name "echo wakeup")
nonsense=$(timeout $sshTime ssh -o ConnectTimeout=$sshTimeout $name "echo get ready")
#Start the installation process.
timeout $sshTime scp -o ConnectTimeout=$sshTimeout $cwd/installBranch.sh $name:/root/installBranch.sh
printf $(timeout $fogTimeout ssh -o ConnectTimeout=$sshTimeout $name "/root/./installBranch.sh $branch;echo \$?") > $statusDir/.${name}.${branch}
status=$(cat $statusDir/.${name}.${branch})
foglog=$(timeout $sshTime ssh -o ConnectTimeout=$sshTimeout $name "ls -dtr1 /root/git/fogproject/bin/error_logs/* | tail -1")
foglog_basename=$foglog
mkdir -p "$webdir/$name"
#Get fog log.
timeout $sshTime scp -o ConnectTimeout=$sshTimeout $name:$foglog $webdir/$name/${now}_installer.log > /dev/null 2>&1
#Get apache log. It can only be in one of two spots.
timeout $sshTime scp -o ConnectTimeout=$sshTimeout $name:/var/log/httpd/error_log $webdir/$name/${now}_apache.log > /dev/null 2>&1
timeout $sshTime scp -o ConnectTimeout=$sshTimeout $name:/var/log/apache2/error.log $webdir/$name/${now}_apache.log > /dev/null 2>&1
foglog=$webdir/$name/${now}_installer.log
commit=$(timeout $sshTime ssh -o ConnectTimeout=$sshTimeout $name "cd /root/git/fogproject;git rev-parse HEAD")
echo "Date=$now" > ${foglog}_new
echo "Branch=$branch" >> ${foglog}_new
echo "Commit=$commit" >> ${foglog}_new
echo "OS=$name" >> ${foglog}_new
echo "File=$foglog_basename" >> ${foglog}_new
echo "##### Begin Log#####" >> ${foglog}_new
cat $foglog >> ${foglog}_new
rm -f $foglog
mv ${foglog}_new $foglog




