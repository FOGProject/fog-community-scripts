#!/usr/bin/python
from threading import Thread
import subprocess
import os
from functions import *



def runTest(branch,os):
    print os.getcwd() + "/testInstance.sh " + branch + " " + os
    subprocess.call(os.getcwd() + "/testInstance.sh " + branch + " " + os, shell=True)


for branch in branches:
    threads = []
    for os in OSs:
        instance = get_instance("Name","fogtesting-" + os)
        snapshot = get_snapshot("Name",os + '-clean')
        restore_snapshot_to_instance(snapshot,instance)
        threads.append(Thread(target=runTest,args=(branch,os)))
    # Start all the tests for this branch.
    for x in threads:
        x.start()
    # Wait for all of them to get done before proceeding.
    for x in threads:
        x.join()







