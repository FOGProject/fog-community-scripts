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
    gzip ${webdir}/${testHost}/${rightNow}_${task}_var-log.tar
    echo "$(date +%x_%r) \"$testHost\" ${task} /var/log here: http://${domainName}${port}${netdir}/${testHost}/${rightNow}_${task}_var-log.tar.gz" >> $output
else
    echo "$(date +%x_%r) \"$testHost\" ${task} /var/log could not be retrieved." >> $output
    echo "\"$testHost\" ${task} /var/log could not be retrieved." >> $report
fi

if [[ -f ${shareDir}/${testHost}/postinit.log ]]; then
    mv ${shareDir}/${testHost}/postinit.log ${webdir}/${testHost}/${rightNow}_${task}_postinit.log
    echo "$(date +%x_%r) \"$testHost\" ${task} postinit.log: http://${domainName}${port}${netdir}/${testHost}/${rightNow}_${task}_postinit.log" >> $output
    if [[ -e ${webdir}/${testHost}/postinit_sums.log ]]; then
        last=$(tail -n 1 ${webdir}/${testHost}/postinit_sums.log)
    fi
    sum=$(sha256sum ${webdir}/${testHost}/${rightNow}_${task}_postinit.log | cut -d' ' -f1)
    echo "$sum" >> ${webdir}/${testHost}/postinit_sums.log
    if [[ "$sum" == "$last" ]]; then
        echo "$(date +%x_%r) \"$testHost\" ${task} postinit.log checksum matches last one." >> $output
        echo " \"$testHost\" ${task} postinit.log checksum matches last one." >> $report
    else
        echo "$(date +%x_%r) \"$testHost\" ${task} postinit.log checksum does not match last one." >> $output
        echo " \"$testHost\" ${task} postinit.log checksum does not match last one." >> $report
    fi
else
    echo "$(date +%x_%r) \"$testHost\" ${task} postinit.log could not be retrieved." >> $output
    echo "\"$testHost\" ${task} postinit.log could not be retrieved." >> $report
fi

if [[ -f ${shareDir}/${testHost}/postdownload.log ]]; then
    mv ${shareDir}/${testHost}/postdownload.log ${webdir}/${testHost}/${rightNow}_${task}_postdownload.log
    echo "$(date +%x_%r) \"$testHost\" ${task} postdownload.log: http://${domainName}${port}${netdir}/${testHost}/${rightNow}_${task}_postdownload.log" >> $output
    if [[ -e ${webdir}/${testHost}/postdownload_sums.log ]]; then
        last=$(tail -n 1 ${webdir}/${testHost}/postdownload_sums.log)
    fi
    sum=$(sha256sum ${webdir}/${testHost}/${rightNow}_${task}_postdownload.log | cut -d' ' -f1)
    echo "$sum" >> ${webdir}/${testHost}/postdownload_sums.log
    if [[ "$sum" == "$last" ]]; then
        echo "$(date +%x_%r) \"$testHost\" ${task} postdownload.log checksum matches last one." >> $output
        echo " \"$testHost\" ${task} postdownload.log checksum matches last one." >> $report
    else
        echo "$(date +%x_%r) \"$testHost\" ${task} postdownload.log checksum does not match last one." >> $output
        echo " \"$testHost\" ${task} postdownload.log checksum does not match last one." >> $report
    fi
else
    echo "$(date +%x_%r) \"$testHost\" ${task} postdownload.log could not be retrieved." >> $output
    echo "\"$testHost\" ${task} postdownload.log could not be retrieved." >> $report
fi

#Screenshots.
count=$(ls -1 ${shareDir}/${testHost}/screenshots/*.ppm 2>/dev/null | wc -l)
if [[ $count -gt 0 ]]; then
    tar -czf ${webdir}/${testHost}/${rightNow}_${task}_screenshots.tar.gz -C ${shareDir}/${testHost}/screenshots .
    echo "$(date +%x_%r) \"$testHost\" ${task} screenshots: http://${domainName}${port}${netdir}/${testHost}/${rightNow}_${task}_screenshots.tar.gz" >> $output
else
    echo "$(date +%x_%r) \"$testHost\" ${task} screenshots could be retrieved." >> $output
    echo "\"$testHost\" ${task} screenshots could be retrieved." >> $report

fi



#Get checksums of vm disks.
#nonsense=$(timeout $sshTime ssh -o ConnectTimeout=$sshTimeout $hostsystem "echo wakeup")
#nonsense=$(timeout $sshTime ssh -o ConnectTimeout=$sshTimeout $hostsystem "echo get ready")
#sleep 5
#sum=$(ssh -o ConnectTimeout=$sshTimeout $hostsystem "sha256sum ${testHostDisksDir}/${testHost}.qcow2 | cut -d' ' -f1")
#if [[ -e ${webdir}/${testHost}/disk_sums.log ]]; then
#    last=$(tail -n 1 ${webdir}/${testHost}/disk_sums.log)
#fi
#echo "$sum" >> ${webdir}/${testHost}/disk_sums.log
#if [[ "$sum" == "$last" ]]; then
#    echo "$(date +%x_%r) \"$testHost\" ${task} disk checksum matches last one." >> $output
#    echo " \"$testHost\" ${task} disk checksum matches last one." >> $report
#else
#    echo "$(date +%x_%r) \"$testHost\" ${task} disk checksum does not match last one." >> $output
#    echo " \"$testHost\" ${task} disk checksum does not match last one." >> $report
#fi


#Cleanup.
rm -rf ${shareDir}/${testHost}




