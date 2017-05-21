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

if [[ -f ${shareDir}/${1}/postinit.log ]]; then
    mv ${shareDir}/${1}/postinit.log ${webdir}/${1}/${rightNow}_postinit.log
    echo "$(date +%x_%r) \"$1\" postinit.log: ${domanName}/${1}/${rightNow}_postinit.log" >> $output
    echo "\"$1\" postinit.log: ${domanName}/${1}/${rightNow}_postinit.log" >> $report
else
    echo "$(date +%x_%r) \"$1\" postinit.log could not be retrieved." >> $output
    echo "\"$1\" postinit.log could not be retrieved." >> $report
fi

if [[ -f ${shareDir}/${$1}/postdownload.log ]]; then
    mv ${shareDir}/${$1}/postdownload.log ${webdir}/${$1}/${rightNow}_postdownload.log
    echo "$(date +%x_%r) \"$1\" postdownload.log: ${domanName}/${1}/${rightNow}_postdownload.log" >> $output
    echo "\"$1\" postdownload.log: ${domanName}/${1}/${rightNow}_postdownload.log" >> $report
else
    echo "$(date +%x_%r) \"$1\" postdownload.log could not be retrieved." >> $output
    echo "\"$1\" postdownload.log could not be retrieved." >> $report
fi

#Screenshots.
count=$(ls -1 ${shareDir}/${1}/*.ppm 2>/dev/null | wc -l)
if [[ $count -gt 0 ]]; then
    tar -cf ${webdir}/${1}/${rightNow}_deploy_screenshots.tar -C ${shareDir}/${1}/*.ppm .
    echo "$(date +%x_%r) \"$1\" deploy screenshots: ${domanName}/${1}/${rightNow}_deploy_screenshots.tar" >> $output
    echo "\"$1\" deploy screenshots: ${domanName}/${1}/${rightNow}_deploy_screenshots.tar" >> $report
else
    echo "$(date +%x_%r) \"$1\" No deploy screenshots could be retrieved." >> $output
    echo "\"$1\" No deploy screenshots could be retrieved." >> $report

fi

#Cleanup.
rm -rf ${shareDir}/${1}




