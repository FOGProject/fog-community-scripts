#!/bin/bash

#----- Settings -----#
hostID="0" # Put the host's ID here.
macToKeep="aa:bb:cc:dd:ee:ff" # Put the mac you want to keep here.




#----- Get command paths -----#
mysql=$(command -v mysql)



#----- MySQL Credentials -----#
source /opt/fog/.fogsettings



#----- Queries ------#
deleteExtraMacs="DELETE FROM hostMAC WHERE hmHostID = '${hostID}' AND hmMAC != '${macToKeep}'"



#----- Build mysql options -----#
options="-sN"
[[ $snmysqlhost != "" ]] && options="$options -h${snmysqlhost}"
[[ $snmysqluser != "" ]] && options="$options -u${snmysqluser}"
[[ $snmysqlpass != "" ]] && options="$options -p${snmysqlpass}"
options="$options -D fog -e"



#----- Execute the command -----#
$mysql $options "${deleteExtraMacs}"

# Troubleshooting line, echos the command.
# echo "$mysql $options \"${deleteExtraMacs}\""
