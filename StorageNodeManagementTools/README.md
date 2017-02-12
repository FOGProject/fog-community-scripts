### Storage Node Management Tools.  Author: Wayne Workman
---


This is a collection of scripts written to ease management of many FOG Storage nodes and also some scripts to help with automated fog testing. This script collection can manage as many Storage Nodes as you include in the settings.sh file. Output is short and simple, and gives a simple "Success" or "Failure" message for each node. If you get a failure message, the script will continue. Most scripts execute commands on all nodes in unison.

These scripts are tested working on CentOS 7, Debian 8, Fedora 25, Ubuntu 14, Ubuntu 16.

Do not use this script to update FOG on your main fog server, it must come first and therefore should be done manually.

This script collection is dependent on ssh pki authentication being setup between the system doing the updates, and makes use of aliases. You may set these things up manually, or you may use a tool I created to do this for you. Find that tool at the below link:

https://github.com/wayneworkman/ssh-pki-setup

To setup the aliases and authentication manually, in your workstation home directory, create `.ssh/config` and create aliases here. Create an ssh key-pair, and place the public key on all nodes inside of `/root/.ssh/authorized_keys` There's a lot of internet documentation about creating ssh aliases and keypairs. Create the alaises exactly as the nodes are named in Virsh if you're using virsh.

All files in this directory are subject to the fog-community-scripts license.
