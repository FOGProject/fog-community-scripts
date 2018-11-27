#!/usr/bin/python
from threading import Thread
import subprocess
from functions import *

def runTest(branch,os):
    subprocess.call(test_script + " " + branch + " " + os, shell=True)

from functions import *

threads = []
for os in OSs:
    instance = get_instance("Name","fogtesting-" + os)
    snapshot = get_snapshot("Name",os + '-clean')
    if os == "debian9":
        threads.append(Thread(target=restore_snapshot_to_instance,args=(snapshot,instance,"xvda")))
    elif os == "centos7":
        threads.append(Thread(target=restore_snapshot_to_instance,args=(snapshot,instance,"/dev/sda1")))

# Start all the threads.
for x in threads:
    x.start()

# Wait for all threads to exit.
for x in threads:
    x.join()


for branch in branches:
    threads = []
    for os in OSs:
        instance = get_instance("Name","fogtesting-" + os)
        snapshot = get_snapshot("Name",os + '-clean')
        if os == "debian9":
            threads.append(Thread(target=restore_snapshot_to_instance,args=(snapshot,instance,"xvda")))
        elif os == "centos7":
            threads.append(Thread(target=restore_snapshot_to_instance,args=(snapshot,instance,"/dev/sda1")))

    # Start snapshot restore threads.
    for x in threads:
        x.start()
    # Wait for all threads to be done.
    for x in threads:
        x.join()

    # Reset threads.
    threads = []
    for os in OSs:
        threads.append(Thread(target=runTest,args=(branch,os)))
    # Start all the tests for this branch.
    for x in threads:
        x.start()
    # Wait for all of them to get done before proceeding.
    for x in threads:
        x.join()




