#!/bin/bash

#Get current working directory.
cwd="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

#This is a list of all storage node aliases and are space seperated. There is no limit on the number of items.
#You will need to modify the below line for any of the scripts in this directory to work.
#SSH cert-based authentication and SSH Aliases need setup between the fogTesting box and all below storageNodes.
storageNodes=( Arch CentOS7 Debian8 Debian9 Fedora25 Fedora26 Ubuntu17 Ubuntu16 Ubuntu14 )

#The name of the SSH alias for the linux KVM+libvirtd host:
hostsystem="dl580"
gitDir="/root/git"

sshTimeout=15 #seconds to wait for ssh connection to be established when running remote commands.

osTimeout="20m" #Time to wait for OS updates to complete.
fogTimeout="20m" #Time to wait for FOG installation to complete.
rebootTimeout="300" #seconds to wait for reboots to complete.
sshTime="${sshTimeout}s" #Time to wait for small SSH commands to complete.

captureLimitUnit="30"  # Time to wait for captures to complete.
captureLimit="60" #This is how long a capture has to get done measured by "captureLimitUnit".

deployLimitUnit="30" # Time to wait for deployments to complete, is seconds. #Recommended not to change this, the math is tricky.
deployLimit="180" #Measured in "deployLimitUnit" which is seconds. #Recommended not to change this, the math is tricky.

report="/root/report.txt"  #Where the short report goes.
output="/root/output.log"  #Where all output goes.
installer_dashboard="/root/installer_dashboard.html" #The dashboard file before being moved to the web directory.
imaging_dashboard="/root/imaging_dashboard.html" #The dashboard file before being moved to the web directory.
redfile="red.png"  #Red dot used for dashboard.
orangefile="orange.png"   #Orange dot used for dashboard.
greenfile="green.png"  #Green dot used for dashboard.
red="<img src=\"${redfile}\" alt=\"Failure\" title=\"Failure\">"  #HTML for using the red dot.
orange="<img src=\"${orangefile}\" alt=\"Possible issue\" title=\"Possible issue\">"   #HTML for using orange dot.
green="<img src=\"${greenfile}\" alt=\"Success\" title=\"Success\">"   #HTML for using the green dot.




webdir="/var/www/html/fog_distro_check"   #This is the web directory to put reports and file structure into.
permissions="www-data:www-data"   #What the web file's ownership should be.
domainName="theworkmans.us"   #Your domain name.
netdir="/fog_distro_check"   #This is the net directory, what gets added to the domain name to get to the webdir.
port=":20080"    #The port, if any. If default, leave blank.

#This is how you would use your Public IP instead of a domain name:
#publicIP=$(/usr/bin/curl -s http://whatismyip.akamai.com/)
#domainName=$publicIP

#The local shared directory where postinitscripts and postdownloadscripts puts stuff.
shareDir="/fogtesting"   
sharePermissions="fogtesting:fogtesting"



#These settings are for the long-standing test FOG Server. It's for testing FOG Functionality.
#SSH aliases and cert-based auth should be setup between the fogTesting box and this box.

testServerUserToken="NTZhZDlhN2M0NTcxOGE0ZTdmZGU1YTVhZGRlNzBmNDIzNTI4MTc1NjdiYWYyMzZlZWQyOTgxMWEzNzUxZjllNWVjY2NmOTUxMmEzZTMwNzkyOGJiODlkNjQ5MWUxY2E5ODkzZDFiZGUxMDFiY2IxNjJkZDhmY2NlMzdiZjA0N2Q="

testServerApiToken="M2JhM2ViZmJhZDM1MmQ1MTU4NTNjMTNmZjY4YTY3MGUxMTZmNzgyMmQxYzlhOWMwMmRjMTg0NWNmYTE4MmZiY2FkNjFjYzY1ZjY5NGQ4ZTE1Yjk4ZTg5NTQ0YTBiYmIwYzFjYmFiNTFiYzkwZTQ0YzI5MzFlNWM0NzhmMzEyNTk="

testServerVMName="testServer"
testServerIP="10.0.0.28"
testServerSshAlias="testServer"


#These are settings for a VM that will be used to test capture & deploy with, and other fog functionality.
#It uses libvirtd & KVM style snapin management, rebooting, and should be set to boot to NIC first.
#Further host testing should be done in postinitscripts and postdownloadscripts from here.
#Snapshots should be prepared with various OSs and partition layouts for testHost1.
#testHost2 should have a smaller disk, testHost3 should have a larger disk.
#Because of multiple OSs being tested with one VM, it's not yet possible to test Snapins.

testHost1VM="testHost1"
testHost1ID="1"
testHost1Disk="/data/pool0/testHost1.qcow2"

testHost1Snapshot1="win10"
testHost1ImageID="1"


testHost2VM="testHost2"
testHost2ID="2"

testHost3VM="testHost3"
testHost3ID="3"


testHostDisksDir="/data/pool0"
blankSnapshot="blank"




