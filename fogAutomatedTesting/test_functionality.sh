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
echo "setTestHostImages.sh \"${testHost1ID},${testHost2ID},${testHost3ID}\""
$cwd/./setTestHostImages.sh $testHost1ImageID "${testHost1ID},${testHost2ID},${testHost3ID}"
echo "captureImage.sh $testHost1Snapshot1 $testHost1VM $testHost1ID"
$cwd/./captureImage.sh $testHost1Snapshot1 $testHost1VM $testHost1ID





