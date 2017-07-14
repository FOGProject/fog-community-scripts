#!/bin/bash

# This is a postdownload script that just gathers some information about the local disks.
# It puts this information onto a mounted share that the postinit should have accomplished.

#Formulate filename.
postDownloadOutput="/fogtesting/postdownload.log"
touch $postDownloadOutput


echo "#################### sfdisk -Fl /dev/sda" > $postDownloadOutput
sfdisk -Fl /dev/sda >> $postDownloadOutput
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
