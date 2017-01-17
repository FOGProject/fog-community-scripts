#!/bin/bash

#----- MySQL Credentials -----#
#Fog settings file.
fogsettings="/opt/fog/.fogsettings"
#If fogsettings exists, source it.
if [[ -e "$fogsettings" ]]; then
    source $fogsettings
else
    echo "The file $fogsettings was not found, this script needs that file. Is FOG installed?"
    exit
fi




#----- Begin Program -----#


#These are the static queries that are used for information gathering.
selectAllSnapinIDs="SELECT sID FROM snapins ORDER BY sID"
selectLowestSnapinID="SELECT sID FROM snapins ORDER BY sID ASC LIMIT 1"
selectHighestSnapinID="SELECT sID FROM snapins ORDER BY sID DESC LIMIT 1"

#Here we build the mysql options properly based on what's set inside of the fogsettings file that we sourced earlier.
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

#Information gathering.
lowestID=$(mysql $options "$selectLowestSnapinID") #Get the lowest snapin ID.
highestID=$(mysql $options "$selectHighestSnapinID") #Get the highest snapin ID.
newAutoIncrement=$((highestID + 1)) #The next free ID is the highest ID + 1.

####### Basic logic flow ########

#If there is a snapin id of 1, move it to the newAutoIncrement number. This is to free the ID number "1" to simplify re-ordering.
#Renumbering then selects all imageIDs from lowest to highest and moves them to the counting number.
#I.E. 5 gets moved to 1. 22 gets moved to 2. 34 gets moved to 3. and so on.
#After re-numbering is complete, we find out what the new highest imageID is, and add 1 to it to find the "new" newAutoIncrement number.
#Then reset the auto-increment to the newAutoIncrement number.



#Move any snapins that have an ID of 1 to the next free number.
if [[ "$lowestID" -eq "1" ]]; then
   echo "-------------------"
   echo "Attempting to change Snapin ID $lowestID to $newAutoIncrement"
   mysql $options "UPDATE snapins SET sID = $newAutoIncrement WHERE sID = $lowestID"
   mysql $options "UPDATE snapinGroupAssoc SET sgaSnapinID = $newAutoIncrement WHERE sgaSnapinID = $lowestID"
   mysql $options "UPDATE snapinAssoc SET saSnapinID = $newAutoIncrement WHERE saSnapinID = $lowestID"
   echo "Attempt completed"
fi


#Re-number all snapins sequentially.
count=1
mysql $options "$selectAllSnapinIDs" | while read snapinID; do
   echo "-------------------"
   echo "Attempting to change Snapin ID $snapinID to $count"
   mysql $options "UPDATE snapins SET sID = $count WHERE sID = $snapinID"
   mysql $options "UPDATE snapinGroupAssoc SET sgaSnapinID = $count WHERE sgaSnapinID = $snapinID"
   mysql $options "UPDATE snapinAssoc SET saSnapinID = $count WHERE saSnapinID = $snapinID"
   echo "Attempt completed"
   count=$((count + 1))
done


#set new auto-increment.
echo "-------------------"
highestID=$(mysql $options "$selectHighestSnapinID")
newAutoIncrement=$((highestID + 1))
echo "Attempting to change the auto_increment for the snapins table to $newAutoIncrement"
mysql $options "ALTER TABLE snapins AUTO_INCREMENT = $newAutoIncrement"
echo "Attempt completed"
