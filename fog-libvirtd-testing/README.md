### FOG Automated Testing.  Author: Wayne Workman
---


These scripts are designed to use ssh aliases with key-based authentication setup to a Linux KVM+Virsh host that is running several guest OSs for testing FOG.

All VMs should have a snapshot called "clean" where the OS is installed, updated, ssh configured, `/root/.ssh/authorized_keys` configured, ssh root login permitted, `git` installed, and the fog repository located at `/root/git/fogproject`

The scripts are designed to test all current FOG Branches. Before each round of tests, the "clean" snapshot is restored and then the OS is updated. Results are sent to a file.

This project makes use of slacktee, an opensource tool that simplifies sending messages to slack.
Project home page: https://github.com/course-hero/slacktee
Fork: https://github.com/wayneworkman/slacktee


File descriptions:

* `settings.sh` Where all settings go. 
** storageNodes are the alias names that must be configured in the controlling sever's `/root/.ssh/config` file, and ssh certificate-based authentication to the remote boxes root must be setup prior. 
** hostsystem is the VM host that runs `libvirtd`, the open source package that helps manage Linux KVM VM guests. 
** gitDir is the universal git directory on all boxes including the controlling one. 
** osTimeout is the length of time alloted for OS updates to happen in.
** fogTimeout is the alloted amount of time for the FOG installer to complete before being left behind.
** sshTime is used for small ssh commands, it's an extra timeout on top of the built-in ssh timeout.
** report is where all the important results are stored.
** output is where more (and less important) results are stored - mostly for the admin to know where in the process the script is at.

* `createSnapshots.sh` Creates snapshots of all nodes on the VM host using the specified name. If a snapshot already exists with this name, it's deleted.

* `customCommand.sh` A utility script that can be used to get things straightened out on all the nodes at once.

* `deleteSnapshot.sh` Deletes specified snapshot.

* `installBranch.sh` Installs the specified branch. This file gets sent via SCP by `updateNodeFOGs.sh` and runs locally on the remote nodes, and returns altered exit codes to specify where a failure happened.

* `rebootVMs.sh` the reliable way of rebooting all of the nodes.

* `test_all.sh` The primary script. This is what you initiate to do a complete run.

* `updateNodeFOGs.sh` this script pushes out `installBranch.sh` to all nodes and then tells it to run, it waits for the return code. On failure, it attempts to gather logs from the broken box.

* `updateNodeOSs.sh` updates all node's OS.


All files in this directory are subject to the fog-community-scripts license.
