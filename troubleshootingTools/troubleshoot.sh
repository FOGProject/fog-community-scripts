#!/bin/bash
(( EUID != 0 )) && exec sudo -- "$0" "$@"
linuxReleaseName=`lsb_release -a 2> /dev/null | grep "Distributor ID" | awk '{print $3,$4,$5,$6,$7,$8,$9}' | tr -d " "`;
if [ -z "$linuxReleaseName" ]; then
	# Fall back incase lsb_release does not exist / fails - use /etc/issue over /etc/*release*
	linuxReleaseName=`cat /etc/issue /etc/*release* 2>/dev/null | head -n1 | awk '{print $1}'`;
fi
logfile="FOGtroubleshoot.log"
# Delete logfile if it exists
if [ -f $logfile ]; then
	rm $logfile
fi
#argument 1 is the logfile name
getStatus() {
	i=1;
	if [ ! -z "`echo $linuxReleaseName | grep -Ei 'Fedora|Redhat|CentOS|Mageia'`" ]; then
		RHVER=`rpm -qa | grep release | xargs rpm -q --queryformat '%{VERSION}' | cut -c -1`;
	fi
	if [ "`echo $RHVER`" -gt 6 ]; then
		services="xinetd rpcbind nfs-server vsftpd firewalld FOGMulticastManager FOGSnapinReplicator FOGImageReplicator FOGScheduler";
		nicename="TFTP RPCBind NFS FTP Firewall FOGMulticastManager FOGSnapinReplicator FOGImageReplicator FOGScheduler";
		for service in $services; do
			niceval=`echo $nicename|awk '{print $'$i'}' |sed 's/_/ /'`;
			echo "----------------------$niceval status below" >> $1
			systemctl status $service >> $1;
			i=`expr $i '+' 1`;
		done
	else
		services="xinetd rpcbind nfs vsftpd iptables FOGMulticastManager FOGSnapinReplicator FOGImageReplicator FOGScheduler";
		nicename="TFTP RPCBind NFS FTP Firewall FOGMulticastManager FOGSnapinReplicator FOGImageReplicator FOGScheduler";
		for service in $services; do
			niceval=`echo $nicename|awk '{print $'$i'}' |sed 's/_/ /'`;
			echo "----------------------$niceval status below" >> $1
			service $service status >> $1;
			i=`expr $i '+' 1`;
		done
	fi
}
#argument 1 is the logfile name
getLogs() {
	if [ ! -z "`echo $linuxReleaseName | grep -Ei 'Fedora|Redhat|CentOS|Mageia'`" ]; then
		httploc='httpd';
		httpsep='_';
	else
		httploc='apache2';
		httpsep='.';
	fi
	logs="/var/log/foginstall.log /var/log/${httploc}/error${httpsep}log /var/log/${httploc}/access${httpsep}log";
	nicename="Installation Apache_Error Apache_Access";
	i=1;
	for lfname in $logs; do
		if [ -f "$lfname" ]; then
			niceval=`echo $nicename|awk '{print $'$i'}' |sed 's/_/ /'`;
			echo ----------------------$niceval log below >> $1;
			tail -30 $lfname >> $1
		fi
		i=`expr $i '+' 1`;
	done
}
#argument 1 is the logfile name
getConfs() {
	conffiles="/etc/dhcp/dhcpd.conf /etc/dnsmasq.d/ltsp.conf /etc/xinetd.d/tftp /etc/vsftpd/vsftpd.conf /etc/rc.d/rc.local";
	for confname in $conffiles; do
		if [ -f "$confname" ]; then
			echo "----------------------$confname file below" >> $1;
			cat $confname >> $1;
		fi
	done
}
echo '----------------------'$linuxReleaseName' version below' >> $logfile
cat /etc/issue >> $logfile
if [ ! -z "`echo $linuxReleaseName | grep -Ei 'Fedora|Redhat|CentOS|Mageia'`" ]; then
	echo '----------------------SELinux status below' >> $logfile;
	sestatus >> $logfile
fi
echo '----------------------IP Configuration below' >> $logfile
ip addr >> $logfile
getStatus $logfile;
getLogs $logfile;
getConfs $logfile;
storageLocation="/images";
if [ -d "/opt/fog" -a -f "/opt/fog/.fogsettings" ]; then
	. /opt/fog/.fogsettings;
fi
if [ -d "$storageLocation" ]; then
	echo '----------------------Check for /images/.mntcheck' >> $logfile
	ls $storageLocation -a |grep "mntcheck" >> $logfile
	echo '----------------------Check for /images/dev/.mntcheck' >> $logfile
	ls ${storageLocation}/dev -a |grep "mntcheck" >> $logfile
	echo '----------------------/images & file permissions below' >> $logfile
	ls -lR $storageLocation >> $logfile
fi
if [ -d "/tftpboot" ]; then
	echo '----------------------/tftpboot & file permissions below' >> $logfile
	ls -lR /tftpboot >> $logfile
fi

#convert output file to windows friendly text.
sed -i 's/$//g' $logfile
echo -n "Script Completed ";
date
echo "Your logfile can be found in `pwd`/$logfile";
