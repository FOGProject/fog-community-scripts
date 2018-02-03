### Delete all network printers. Author: Wayne Workman.
---

This powershell script will delete all network printers installed locally
that begin with the address '10.' and will delete all printer ports that
begin with the address '10.'

When a fog network printer is deployed with incorrect settings, or when
it's deployed successfully and the end-user renames it or deletes it,
the printer goes into this weird state where the user cannot use it,
it does not show in 'Devices and Printers', but the fog client and the
fog client helper say that it's already installed. When this happens,
you can use this script to delete all network printers installed locally.
Beware, all this script does is delete network printers. It does not
re-add them. If all of your printers are configured correctly via FOG,
after this script completes the FOG Client will add all printers back.
This script can be deployed manually on an as-needed basis or via 
a snapin as needed.

This utility is subject to the fog-community-scripts license.

