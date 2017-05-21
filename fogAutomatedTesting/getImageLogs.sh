#!/bin/bash

cwd="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$cwd/settings.sh"

rightNow=$(date +%Y-%m-%d_%H-%M)

testHost=$1
if [[ -z $testHost ]]; then
    echo "$(date +%x_%r) Must provide the testHost to get logs from." >> $output.
    exit
fi

task=$2
if [[ -z $task ]]; then
    echo "$(date +%x_%r) Must provide the task type for log storage purposes." >> $output
    exit
fi


if [[ -f ${shareDir}/${testHost}/var-log.tar ]]; then
    mv ${shareDir}/${testHost}/var-log.tar ${webdir}/${testHost}/${rightNow}_${task}_var-log.tar
    echo "$(date +%x_%r) \"$testHost\" /var/log here: http://${domainName}${port}${netdir}/${testHost}/${rightNow}_${task}_var-log.tar" >> $output
    echo "\"$testHost\" /var/log here: http://${domainName}${port}${netdir}/${testHost}/${rightNow}_${task}_var-log.tar" >> $report
else
    echo "$(date +%x_%r) \"$testHost\" ${task} /var/log could not be retrieved." >> $output
    echo "\"$testHost\" ${task} /var/log could not be retrieved." >> $report
fi

if [[ -f ${shareDir}/${testHost}/postinit.log ]]; then
    mv ${shareDir}/${testHost}/postinit.log ${webdir}/${testHost}/${rightNow}_${task}_postinit.log
    echo "$(date +%x_%r) \"$testHost\" postinit.log: http://${domainName}${port}${netdir}/${testHost}/${rightNow}_${task}_postinit.log" >> $output
    echo "\"$testHost\" postinit.log: http://${domainName}${port}${netdir}/${testHost}/${rightNow}_${task}_postinit.log" >> $report
else
    echo "$(date +%x_%r) \"$testHost\" ${task} postinit.log could not be retrieved." >> $output
    echo "\"$testHost\" ${task} postinit.log could not be retrieved." >> $report
fi

if [[ -f ${shareDir}/${$testHost}/postdownload.log ]]; then
    mv ${shareDir}/${$testHost}/postdownload.log ${webdir}/${$testHost}/${rightNow}_${task}_postdownload.log
    echo "$(date +%x_%r) \"$testHost\" postdownload.log: http://${domainName}${port}${netdir}/${testHost}/${rightNow}_${task}_postdownload.log" >> $output
    echo "\"$testHost\" postdownload.log: http://${domainName}${port}${netdir}/${testHost}/${rightNow}_${task}_postdownload.log" >> $report
else
    echo "$(date +%x_%r) \"$testHost\" ${task} postdownload.log could not be retrieved." >> $output
    echo "\"$testHost\" ${task} postdownload.log could not be retrieved." >> $report
fi

#Screenshots.
count=$(ls -1 ${shareDir}/${testHost}/screenshots/*.ppm 2>/dev/null | wc -l)
if [[ $count -gt 0 ]]; then
    tar -cf ${webdir}/${testHost}/${rightNow}_${task}_screenshots.tar -C ${shareDir}/${testHost}/screenshots .
    echo "$(date +%x_%r) \"$testHost\" deploy screenshots: http://${domainName}${port}${netdir}/${testHost}/${rightNow}_${task}_screenshots.tar" >> $output
    echo "\"$testHost\" deploy screenshots: http://${domainName}${port}${netdir}/${testHost}/${rightNow}_${task}_screenshots.tar" >> $report
else
    echo "$(date +%x_%r) \"$testHost\" ${task} screenshots could be retrieved." >> $output
    echo "\"$testHost\" ${task} screenshots could be retrieved." >> $report

fi

#Cleanup.
rm -rf ${shareDir}/${testHost}




