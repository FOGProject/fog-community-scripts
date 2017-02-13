#!/bin/bash

#Get current working directory.
cwd="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

#This is a list of all storage node aliases and are space seperated. There is no limit on the number of items.
#You will need to modify the below line for any of the scripts in this directory to work.
#storageNodes=( fogsite1 fogsite2 downtown uptown dallas houston floor1 floor2 japan uk )
storageNodes=( box1 box2 box3 box4 )

#The name of the linux KVM+libvirtd host and is only used for the snapshot related scripts:
hostsystem="hostname"
snapshotName="clean"


report="${cwd}/report.txt"

sshTimeout=5 #seconds to wait for ssh connection to be established when running remote commands.


