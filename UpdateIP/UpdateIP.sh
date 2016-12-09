#!/bin/bash

# Variable definitions
## FOG Settings
[[ -z $fogsettings ]] && fogsettings="/opt/fog/.fogsettings"
## Storage Node Name
[[ -z $storageNode ]] && storageNode="DefaultMember"
## Database Name
[[ -z $database ]] && database="fog"
## default.ipxe location
[[ -z $tftpfile ]] && tftpfile="/tftpboot/default.ipxe"
## Get current directory
[[ -z $DIR ]] && DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"


# Parameter 1 is the file to check for
checkFilePresence() {
    local file="$1"
    if [[ ! -f $file ]]; then
        echo "The file $file does not exist, exiting."
        exit 2
    fi
}

# Check fogsettings existence
checkFilePresence "$fogsettings"
checkFilePresence "$tftpfile"

# Function checks if the variables needed are set
# Parameter 1 is the variable to test
# Parameter 2 is what the variable is testing for (msg string)
# Parameter 3 is the config file (msg string)
checkFogSettingVars() {
    local var="$1"
    local msg="$2"
    local cfg="$3"
    if [[ -z $var ]]; then
        echo "The $msg setting inside $cfg is not set, cannot continue, exiting."
        exit 3
    fi
}
## Source fogsettings file.
. $fogsettings

# Check our required checks first
checkFogSettingVars "$interface" "interface" "$fogsettings"
checkFogSettingVars "$ipaddress" "ipaddress" "$fogsettings"



## Function to find all interfaces, suggest each one, let user choose which. Supports up to 4 choices.
identifyInterfaces() {
    ##Send all ip information to temporary file.
    ip link show > $DIR/interfaces.txt
    ##Sed the 3rd, 5th, 7th, and 9th lines of output to variable.
    interface1name="$(sed -n '3p' $DIR/interfaces.txt)"
    interface2name="$(sed -n '5p' $DIR/interfaces.txt)"
    interface3name="$(sed -n '7p' $DIR/interfaces.txt)"
    interface4name="$(sed -n '9p' $DIR/interfaces.txt)"
    ##Get rid of temporary file.
    rm -f $DIR/interfaces.txt
    ##Isolate the interface names using cut and send them to temporary files.
    echo $interface1name | cut -d \: -f2 | cut -c2- > $DIR/interface1name.txt
    echo $interface2name | cut -d \: -f2 | cut -c2- > $DIR/interface2name.txt
    echo $interface3name | cut -d \: -f2 | cut -c2- > $DIR/interface3name.txt
    echo $interface4name | cut -d \: -f2 | cut -c2- > $DIR/interface4name.txt
    ##Load the names from the temporary files.
    interface1name="$(cat $DIR/interface1name.txt)"
    interface2name="$(cat $DIR/interface2name.txt)"
    interface3name="$(cat $DIR/interface3name.txt)"
    interface4name="$(cat $DIR/interface4name.txt)"
    ##Get rid of the temporary files.
    rm -f $DIR/interface1name.txt
    rm -f $DIR/interface2name.txt
    rm -f $DIR/interface3name.txt
    rm -f $DIR/interface4name.txt
    ##Parse IP addresses for each interface name.
    interface1ip="$(/sbin/ip addr show | grep $interface1name | grep -o "inet [0-9]*\.[0-9]*\.[0-9]*\.[0-9]*" | grep -o "[0-9]*\.[0-9]*\.[0-9]*\.[0-9]*")"
    interface2ip="$(/sbin/ip addr show | grep $interface2name | grep -o "inet [0-9]*\.[0-9]*\.[0-9]*\.[0-9]*" | grep -o "[0-9]*\.[0-9]*\.[0-9]*\.[0-9]*")"
    interface3ip="$(/sbin/ip addr show | grep $interface3name | grep -o "inet [0-9]*\.[0-9]*\.[0-9]*\.[0-9]*" | grep -o "[0-9]*\.[0-9]*\.[0-9]*\.[0-9]*")"
    interface4ip="$(/sbin/ip addr show | grep $interface4name | grep -o "inet [0-9]*\.[0-9]*\.[0-9]*\.[0-9]*" | grep -o "[0-9]*\.[0-9]*\.[0-9]*\.[0-9]*")"
    ##If there is no IP Address for the interfaces, assign local loopback. This means the interface doesn't exist.
    ##If only one interface has a legitimate address, don't even ask what interface to use.
    goodInterfaces="0"
    if [[ -z $interface1ip ]]; then
        interface1ip=127.0.0.1
        goodInterfaces=$(($goodInterfaces + 1))
    fi
    if [[ -z $interface2ip ]]; then 
        interface2ip=127.0.0.1
        goodInterfaces=$(($goodInterfaces + 1))
    fi
    if [[ -z $interface3ip ]]; then
        interface3ip=127.0.0.1
        goodInterfaces=$(($goodInterfaces + 1))
    fi
    if [[ -z $interface4ip ]]; then
        interface4ip=127.0.0.1
        goodInterfaces=$(($goodInterfaces + 1))
    fi

    ##Only do the menu stuff if there is more than one interface to pick from.
    if [[ "$goodInterfaces" -gt "1" ]]; then

        ##Build Menu
        MENU="Please choose which interface to use.\n\n"
        if [[ "$interface1ip" != "127.0.0.1" ]]; then
            MENU="$MENU\n    1. $interface1name currently configured with $interface1ip\n\n"
        fi
        if [[ "$interface2ip" != "127.0.0.1" ]]; then
            MENU="$MENU\n    2. $interface2name currently configured with $interface2ip\n\n"
        fi
        if [[ "$interface3ip" != "127.0.0.1" ]]; then
            MENU="$MENU\n    3. $interface3name currently configured with $interface3ip\n\n"
        fi
        if [[ "$interface4ip" != "127.0.0.1" ]]; then
            MENU="$MENU\n    4. $interface4name currently configured with $interface4ip\n\n"
        fi

        ##Print menu.
        printf "$MENU"
        printf "Selection: "
        read interfaceChoice # Assign user input to variable
        if [[ -z $interfaceChoice || ( $interfaceChoice != 1 && $interfaceChoice != 2 && $interfaceChoice != 3 && $interfaceChoice != 4 ) ]]; then
            echo Selection for interface was not valid, exiting.
            exit
        fi
        if [[ $interfaceChoice == 1 ]]; then
            newInterface="$interface1name"
            newIP="$interface1ip"
        elif [[ $interfaceChoice == 2 ]]; then
            newInterface="$interface2name"
            newIP="$interface2ip"
        elif [[ $interfaceChoice == 3 ]]; then
            newInterface="$interface3name"
            newIP="$interface3ip"
        elif [[ $interfaceChoice == 4 ]]; then
            newInterface="$interface4name"
            newIP="$interface4ip"
        fi
    else
        echo "No good interfaces found, exiting."
        exit
    fi
    return $continue
}


identifyInterfaces #Will exit on failure.


## Do changes:


#---- Update the IP Setting ----#
echo
echo "Updating the IP Settings server-wide."
statement1="UPDATE \`globalSettings\` SET \`settingValue\`='$newIP' WHERE \`settingKey\` IN ('FOG_TFTP_HOST','FOG_WOL_HOST','FOG_WEB_HOST');"
statement2="UPDATE \`nfsGroupMembers\` SET \`ngmHostname\`='$newIP' WHERE \`ngmMemberName\`='$storageNode' OR \`ngmHostname\`='$ipaddress';"
sqlStatements="$statement1$statement2"

# Builds proper SQL Statement and runs.
# If no user defined, assume root
[[ -z $snmysqluser ]] && $snmysqluser='root'
# If no host defined, assume localhost/127.0.0.1
[[ -z $snmysqlhost ]] && $snmysqlhost='127.0.0.1'
# No password set, run statement without pass authentication
if [[ -z $snmysqlpass ]]; then
    echo "A password was not set in $fogsettings for mysql use."
    mysql -u"$snmysqluser" -e "$sqlStatements" "$database"
    # Else run with password authentication
else
    echo "A password was set in $fogsettings for mysql use."
    mysql -u"$snmysqluser" -p"${snmysqlpass}" -e "$sqlStatements" "$database"
fi

#---- Update IP address in file default.ipxe ----#
echo "Updating the IP in $tftpfile"
sed -i "s|http://\([^/]\+\)/|http://$newIP/|" $tftpfile
sed -i "s|http:///|http://$newIP/|" $tftpfile

#---- Check docroot and webroot is set ----#
checkFogSettingVars "$docroot" "docroot" "$fogsettings"
checkFogSettingVars "$webroot" "docroot" "$fogsettings"

#---- Set config file location and check----#
configfile="${docroot}${webroot}lib/fog/config.class.php"
checkFilePresence "$configfile"

#---- Backup config.class.php ----#
echo "Backing up $configfile"
cp -f "$configfile" "${configfile}.old"

#---- Update IP in config.class.php ----#
echo "Updating the IP inside $configfile"
sed -i "s|\".*\..*\..*\..*\"|\$_SERVER['SERVER_ADDR']|" $configfile

#---- Update .fogsettings IP ----#
echo "Updating the ipaddress field inside of $fogsettings"
sed -i "s|ipaddress='.*'|ipaddress='$newIP'|g" $fogsettings


##Have to update/restart ISC-DHCP here if it's supposed to be built/enabled in .fogsettings.
#---- Update ISC-DHCP ----#






echo
echo "All done. Don't forget to update your DHCP/ProxyDHCP to use option 066 / filename of: $newIP"
echo

