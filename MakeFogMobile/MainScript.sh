#!/bin/bash

# Variable definitions
## Custom configuration stuff
[[ -z $fogsettings ]] && fogsettings="/opt/fog/.fogsettings"
[[ -z $customfogsettings ]] && customfogsettings="/opt/fog/.fogsettings"
## Log to write information to
[[ -z $log ]] && log="/opt/fog/log/makeFogMobile.log"
## Storage Node Name
[[ -z $storageNode ]] && storageNode="DefaultMember"
[[ -z $database ]] && database="fog"
[[ -z $tftpfile ]] && tftpfile="/tftpboot/default.ipxe"


#---- Set Required Command Paths ----#
grep=$(command -v grep)
awk=$(command -v awk)
cut=$(command -v cut)
sed=$(command -v sed)
mysql=$(command -v mysql)
cp=$(command -v cp)
echo=$(command -v echo)
mv=$(command -v mv)
rm=$(command -v rm)
date=$(command -v date)
touch=$(command -v touch)
dirname=$(command -v dirname)
basename=$(command -v basename)

#---- Set non-required command paths ----#
ip=$(command -v ip)
systemctl=$(command -v systemctl)

# Function simply checks if the variable is defined.
# Parameter 1 is the variable to check is set.
# Parameter 2 is the message of what couldn't be found.
# Parameter 3 is the log to send information to.
checkCommand() {
    local cmd="$1"
    local msg="$2"
    local log="$3"
    if [[ -z $cmd ]]; then
        echo "The path for $msg was not found, exiting" >> $log
        exit 1
    fi
}

#---- Check command variables required ----#
checkCommand "$grep" "grep" "$log"
checkCommand "$awk" "awk" "$log"
checkCommand "$ip" "ip" "$log"
checkCommand "$sed" "sed" "$log"
checkCommand "$mysql" "mysql" "$log"
checkCommand "$cp" "cp" "$log"
checkCommand "$echo" "echo" "$log"
checkCommand "$mv" "mv" "$log"
checkCommand "$date" "date" "$log"
checkCommand "$touch" "touch" "$log"
checkCommand "$dirname" "dirname" "$log"
checkCommand "$basename" "basename" "$log"

#Record the date.
NOW=$($date '+%d/%m/%Y %H:%M:%S')
$echo ---------------------------------------------- >> $log
$echo $NOW >> $log
$echo >> $log
# Function checks if file is present.
# Parameter 1 is the file to check for
# Parameter 2 is the log to write to
checkFilePresence() {
    local file="$1"
    local log="$2"
    if [[ ! -f $file ]]; then
        $echo "The file $file does not exist, exiting" >> $log
        exit 2
    fi
}

# Check fogsettings existence
checkFilePresence "$fogsettings" "$log"
checkFilePresence "$tftpfile" "$log"

# Function checks if the variables needed are set
# Parameter 1 is the variable to test
# Parameter 2 is what the variable is testing for (msg string)
# Parameter 3 is the config file (msg string)
# Parameter 4 is the log file to write to
checkFogSettingVars() {
    local var="$1"
    local msg="$2"
    local cfg="$3"
    local log="$4"
    if [[ -z $var ]]; then
        echo "The $msg setting inside $cfg is not set, cannot continue, exiting" >> $log
        exit 3
    fi
}
. $fogsettings

# Check our required checks first
checkFogSettingVars "$interface" "interface" "$fogsettings" "$log"
checkFogSettingVars "$ipaddress" "ipaddress" "$fogsettings" "$log"

#---- Wait for an IP address ----#
while [[ -z $IP ]]; do
    ip=$($ip -4 addr show $interface | awk -F'[ /]+' '/global/ {print $3}')
    [[ -n $ip ]] && break
    $echo "The IP Address for $interface was not found, waiting 5 seconds to test again" >> $log
    sleep 5
done

# If the IP's match, exit immediately.
if [[ $ip == $ipaddress ]]; then
    $echo "The IP address found on $interface matches the IP set in $fogsettings, assuming all is good, exiting." >> $log
    exit
fi
# If the IP from fogsettings doesn't match what the system returned #
#    Make the change so system can still function #
#---- Update the IP Setting ----#
$echo "The IP Address for $interface does not match the ipaddress setting in $fogsettings, updating the IP Settings server-wide." >> $log
statement1="UPDATE \`globalSettings\` SET \`settingValue\`='$ip' WHERE \`settingKey\` IN ('FOG_TFTP_HOST','FOG_WOL_HOST','FOG_WEB_HOST');"
statement2="UPDATE \`nfsGroupMembers\` SET \`ngmHostname\`='$ip' WHERE \`ngmMemberName\`='$storageNode' OR \`ngmHostname\`='$ipaddress';"
sqlStatements="$statement1$statement2"

# Builds proper SQL Statement and runs.
# If no user defined, assume root
[[ -z $snmysqluser ]] && $snmysqluser='root'
# If no host defined, assume localhost/127.0.0.1
[[ -z $snmysqlhost ]] && $snmysqlhost='127.0.0.1'
# No password set, run statement without pass authentication
if [[ -z $snmysqlpass ]]; then
    $echo "A password was not set in $fogsettings for mysql use" >> $log
    $mysql -u"$snmysqluser" -e "$sqlStatements" "$database" 2>> $log
    # Else run with password authentication
else
    $echo "A password was set in $fogsettings for mysql use" >> $log
    $mysql -u"$snmysqluser" -p"${snmysqlpass}" -e "$sqlStatements" "$database" 2>> $log
fi

#---- Update IP address in file default.ipxe ----#
$echo "Updating the IP in $tftpfile" >> $log
$sed -i "s|http://\([^/]\+\)/|http://$ip/|" $tftpfile
$sed -i "s|http:///|http://$ip/|" $tftpfile

#---- Check docroot and webroot is set ----#
checkFogSettingVars "$docroot" "docroot" "$fogsettings" "$log"
checkFogSettingVars "$webroot" "docroot" "$fogsettings" "$log"

#---- Set config file location and check----#
configfile="${docroot}${webroot}lib/fog/config.class.php"
checkFilePresence "$configfile" "$log"

#---- Backup config.class.php ----#
$echo "Backing up $configfile" >> $log
$cp -f "$configfile" "${configfile}.old"

#---- Update IP in config.class.php ----#
$echo "Updating the IP inside $configfile" >> $log
$sed -i "s|\".*\..*\..*\..*\"|\$_SERVER['SERVER_ADDR']|" $configfile

#---- Update .fogsettings IP ----#
$echo "Updating the ipaddress field inside of $fogsettings" >> $log
$sed -i "s|ipaddress='.*'|ipaddress='$ip'|g" $fogsettings

# check if customfogsettings exists, if not, create it.
if [[ ! -f $customfogsettings ]]; then
    $echo "$customfogsettings was not found, creating it." >> $log
    $touch $customfogsettings
fi

checkFilePresence "$customfogsettings" "$log"

# Source custom fogsettings
. $customfogsettings
if [[ -z $dodnsmasq ]]; then
    $echo "The dodnsmasq setting was not found in $customfogsettings, adding it." >> $log
    # Add dodnsmasq setting
    $echo "dodnsmasq='1'" >> $customfogsettings
fi
if [[ -z $bldnsmasq ]]; then
    $echo "The bldnsmasq setting was not found in $customfogsettings, adding it." >> $log
    # Add bldnsmasq
    $echo "bldnsmasq='1'" >> $customfogsettings
fi
# Resource both settings files
. $fogsettings
. $customfogsettings

# Verify dodnsmasq and bldnsmasq are indeed set
checkFogSettingVars "$dodnsmasq" 'dodnsmasq' "$fogsettings or $customfogsettings" "$log"
checkFogSettingVars "$bldnsmasq" 'bldnsmasq' "$fogsettings or $customfogsettings" "$log"

# if bldnsmasq is on, build conf file and setup boot file.
if [[ $bldnsmasq -eq 1 ]]; then
    [[ -z $ltspfile ]] && ltspfile="/etc/dnsmasq.d/ltsp.conf"
    $echo "bldnsmasq inside $fogsettings or $customfogsettings was set to enabled, recreating $ltspfile" >> $log
    # Check ltspfile presence
    [[ ! -f $ltspfile ]] && $touch $ltspfile
    if [[ -z $bootfilename ]]; then
        $echo "The bootfilename setting in either $fogsettings or $customfogsettings is not set, setting to undionly.kkpxe" >> $log
        bootfilename="undionly.kkpxe"
    fi
    [[ -z $bootfilepath ]] && bootfilepath="/tftpboot/$bootfilename"
    bootfileCopy="${bootfilepath%.*}.0"
    if [[ -f $bootfileCopy ]]; then
        $echo "$bootfileCopy was found, deleting it." >> $log
        $rm -f $bootfileCopy
    fi
    $echo "Copying $bootfilepath to $bootfileCopy for dnsmasq to use." >> $log
    $cp $bootfilepath $bootfileCopy

    # Creating config file
    $echo "Recreating $ltspfile for use with dnsmasq." >> $log
    # backing up ltspfile
    $mv $ltspfile ${ltspfile}.backup
    $echo -e "#port=0\n\
log-dhcp\n\
tftp-root=$($dirname $bootfilepath)\n\
dhcp-boot=$($basename $bootfileCopy),$ip,$ip\n\
dhcp-option=17,$storageLocation\n\
dhcp-option=vendor:PXEClient,6,2b\n\
dhcp-no-override\n\
pxe-prompt=\"Press F8 for boot menu\",60\n\
pxe-service=X86PC,\"Boot from network\",$($basename $bootfilepath)\n\
pxe-service=X86PC,\"Boot from local hard disk\",0\n\
dhcp-range=$ip,proxy" > $ltspfile
fi
doDnsmasqService () {

local dnsmasqOn=$1
local systemctl=$(command -v systemctl)
local service=$(command -v service)

if [[ "$dnsmasqOn" -eq 0 ]]; then
    if [[ -e "$systemctl" ]]; then
        $systemctl stop dnsmasq >> $log
        $systemctl disable dnsmasq >> $log
    elif [[ -e "$service" ]]; then
        $service dnsmasq stop >> $log
        $service dnsmasq disable >> $log
    else
        echo "Could not disable dnsmasq." >> $log
    fi
elif [[ "$dnsmasqOn" -eq 1 ]]; then
    if [[ -e "$systemctl" ]]; then
        $systemctl start dnsmasq >> $log
        $systemctl enable dnsmasq >> $log
    elif [[ -e "$service" ]]; then
        $service dnsmasq start >> $log
        $service dnsmasq enable >> $log
    else
        echo "Could not enable dnsmasq." >> $log
    fi
fi
}

if [[ $dodnsmasq -eq 1 ]]; then
    $echo "dodnsmasq was enabled in either $fogsettings or $customfogsettings - starting dnsmasq/proxyDHCP and enabling to run at boot time." >> $log
    $echo "You may manually set this to 0 if you like, and manually stop/disable dnsmasq with these commands:" >> $log
    doDnsmasqService 1
    $echo "Debian/Ubuntu:" >> $log
    $echo "    service dnsmasq stop;service dnsmasq disable" >> $log
    $echo "RHEL/Fedora/CentOS:" >> $log
    $echo "    systemctl stop dnsmasq;systemctl disable dnsmasq" >> $log
else
    $echo "dodnasmasq was disabled in either $fogsettings or $customfogsettings - stopping dnsmasq/proxyDHCP and disabling boot time startup." >> $log
    $echo "You may manually set this to 1 if you like, and manually start/enable dnsmasq with these commands:" >>$ log
    doDnsmasqService 0
    $echo "Debian/Ubuntu:" >> $log
    $echo "    service dnsmasq start;service dnsmasq enable" >> $log
    $echo "RHEL/Fedora/CentOS:" >> $log
    $echo "    systemctl start dnsmasq;systemctl enable dnsmasq" >> $log
fi
