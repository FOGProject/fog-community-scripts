#!/bin/bash

# This is a postinit script that mounts a remote password protected CIFS/smb share.
# It then starts and backgrounds a loop that packages up everything in /var/log to the share.
# This constant log collecting just-about ensures you will get the crash log from FOS.
# It also takes initial information about the local disks and puts that on the share.

#Sourcing the functions file gives us access to all kernel variables and many neat functions.
source /usr/share/fog/lib/funcs.sh

#Mount share to /fogtesting

mkdir /fogtesting
mount -t cifs //10.0.0.25/fogtesting/$hostname /fogtesting -o username=fogtesting -o password=testing


#Setup backgrounded loop that collects logs.
loop="/backgroundloop.sh"
echo "#!/bin/bash" > $loop
echo "while true; do" >> $loop
echo "    if [[ -f /fogtesting/var-log.tar ]]; then" >> $loop
echo "        rm -f /fogtesting/var-log.tar" >> $loop
echo "    fi" >> $loop
echo "    tar -cf /fogtesting/var-log.tar -C /var/log ." >> $loop
echo "    sleep 25" >> $loop
echo "done" >> $loop
chmod +x $loop
$loop &



postInitOutput="/fogtesting/postinit.log"
touch $postInitOutput

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
