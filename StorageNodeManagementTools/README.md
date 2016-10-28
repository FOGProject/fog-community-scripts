### Storage Node Management Tools.  Author: Wayne Workman
---


This is a collection of scripts written to ease management of many FOG Storage nodes. This script collection can manage as many Storage Nodes as you include in the storageNodes.sh file. Output is short and simple, and gives a simple "Success" or "Failure" message for each node. If you get a failure message, you would let the script continue if other nodes are succeeding, and use another ssh session to work on the failed node.

If you use this script to also update the main fog server - the main fog server MUST come first in the storageNodes.sh file.

This script collection is dependent on ssh pki authentication being setup between the system doing the updates, and makes use of aliases. You may set these things up manually, or you may use a tool I created to do this for you. Find that tool at the below link:

https://github.com/wayneworkman/ssh-pki-setup

All files in this directory are subject to the fog-community-scripts license.
