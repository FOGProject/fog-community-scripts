### Monitor FOG Storage Nodes
## Author: Wayne Workman

---

This is a simple BASH script that aids in monitoring the online/offline status of many storage nodes.


Place the MonitorNodes.sh file onto your main fog server.
Leaving it in the cloned git repo is fine.


Create a root crontab event. You will need to be root to do this.
You can switch to root with:

`sudo -i`

Then enter into root's crontab with:

`crontab -e`


Add this line to the file to run the script every minute.

`* * * * * /root/MonitorNodes.sh`

Or this to run every 3 minutes:

`*/3 * * * * /root/MonitorNodes.sh`

The script will ping all fog storage nodes.
If they respond within the defined WaitTime, they are marked as enabled in the DB.
If they do not respond within the defined WaitTime, they are marked as disabled in the DB.

Also, a simple web report is generated that lists all storage node status.
You can view it by navigating to the below address, where x.x.x.x is your main fog server's IP.

`x.x.x.x\nodestatus.html`

This tool is licensed under the fog community scripts license.

