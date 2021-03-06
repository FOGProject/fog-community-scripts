#!/bin/bash

#---- Set variables ----#

echo "Installing, please wait..."

currentDir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
utilsDir=/opt/fog/utils
targetDir=/opt/fog/utils/MakeFogMobile
fogsettings=/opt/fog/.fogsettings
packages="$(grep 'packages=' $fogsettings | cut -d \' -f2 )"

#---- Check if FOG is installed ----#

if [[ ! -f $fogsettings ]]; then
        echo "$fogsettings file not found."
        echo Please install FOG first.
        exit
fi

#---- Check if this is running as root ----*

currentUser=$(whoami)
if [[ "$currentUser" != "root" ]]; then
    echo "I am ${currentUser}, exiting."
    exit
fi



#---- Create directory and copy files ----#

#Correcting for FOG sourceforge revision 4580 where the utils directory is no longer created.
if [[ ! -d $utilsDir ]]; then
	mkdir $utilsDir
fi	


#If the target directory already exists, delete it. Then remake it.
if [[ -d $targetDir ]]; then
	rm -rf $targetDir
fi
mkdir $targetDir

cp $currentDir/README.md $targetDir/README.md
cp $currentDir/MainScript.sh $targetDir/MakeFogMobile.sh


#make the main script executable.
chmod +x $targetDir/MakeFogMobile.sh

#Check if dnsmasq is installed. If not, try to install it.

dnsmasq=$(command -v dnsmasq)

systemctl=$(command -v systemctl)
service=$(command -v service)

if [[ ! -z "$systemctl" ]]; then
    dnsmasqStatus=$(systemctl status dnsmasq >/dev/null 2>&1)
elif [[ ! -z "$service" ]]; then
    dnsmasqStatus=$(service dnsmasq status >/dev/null 2>&1)
else
    echo "Don't know how to check dnsmasq service status."
    echo "Going to try to install dnsmasq."
    dnsmasqStatus="1"
fi




if [[ -z "$dnsmasq" || "$dnsmasqStatus" != "0" ]]; then

    yum=$(command -v yum)
    dnf=$(command -v dnf)
    aptget=$(command -v apt-get)

    if [[ -e "$yum" ]]; then
        yum install dnsmasq -y >/dev/null 2>&1
    elif [[ -e "$dnf" ]]; then
        dnf install dnsmasq -y >/dev/null 2>&1
    elif [[ -e "$aptget" ]]; then
        apt-get install dnsmasq -y >/dev/null 2>&1
    else
        echo "Could not find a repo manager to install dnsmasq, quitting."
        exit 1
    fi
fi

#---- Create the cron event ----#
crontab -l -u root | grep -v PATH | crontab -u root -
newline=$PATH
(crontab -l -u root; echo "PATH=$newline") | crontab - >/dev/null 2>&1


crontab -l -u root | grep -v MakeFogMobile.sh | crontab -u root -
# */3 for every three minutes.
newline="*/3 * * * * $targetDir/MakeFogMobile.sh"
(crontab -l -u root; echo "$newline") | crontab - >/dev/null 2>&1

echo "Finished."
