#!/bin/bash
webFile="/var/www/html/nodestatus.html" #Where to put the web document.
PageAutoRefreshTime="15" #How often the web document should auto-refresh.
WaitTime="15"  #The amount of time in seconds that a node has to respond. You can use decimals, such as "0.3" or "2.5"

#-----Get command paths-----#
printf=$(command -v printf)
ping=$(command -v ping)
mysql=$(command -v mysql)
date=$(command -v date)

#----- MySQL Credentials -----#
snmysqluser=""
snmysqlpass=""
snmysqlhost=""
# If user and pass is blank, leave just a set of double quotes like ""
# if the db is local, set the host to just double quotes "" or "127.0.0.1" or "localhost"




#----- Queries ------#
getHostnames="SELECT \`ngmHostname\`, \`ngmMemberName\` FROM \`nfsGroupMembers\`"



#----- Build mysql options -----#
options="-sN"
if [[ $snmysqlhost != "" ]]; then
        options="$options -h$snmysqlhost"
fi
if [[ $snmysqluser != "" ]]; then
        options="$options -u$snmysqluser"
fi
if [[ $snmysqlpass != "" ]]; then
        options="$options -p$snmysqlpass"
fi
options="$options -D fog -e"



#------- HTML pieces ------#
htmlHead="<!DOCTYPE html>\n<html>\n<HEAD>\n<META HTTP-EQUIV="refresh" CONTENT="$PageAutoRefreshTime">\n<TITLE>\nNode Status\n</TITLE>\n</HEAD>\n<body>\n"
htmlHeading="<h1>FOG Storage Node Status</h1>\n<br>\n"
waitMessage="<br>\nCurrent Wait Time for ping response is set to $WaitTime seconds.\n<br>\n<br>\n"
online="<font color=\"green\">Online!</font>\n<br>\n"
offline="<font color=\"red\">Offline!</font>\n<br>\n"
rightNow="<pre>Last Updated: $( $date )</pre>\n"
htmlFoot="</body>\n</html>\n"


#---- Start wring html doc, header and other info. ------#

$printf "$htmlHead" > $webFile
$printf "$htmlHeading" >> $webFile
$printf "$waitMessage" >> $webFile
$printf "$rightNow" >> $webFile


#query database for list of nodes and names, loop through each.
$mysql $options "$getHostnames" | while read ngmHostname ngmMemberName; do
    #Ping each one.
    $ping -i $WaitTime -c 1 $ngmHostname > /dev/null 2>&1
    if [[ $? -eq 0 ]]; then
        #if ping succeeds, it's online.
        $printf "$ngmMemberName is $online" >> $webFile
    else
        #if ping fails, it's offline.
        $printf "$ngmMemberName is $offline" >> $webFile
    fi
#end loop
done
#write footer.
$printf "$htmlFoot" >> $webFile


