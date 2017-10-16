#!/bin/bash

hostID = "0" # Put the host's ID here.
macToKeep = "aa:bb:cc:dd:ee:ff" # Put the mac you want to keep here.


#-----Get command paths-----#
mysql=$(command -v mysql)

#----- MySQL Credentials -----#
source /opt/fog/.fogsettings



#----- Queries ------#
deleteExtraMacs="SELECT \`ngmHostname\`, \`ngmMemberName\` FROM \`nfsGroupMembers\`"



#----- Build mysql options -----#
options="-sN"
if [[$snmysqlhost != ""]]; then
        options="$options -h$snmysqlhost"
fi
if [[$snmysqluser != ""]]; then
        options="$options -u$snmysqluser"
fi
if [[$snmysqlpass != ""]]; then
        options="$options -p$snmysqlpass"
fi
options="$options -D fog -e"



#Execute the command.
$mysql $options "$deleteExtraMacs"


