### Storage Node Management Tools.  Author: Wayne Workman
---


This is a collection of scripts written to ease management of many FOG Storage nodes. This script collection can manage as many Storage Nodes as you include in the settings.sh file. Output is short and simple, and gives a simple "Success" or "Failure" message for each node. If you get a failure message, the script will continue. Most scripts execute commands on all nodes in unison.

These scripts are currently geared towards Red-Hat-like systems, but can be easily modified to run against Debian-like systems, however Debian-like systems present all new issues that aren't present in Red-Hat-like systems specifically concerning remote ssh execution.

Do not use this script to update FOG on your main fog server, it must come first and therefore should be done manually.

This script collection is dependent on ssh pki authentication being setup between the system doing the updates, and makes use of aliases. You may set these things up manually, or you may use a tool I created to do this for you. Find that tool at the below link:

https://github.com/wayneworkman/ssh-pki-setup

All files in this directory are subject to the fog-community-scripts license.
