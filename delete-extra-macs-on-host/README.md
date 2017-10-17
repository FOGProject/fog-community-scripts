## Author: Wayne Workman

---

This is a simple BASH script that deletes all extra MACs associated with a particular host.
In the script at the top, set the hostID and MAC that you want to keep associated with that hostID. 
All other MACs associated with that hostID will be deleted.

Create a root crontab event. You will need to be root to do this.

You can switch to root with:

`sudo -i`

Then enter into root's crontab with:

`crontab -e`


Add this line to the file to run the script every minute. The path should be the path to the script.

`* * * * * /root/git/fog-community-scripts/delete-extra-macs-on-host/delete-extra-macs.sh`

Or this to run every 3 minutes:

`*/3 * * * * /root/git/fog-community-scripts/delete-extra-macs-on-host/delete-extra-macs.sh`

Or once a day:

`0 12 * * * /root/git/fog-community-scripts/delete-extra-macs-on-host/delete-extra-macs.sh`

This tool is licensed under the fog community scripts license.

