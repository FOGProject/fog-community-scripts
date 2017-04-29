#!/bin/bash
cwd="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$cwd/settings.sh"

#If an old report exists here, delete it.
if [[ -f $report ]]; then
    rm -f $report
fi

#If old output file exists, delete it.
if [[ -f $output ]]; then
    rm -f $output
fi


#Here, we begin testing fog functionality.

echo "getTestServerReady.sh"
$cwd/./getTestServerReady.sh
$cwd/./setTestHostImages.sh $testHost1ImageID "${testHost1ID},${testHost2ID},${testHost3ID}"
$cwd/./captureImage.sh $testHost1Snapshot1 $testHost1VM $testHost1ID
$cwd/./deployImage.sh $testHost2VM $testHost2ID
$cwd/./deployImage.sh $testHost3VM $testHost3ID

echo "$(date +%x_%r) Waiting for image deployments to complete..." >> $output

count=0
#Need to monitor task progress somehow. Once done, should exit.
while true; do
    if [[ "$($cwd/./getTaskStatus.sh)" == "0" ]]; then
        echo "$(date +%x_%r) Image deployments complete." >> $output
        exit
    else
        count=$(($count + 1))
        sleep 60
        if [[ $count -gt $deployLimit ]]; then
            echo "$(date +%x_%r) Image deployments did not complete within ${deployLimit} seconds." >> $output
            break
        fi
    fi
done



