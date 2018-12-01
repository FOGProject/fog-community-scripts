#!/usr/bin/python

from threading import Thread
from functions import *

threads = []
for os in OSs:
    instance = get_instance("Name","fogtesting-" + os)
    snapshot = get_snapshot("Name",os + '-clean')
    if os == "debian9":
        threads.append(Thread(target=restore_snapshot_to_instance,args=(snapshot,instance,"xvda")))
    elif os == "centos7":
        threads.append(Thread(target=restore_snapshot_to_instance,args=(snapshot,instance,"/dev/sda1")))

complete_threads(threads)


