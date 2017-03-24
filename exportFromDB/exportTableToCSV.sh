#!/bin/bash

snmysqluser='fogstorage'
snmysqlpass='something' #The fogstorage pass goes here, git it from Web Interface -> FOG Configuration -> FOG Settings -> FOG Storage Nodes
snmysqlhost='10.0.0.2' #Put your FOG Server's FQDN or IP here.
database="fog"
table="inventory"
header=""
csvFile="/root/output.csv"
mysql=$(command -v mysql) #Get absolute path of mysql command.
sed=$(command -v sed) #Get absolute path of sed.
echo=$(command -v echo) #Get absolute path of echo.


#Get the headers.
$mysql -sN -u $snmysqluser -h $snmysqlhost -D $database -p${snmysqlpass} -e "SELECT COLUMN_NAME FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_SCHEMA=\"$database\" AND TABLE_NAME=\"$table\"" | $sed 's/\x09/,/g' | while read field;
do

    if [[ -z $header ]]; then
        header="${field}"
    else
        header="${header},${field}"
    fi
    echo "$header" > $csvFile
done



#Get the rows, convert to comma seperated, read line by line.
$mysql -sN -u $snmysqluser -h $snmysqlhost -D $database -p${snmysqlpass} -e "SELECT * FROM $table" | $sed 's/\x09/,/g' | while read line;
do
    echo "$line" >> $csvFile
done

