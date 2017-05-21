#!/bin/bash

cwd="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$cwd/settings.sh"

rightNow=$(date +%Y-%m-%d_%H-%M)

testHost=$1


if [[ -f ${shareDir}/${testHost}/var-log.tar ]]; then
    mv ${shareDir}/${testHost}/var-log.tar ${webdir}/${testHost}/${rightNow}_var-log.tar
    echo "$(date +%x_%r) \"$testHost\" /var/log here: ${domainName}/${testHost}/${rightNow}_var-log.tar" >> $output
    echo "\"$testHost\" /var/log here: ${domainName}/${testHost}/${rightNow}_var-log.tar" >> $report
else
    echo "$(date +%x_%r) \"$testHost\" /var/log could not be retrieved." >> $output
    echo "\"$testHost\" /var/log could not be retrieved." >> $report
fi

if [[ -f ${shareDir}/${testHost}/postinit.log ]]; then
    mv ${shareDir}/${testHost}/postinit.log ${webdir}/${testHost}/${rightNow}_postinit.log
    echo "$(date +%x_%r) \"$testHost\" postinit.log: ${domainName}/${testHost}/${rightNow}_postinit.log" >> $output
    echo "\"$testHost\" postinit.log: ${domainName}/${testHost}/${rightNow}_postinit.log" >> $report
else
    echo "$(date +%x_%r) \"$testHost\" postinit.log could not be retrieved." >> $output
    echo "\"$testHost\" postinit.log could not be retrieved." >> $report
fi

if [[ -f ${shareDir}/${$testHost}/postdownload.log ]]; then
    mv ${shareDir}/${$testHost}/postdownload.log ${webdir}/${$testHost}/${rightNow}_postdownload.log
    echo "$(date +%x_%r) \"$testHost\" postdownload.log: ${domainName}/${testHost}/${rightNow}_postdownload.log" >> $output
    echo "\"$testHost\" postdownload.log: ${domainName}/${testHost}/${rightNow}_postdownload.log" >> $report
else
    echo "$(date +%x_%r) \"$testHost\" postdownload.log could not be retrieved." >> $output
    echo "\"$testHost\" postdownload.log could not be retrieved." >> $report
fi

#Screenshots.
count=$(ls -1 ${shareDir}/${testHost}/screenshots/*.ppm 2>/dev/null | wc -l)
if [[ $count -gt 0 ]]; then
    tar -cf ${webdir}/${testHost}/${rightNow}_deploy_screenshots.tar -C ${shareDir}/${testHost}/screenshots .
    echo "$(date +%x_%r) \"$testHost\" deploy screenshots: ${domainName}/${testHost}/${rightNow}_deploy_screenshots.tar" >> $output
    echo "\"$testHost\" deploy screenshots: ${domainName}/${testHost}/${rightNow}_deploy_screenshots.tar" >> $report
else
    echo "$(date +%x_%r) \"$testHost\" No deploy screenshots could be retrieved." >> $output
    echo "\"$testHost\" No deploy screenshots could be retrieved." >> $report

fi

#Cleanup.
rm -rf ${shareDir}/${testHost}




