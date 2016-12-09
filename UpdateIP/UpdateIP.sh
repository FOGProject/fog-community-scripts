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



## Here, there should be the same sort of menus and suggestions that the FOG installer gives.

## Is this suggested interface the right interface?

## Is this suggested IP the right IP?

## CONFIRMATION - are you sure about these changes?
#list changes.


## Do changes:







#################################################    Make the changes


#---- Update the IP Setting ----#
echo
echo "Updating the IP Settings server-wide."
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
    echo "A password was not set in $fogsettings for mysql use."
    mysql -u"$snmysqluser" -e "$sqlStatements" "$database"
    # Else run with password authentication
else
    echo "A password was set in $fogsettings for mysql use."
    mysql -u"$snmysqluser" -p"${snmysqlpass}" -e "$sqlStatements" "$database"
fi

#---- Update IP address in file default.ipxe ----#
echo "Updating the IP in $tftpfile"
sed -i "s|http://\([^/]\+\)/|http://$ip/|" $tftpfile
sed -i "s|http:///|http://$ip/|" $tftpfile

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
sed -i "s|ipaddress='.*'|ipaddress='$ip'|g" $fogsettings

# check if customfogsettings exists, if not, create it.
if [[ ! -f $customfogsettings ]]; then
    echo "$customfogsettings was not found, creating it."
    touch $customfogsettings
fi


