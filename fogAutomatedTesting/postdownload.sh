#!/bin/bash

#Formulate filename.
postDownloadOutput="/fogtesting/postdownload.log"
touch $postDownloadOutput

tar -zcvf postdownloadlogs.tar.gz /tmp/ -C /fogtesting

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
echo "#################### df -h" >> $postDownloadOutput
df -h >> $postDownloadOutput
echo "" >> $postDownloadOutput
echo "" >> $postDownloadOutput


