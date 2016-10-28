### Author: Wayne Workman
---

This small project makes FOG mobile.

With this project, you may configure hardware of your choosing to use DHCP from wherever it's hooked up. Install FOG on this sytem, then install this project. This project will detect if the mobile FOG Server's IPv4 address has changed or not. If it detects change, this project will re-configure the FOG server's IP Address and also re-configure dnsmasq in ProxyDHCP mode. This enables you to carry your mobile FOG server into any network to be plugged up and just begin imaging minutes after the server boots up without changing anything manually on the server or on the network.


The project should work fine on:
* Red Hat 7 
* CentOS 7
* Fedora 19+
* Ubuntu 16
* Debian 8
* Raspbian Jessie+


Thanks to forums.fogproject.org @sudburr for doing the initial work.
Expanded & Made better by forums.fogproject.org @Wayne-Workman
Thanks to Tom Elliott for helping with cross-platform compatibility.

Please direct inqueries about this to the fog forums.


What triggers this software to correct the FOG Server's IP address and reconfigure dnsmasq is:
If the field "ipaddress" inside of /opt/fog/.fogsettings does not match the actual IPv4 address on the local interface.

The installation script does install dnsmasq too, and adds it to FOG's packages list inside .fogsettings

The script creates a root cron event that runs the main script every 3 minutes - this is what automatically keeps the IP settings updated.

This small project and it's files and documentation are subject to the limitations of the fog community scripts license.

There are some settings that can be modified in the main script - these are towards the top of the file. An important note is that the storage node name in the script must match what the real name is in the FOG Server. The script is already set to the default value.

