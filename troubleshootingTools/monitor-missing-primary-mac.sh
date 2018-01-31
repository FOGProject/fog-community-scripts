#!/bin/bash
webFile="/var/www/html/nodestatus.html" #Where to put the web document.
PageAutoRefreshTime="15" #How often the web document should auto-refresh.
WaitTime="15"  #The amount of time in seconds that a node has to respond. You can use decimals, such as "0.3" or "2.5"

#-----Get command paths-----#
printf=$(command -v printf)
ping=$(command -v ping)
mysql=$(command -v mysql)
date=$(command -v date)
echo=$(command -v echo)
tail=$(command -v tail)

log="/root/troubleshooting.log"


# If the troubleshooting log exists, this means we caught what we wanted so exit.
if [[ -f $log ]]; then
    exit
fi



# Source the fogsettings file to get mysql credentials.
source /opt/fog/.fogsettings


#----- Queries ------#

# Any queries you want to monitor would go here. Just make a new SQL query and assign it to a new variable.

# This query tests for hosts that do not have a primary MAC address set.
getHostsWithMissingPrimaryMac="SELECT hostID FROM hosts WHERE hostID NOT IN (SELECT hmHostID FROM hostMAC WHERE hmPrimary = '1');"
getHostsWithMissingPrimaryMacCount="SELECT COUNT(hostID) FROM hosts WHERE hostID NOT IN (SELECT hmHostID FROM hostMAC WHERE hmPrimary = '1');"
getLast50historyEntries="SELECT hText,hUser,hTime,hIP FROM history ORDER BY hTime DESC LIMIT 50;"


#----- Build mysql options -----#
options="-sN"
if [[ "$snmysqlhost" != "" ]]; then
        options="$options -h$snmysqlhost"
fi
if [[ "$snmysqluser" != "" ]]; then
        options="$options -u$snmysqluser"
fi
if [[ "$snmysqlpass" != "" ]]; then
        options="$options -p$snmysqlpass"
fi
options="$options -D fog -e"



# To iterate through multiple fields in a return, do something like this as an example:
# $mysql $options "$getHostnames" | while read hostID hostName; do


count=$($mysql $options "$getHostsWithMissingPrimaryMacCount")

if [[ "$count" == "0" ]]; then
    exit
fi

echo "Date & time: $($date)" >> $log

$mysql $options "$getHostsWithMissingPrimaryMac" | while read hostID; do
    # Write out a log file saying which hosts
    echo "Found hostID '$hostID' without a primary MAC." >> $log
#end loop
done

if [[ -d "/var/log/httpd" ]]; then
    echo "################################################" >> $log
    echo "Apache error log" >> $log
    echo "################################################" >> $log
    $tail -n 100 /var/log/httpd/error_log >> $log
    echo "################################################" >> $log
    echo "Apache access log" >> $log
    echo "################################################" >> $log
    $tail -n 100 /var/log/httpd/access_log >> $log
fi
if [[ -d "/var/log/apache2" ]]; then
    echo "################################################" >> $log
    echo "Apache error log" >> $log
    echo "################################################" >> $log
    $tail -n 100 /var/log/apache2/error.log >> $log
    echo "################################################" >> $log
    echo "Apache access log" >> $log
    echo "################################################" >> $log
    $tail -n 100 /var/log/apache2/access.log >> $log
fi



echo "################################################" >> $log
echo "Last 50 history events" >> $log
echo "################################################" >> $log

echo "hText,hUser,hTime,hIP" >> $log
$mysql $options "$getHostsWithMissingPrimaryMac" | while read hText hUser hTime hIP; do
    echo "$hText,$hUser,$hTime,$hIP" >> $log
done



