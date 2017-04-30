#!/bin/bash

#Sourcing the functions file gives us access to all kernel variables and many neat functions.
source /usr/share/fog/lib/funcs.sh

#Getting this file from the server and then sourcing it gives us access to a wealth of variables about this host.
if [[ ! -z $mac ]]; then
    wget -q -O /tmp/hinfo.txt "http://${web}service/hostinfo.php?mac=$mac"
    if [[ -f /tmp/hinfo.txt ]]; then
        . /tmp/hinfo.txt
    fi
fi

#Map to a windows/cifs share using username and password.
mkdir /fogtesting
mount -t cifs //10.0.0.25/fogtesting /fogtesting -o username=fogtesting -o password=testing,noexec



#The below are from sourcing the funcs.sh script.
# ftp		# IP Address from Storage Management-General
# hostname	# Host Name from Host Managment-General
# img		# Image Name from Image Management-General
# mac		# Primary MAC from Image Management-General
# osid		# Host Image Index number from Image Management-General
# storage		# IP Address + Image Path from Storage Management-General
# storageip	# IP Address from Storage Management-General
# web		#IP Address + Web root from Storage Management-General

#The below are from querying the fog server.
# shutdown		# Shut down at the end of imaging
# hostdesc		#Host Description from Host Managment-General
# hostip		# IP address of the FOS client
# hostimageid		# ID of image being deployed
# hostbuilding		# Left over from very old versions of fog, not used anymore.
# hostusead		# Join Domain after image task from Host Management-Active Directory
# hostaddomain		# Domain name from Host Management-Active Directory
# hostaduser		# Domain Username from Host Management-Active Directory
# hostadou		# Organizational Unit from Host Management-Active Directory
# hostproductkey=	# Host Product Key from Host Management-Active Directory
# imagename		# Image Name from Image Management-General
# imagedesc		# Image Description from Image Management-General
# imageosid		# Operating System from Image Management-General
# imagepath		# Image Path from Image Management-General (/images/ assumed)
# primaryuser		# Primary User from Host Management-Inventory
# othertag		# Other Tag #1 User from Host Management-Inventory
# othertag1		# Other Tag #2 from Host Management-Inventory
# sysman		# System Manufacturer from Host Management-Inventory (from SMBIOS)
# sysproduct		# System Product from Host Management-Inventory (from SMBIOS)
# sysserial		# System Serial Number from Host Management-Inventory (from SMBIOS)
# mbman			# Motherboard Manufacturer from Host Management-Inventory (from SMBIOS)
# mbserial		# Motherboard Serial Number from Host Management-Inventory (from SMBIOS)
# mbasset		# Motherboard Asset Tag from Host Management-Inventory (from SMBIOS)
# mbproductname		# Motherboard Product Name from Host Management-Inventory (from SMBIOS)
# caseman		# Chassis Manufacturer from Host Management-Inventory (from SMBIOS)
# caseserial		# Chassis Serial from Host Management-Inventory (from SMBIOS)
# caseasset		# Chassis Asset from Host Management-Inventory (from SMBIOS)
# location		# Host Location (name) from Host Management-General


#Formulate filename.
postInitOutput="/fogtesting/${hostname}_postinit.log"


echo "#################### sfdisk -Vxl /dev/sda" > $postInitOutput
sfdisk -Vxl /dev/sda >> $postInitOutput
echo "" >> $postInitOutput
echo "" >> $postInitOutput
echo "#################### lsblk" >> $postInitOutput
lsblk >> $postInitOutput
echo "" >> $postInitOutput
echo "" >> $postInitOutput
echo "#################### blkid" >> $postInitOutput
blkid >> $postInitOutput
echo "" >> $postInitOutput
echo "" >> $postInitOutput
echo "#################### fdisk -l" >> $postInitOutput
fdisk -l >> $postInitOutput
echo "" >> $postInitOutput
echo "" >> $postInitOutput
echo "#################### pvdisplay" >> $postInitOutput
pvdisplay >> $postInitOutput
echo "" >> $postInitOutput
echo "" >> $postInitOutput
echo "#################### vgdisplay" >> $postInitOutput
vgdisplay >> $postInitOutput
echo "" >> $postInitOutput
echo "" >> $postInitOutput
echo "#################### lvdisplay" >> $postInitOutput
lvdisplay >> $postInitOutput
echo "" >> $postInitOutput
echo "" >> $postInitOutput
echo "#################### df -h" >> $postInitOutput
df -h >> $postInitOutput
echo "" >> $postInitOutput
echo "" >> $postInitOutput

