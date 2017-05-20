#!/bin/bash

cwd="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$cwd/settings.sh"




if [[ -f ${shareDir}/${1}/var-log.tar ]]; then
    mv ${shareDir}/${1}/var-log.tar ${webdir}/${1}/${rightNow}_var-log.tar
    echo "$(date +%x_%r) $1 /var/log here: ${domanName}/${1}/${rightNow}_var-log.tar" >> $output
    echo "$1 /var/log here: ${domanName}/${1}/${rightNow}_var-log.tar" >> $report
else
    echo "$(date +%x_%r) $1 /var/log could not be retrieved." >> $output
    echo "$1 /var/log could not be retrieved." >> $report
fi

if [[ -f ${shareDir}/${1}/var-log.tar ]]; then
    mv ${shareDir}/${1}/var-log.tar ${webdir}/${1}/${rightNow}_var-log.tar
    echo "$(date +%x_%r) $1 /var/log here: ${domanName}/${1}/${rightNow}_var-log.tar" >> $output
    echo "$1 /var/log here: ${domanName}/${1}/${rightNow}_var-log.tar" >> $report
else
    echo "$(date +%x_%r) $1 /var/log could not be retrieved." >> $output
    echo "$1 /var/log could not be retrieved." >> $report
fi

if [[ -f ${shareDir}/${testHost1VM}/var-log.tar ]]; then
    mv ${shareDir}/${testHost1VM}/var-log.tar ${webdir}/${testHost1VM}/${rightNow}_var-log.tar
    echo "$(date +%x_%r) $testHost1VM /var/log here: ${domanName}/${testHost1VM}/${rightNow}_var-log.tar" >> $output
    echo "$testHost1VM /var/log here: ${domanName}/${testHost1VM}/${rightNow}_var-log.tar" >> $report
else
    echo "$(date +%x_%r) $testHost1VM /var/log could not be retrieved." >> $output
    echo "$testHost1VM /var/log could not be retrieved." >> $report
fi

