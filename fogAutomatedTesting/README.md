### FOG Automated Testing.  Author: Wayne Workman
---


These scripts are designed to use ssh aliases with key-based authentication setup to a Linux KVM+Virsh host that is running several guest OSs for testing FOG.

All VMs should have a snapshot called "clean" where the OS is installed, updated, ssh configured, `/root/.ssh/authorized_keys` configured, ssh root login permitted, `git` installed, and the fog repository located at `/root/git/fogproject`

The scripts are designed to test all current FOG Branches. Before each round of tests, the "clean" snapshot is restored and then the OS is updated. Results are sent to a file.

All files in this directory are subject to the fog-community-scripts license.
