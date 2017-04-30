#!/bin/bash


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
postDownloadOutput="/fogtesting/${hostname}_postdownload.log"


echo "#################### sfdisk -Vxl /dev/sda" > $postDownloadOutput
sfdisk -Vxl /dev/sda >> $postDownloadOutput
echo "" >> $postDownloadOutput
echo "" >> $postDownloadOutput
echo "#################### lsblk" >> $postDownloadOutput
lsblk >> $postDownloadOutput
echo "" >> $postDownloadOutput
echo "" >> $postDownloadOutput
echo "#################### blkid" >> $postDownloadOutput
blkid >> $postDownloadOutput
echo "" >> $postDownloadOutput
echo "" >> $postDownloadOutput
echo "#################### fdisk -l" >> $postDownloadOutput
fdisk -l >> $postDownloadOutput
echo "" >> $postDownloadOutput
echo "" >> $postDownloadOutput
echo "#################### pvdisplay" >> $postDownloadOutput
pvdisplay >> $postDownloadOutput
echo "" >> $postDownloadOutput
echo "" >> $postDownloadOutput
echo "#################### vgdisplay" >> $postDownloadOutput
vgdisplay >> $postDownloadOutput
echo "" >> $postDownloadOutput
echo "" >> $postDownloadOutput
echo "#################### lvdisplay" >> $postDownloadOutput
lvdisplay >> $postDownloadOutput
echo "" >> $postDownloadOutput
echo "" >> $postDownloadOutput
echo "#################### df -h" >> $postDownloadOutput
df -h >> $postDownloadOutput
echo "" >> $postDownloadOutput
echo "" >> $postDownloadOutput

