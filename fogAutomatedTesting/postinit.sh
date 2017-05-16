#!/bin/bash

#Sourcing the functions file gives us access to all kernel variables and many neat functions.
source /usr/share/fog/lib/funcs.sh

#Mount share to /fogtesting

mkdir /fogtesting
mount -t cifs //10.0.0.25/fogtesting/$hostname /fogtesting -o username=fogtesting -o password=testing



postInitOutput="/fogtesting/postinit.log"
touch $postInitOutput

tar -zcvf postinitlogs.tar.gz /tmp/ -C /fogtesting


echo "#################### sfdisk -Fl /dev/sda" > $postInitOutput
sfdisk -Fl /dev/sda >> $postInitOutput
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

