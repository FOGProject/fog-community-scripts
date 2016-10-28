#!/bin/bash

#----- MySQL Credentials -----#
snmysqluser=""
snmysqlpass=""
snmysqlhost=""
# If user and pass is blank, leave just a set of double quotes like ""
# if the db is local, set the host to just double quotes "" or "127.0.0.1" or "localhost"


#----- Begin Program -----#

selectAllImageIDs="SELECT imageID FROM images ORDER BY imageID"
selectLowestImageID="SELECT imageID FROM images ORDER BY imageID ASC LIMIT 1"
selectHighestImageID="SELECT imageID FROM images ORDER BY imageID DESC LIMIT 1"

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
lowestID=$(mysql $options "$selectLowestImageID")
highestID=$(mysql $options "$selectHighestImageID")
newAutoIncrement=$((highestID + 1))


####### Basic logic flow ########

#If there is an image id of 1, move it to the new auto increment number.
#After re-numbering is complete, the new auto increment number will not be taken.
#Then reset the auto-increment to the new auto increment number, which is the first free number.



#Move any images that have an ID of 1 to the next free number.
if [[ "$lowestID" -eq "1" ]]; then
    echo "-------------------"
    echo "Attempting to change Image ID $lowestID to $newAutoIncrement"
    mysql $options "UPDATE images SET imageID = $newAutoIncrement WHERE imageID = $lowestID"
    mysql $options "UPDATE imageGroupAssoc SET igaImageID = $newAutoIncrement WHERE igaImageID = $lowestID"
    mysql $options "UPDATE hosts SET hostImage = $newAutoIncrement WHERE hostImage = $lowestID"
    echo "Attempt completed"
fi


#Re-number all images sequentially.
count=1
mysql $options "$selectAllImageIDs" | while read imageID; do
    echo "-------------------"
    echo "Attempting to change Image ID $imageID to $count"
    mysql $options "UPDATE images SET imageID = $count WHERE imageID = $imageID"
    mysql $options "UPDATE imageGroupAssoc SET igaImageID = $count WHERE igaImageID = $imageID"
    mysql $options "UPDATE hosts SET hostImage = $count WHERE hostImage = $imageID"
    echo "Attempt completed"
    count=$((count + 1))
done


#set new auto-increment.
echo "-------------------"
highestID=$(mysql $options "$selectHighestImageID")
newAutoIncrement=$((highestID + 1))
echo "Attempting to change the auto_increment for the images table to $newAutoIncrement"
mysql $options "ALTER TABLE images AUTO_INCREMENT = $newAutoIncrement"
echo "Attempt completed"

