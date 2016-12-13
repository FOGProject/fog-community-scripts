### Author: Wayne Workman
---

This script updates FOG's IP address. It is designed for manual one-and-done use. If you're looking to automate changing a FOG Server's IP address, look at the MakeFogMobile project.

How to use:

1. Update your operating system's IP Address according to your distribution's instructions.
2. Run `UpdateIP.sh`


The project should work fine on:
* Red Hat 7 
* CentOS 7
* Fedora 19+
* Ubuntu 16
* Debian 8
* Raspbian Jessie+

Supports updating all the normal places:

* `/tftpboot/default.ipxe`
* Database entries
* `config.class.php`
* `/opt/fog/.fogsettings`

Also - something new. Rebuilds DHCP Configuration from the ground-up for the new IP/network. Supports multi-nic and **multi-homed** configurations for DHCP. Supports detection/configuration for up to 4 network interfaces.

