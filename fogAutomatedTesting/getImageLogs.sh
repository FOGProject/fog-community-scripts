#!/bin/bash

cwd="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$cwd/settings.sh"

rightNow=$(date +%Y-%m-%d_%H-%M)


if [[ -f ${shareDir}/${1}/var-log.tar ]]; then
    mv ${shareDir}/${1}/var-log.tar ${webdir}/${1}/${rightNow}_var-log.tar
    echo "$(date +%x_%r) \"$1\" /var/log here: ${domanName}/${1}/${rightNow}_var-log.tar" >> $output
    echo "\"$1\" /var/log here: ${domanName}/${1}/${rightNow}_var-log.tar" >> $report
else
    echo "$(date +%x_%r) \"$1\" /var/log could not be retrieved." >> $output
    echo "\"$1\" /var/log could not be retrieved." >> $report
fi

if [[ -f ${shareDir}/${1}/var-log.tar ]]; then
    mv ${shareDir}/${1}/var-log.tar ${webdir}/${1}/${rightNow}_var-log.tar
    echo "$(date +%x_%r) \"$1\" /var/log here: ${domanName}/${1}/${rightNow}_var-log.tar" >> $output
    echo "\"$1\" /var/log here: ${domanName}/${1}/${rightNow}_var-log.tar" >> $report
else
    echo "$(date +%x_%r) \"$1\" /var/log could not be retrieved." >> $output
    echo "\"$1\" /var/log could not be retrieved." >> $report
fi

if [[ -f ${shareDir}/${$1}/var-log.tar ]]; then
    mv ${shareDir}/${$1}/var-log.tar ${webdir}/${$1}/${rightNow}_var-log.tar
    echo "$(date +%x_%r) \"$1\" /var/log here: ${domanName}/${1}/${rightNow}_var-log.tar" >> $output
    echo "\"$1\" /var/log here: ${domanName}/${1}/${rightNow}_var-log.tar" >> $report
else
    echo "$(date +%x_%r) \"$1\" /var/log could not be retrieved." >> $output
    echo "\"$1\" /var/log could not be retrieved." >> $report
fi



